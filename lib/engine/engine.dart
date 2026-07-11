/// Football Dice 게임 엔진.
///
/// 필드 좌표계: 0 ~ 100 (절대 좌표).
///  - 0   = home 팀의 엔드 라인 (home 골라인)
///  - 100 = away 팀의 엔드 라인 (away 골라인)
///  - home은 100 방향으로, away는 0 방향으로 공격한다.
library;

import 'dart:math';

import '../data/cards.dart';
import '../l10n/l10n.dart';

enum Team { home, away }

extension TeamX on Team {
  Team get opponent => this == Team.home ? Team.away : Team.home;

  /// 공격 진행 방향 (+1: 100쪽으로, -1: 0쪽으로)
  int get direction => this == Team.home ? 1 : -1;
}

enum GamePhase {
  /// 킥오프 대기: [GameState.kickingTeam]이 킥오프 또는 온사이드 킥 선택
  kickoff,

  /// 킥오프/펀트가 엔드존에 도달: 리시버의 리턴/터치백 선택 대기
  returnChoice,

  /// 일반 다운 진행: 공격/수비 카드 선택
  play,

  /// 터치다운 직후: 추가득점(킥 or 2점 컨버전) 선택
  extraPoint,

  gameOver,
}

enum PendingReturn { kickoff, punt }

/// 사운드 연출용 판정 이벤트 (UI가 언어와 무관하게 효과음을 고른다)
enum SfxEvent { score, penalty, turnover, kick }

/// 한 번의 판정 결과(로그 + 주사위/차트 표시용)
class Resolution {
  final List<String> log = [];
  final Set<SfxEvent> sfx = {};
  int? offD10, defD10, offD12, defD12;
  String? offCardId, defCardId, chartCardId;

  /// 차트에서 짚은 위치 (UI 하이라이트용)
  int? row, col;
  String? cellValue;

  /// 이번 판정으로 공이 지나간 궤적 (애니메이션용 절대좌표)
  final List<int> ballPath = [];

  void add(String s) => log.add(s);
}

class GameState {
  int ballPos = 50;
  Team possession = Team.home;
  int down = 1;

  /// 퍼스트 다운 목표 지점(절대좌표). null이면 골라인까지.
  int? firstDownTarget;

  int quarter = 1;
  int playCount = 1;
  final Map<Team, int> score = {Team.home: 0, Team.away: 0};

  GamePhase phase = GamePhase.kickoff;
  Team kickingTeam = Team.away;

  /// 전반 시작 시 킥오프한 팀 (후반에 리턴팀과 교대)
  Team openingKicker = Team.away;

  /// returnChoice 단계에서 어떤 리턴인지
  PendingReturn pendingReturn = PendingReturn.kickoff;

  /// 연장전(서든 데스) 여부
  bool overtime = false;

  Team? winner;
  bool isDraw = false;

  /// 공격팀 골라인까지 남은 거리
  int distanceToGoal(Team team) =>
      team == Team.home ? 100 - ballPos : ballPos;

  /// 퍼스트 다운까지 남은 야드
  int yardsToFirstDown() {
    final t = firstDownTarget;
    if (t == null) return distanceToGoal(possession);
    return possession == Team.home ? t - ballPos : ballPos - t;
  }
}

class GameEngine {
  final GameState state = GameState();
  final Random _rng;
  final List<String> gameLog = [];

  /// 16번째 플레이가 끝나 쿼터 전환이 예약된 상태
  bool _pendingQuarterEnd = false;

  GameEngine({int? seed}) : _rng = Random(seed) {
    state.kickingTeam = _rng.nextBool() ? Team.home : Team.away;
    state.openingKicker = state.kickingTeam;
    _log(loc.coinToss(teamName(state.kickingTeam)));
  }

  static String teamName(Team t) => t == Team.home ? 'HOME' : 'AWAY';

  void _log(String s) {
    gameLog.add(s);
    if (gameLog.length > 300) gameLog.removeAt(0);
  }

  int _d10() => _rng.nextInt(10) + 1;
  int _d12() => _rng.nextInt(12) + 1;

  // -------------------------------------------------------------------------
  // 킥오프
  // -------------------------------------------------------------------------

  Resolution kickoff() {
    assert(state.phase == GamePhase.kickoff);
    final r = Resolution();
    final kicker = state.kickingTeam;
    final receiver = kicker.opponent;

    // 킥오프는 자신의 30야드 라인에서
    state.ballPos = kicker == Team.home ? 30 : 70;
    r.ballPath.add(state.ballPos);

    final d10 = _d10();
    final d12a = _d12(), d12b = _d12();
    final row = rowIndex(d10);
    final col = columnIndex(d12a + d12b);
    final cell = kickOffCard.cell(row, col);
    r
      ..offD10 = d10
      ..offD12 = d12a
      ..defD12 = d12b
      ..chartCardId = kickOffCard.id
      ..row = row
      ..col = col
      ..cellValue = cell;

    int yards;
    if (cell == 'F') {
      yards = kickOffCard.roundedAverage;
      r.add(loc.kickFallback(yards));
    } else {
      yards = int.parse(cell);
    }
    r.add(loc.kickoffLine(teamName(kicker), yards));
    r.sfx.add(SfxEvent.kick);

    state.ballPos += yards * kicker.direction;
    _countPlay(); // 킥오프는 플레이 마커 진행

    state.possession = receiver;
    if (_clampToEndLine(receiver)) {
      r.add(loc.endzoneChoiceKickoff);
      r.ballPath.add(state.ballPos);
      state.phase = GamePhase.returnChoice;
      state.pendingReturn = PendingReturn.kickoff;
      return _finish(r);
    }
    r.ballPath.add(state.ballPos);
    _doKickoffReturn(r, receiver);
    return _finish(r);
  }

  /// 온사이드 킥 (킥오프 위치에서만 사용 가능)
  Resolution onsideKick() {
    assert(state.phase == GamePhase.kickoff);
    final r = Resolution();
    final kicker = state.kickingTeam;

    state.ballPos = kicker == Team.home ? 30 : 70;
    r.ballPath.add(state.ballPos);

    final d10 = _d10();
    final d12a = _d12(), d12b = _d12();
    final row = rowIndex(d10);
    final col = columnIndex(d12a + d12b);
    final cell = onSideKickCard.cell(row, col);
    r
      ..offD10 = d10
      ..offD12 = d12a
      ..defD12 = d12b
      ..chartCardId = onSideKickCard.id
      ..row = row
      ..col = col
      ..cellValue = cell;

    _countPlay();
    r.sfx.add(SfxEvent.kick);

    if (cell == 'I') {
      r.add(loc.onsideFail(teamName(kicker.opponent)));
      state.possession = kicker.opponent;
      _startFirstDown(r);
    } else {
      final yards = int.parse(cell);
      state.ballPos += yards * kicker.direction;
      _clampInside();
      r.ballPath.add(state.ballPos);
      if (yards < 0) {
        r.add(loc.onsideBackward(-yards));
      } else {
        r.add(loc.onsideSuccess(yards, teamName(kicker)));
      }
      state.possession = kicker;
      _startFirstDown(r);
    }
    return _finish(r);
  }

  /// returnChoice 단계: 리턴 선택
  Resolution chooseReturn() {
    assert(state.phase == GamePhase.returnChoice);
    final r = Resolution();
    final receiver = state.possession;
    if (state.pendingReturn == PendingReturn.kickoff) {
      _doKickoffReturn(r, receiver);
    } else {
      _doPuntReturn(r, receiver);
    }
    return _finish(r);
  }

  /// returnChoice 단계: 터치백 선택 (자기 진영 20야드)
  Resolution chooseTouchback() {
    assert(state.phase == GamePhase.returnChoice);
    final r = Resolution();
    final receiver = state.possession;
    state.ballPos = receiver == Team.home ? 20 : 80;
    r.ballPath.add(state.ballPos);
    r.add(loc.touchbackLine(teamName(receiver)));
    _startFirstDown(r);
    return _finish(r);
  }

  void _doKickoffReturn(Resolution r, Team receiver) {
    final d10 = _d10();
    final d12a = _d12(), d12b = _d12();
    final row = rowIndex(d10);
    final col = columnIndex(d12a + d12b);
    final cell = kickoffReturnCard.cell(row, col);
    r
      ..offD10 = d10
      ..offD12 = d12a
      ..defD12 = d12b
      ..chartCardId = kickoffReturnCard.id
      ..row = row
      ..col = col
      ..cellValue = cell;

    if (cell == 'F') {
      final adv = kickoffReturnCard.roundedAverage;
      state.ballPos += adv * receiver.direction;
      _clampInside();
      r.ballPath.add(state.ballPos);
      r.add(loc.kickoffReturnFumble(adv));
      r.sfx.add(SfxEvent.turnover);
      // 킥오프 팀이 공격권을 잡고 턴오버 리턴을 수행한다
      state.possession = receiver.opponent;
      _resolveTurnoverChart(r);
      return;
    }

    final yards = int.parse(cell);
    state.ballPos += yards * receiver.direction;
    r.add(loc.kickoffReturnLine(teamName(receiver), yards));
    state.possession = receiver;

    if (_checkTouchdown(r, receiver)) return;
    _clampInside();
    r.ballPath.add(state.ballPos);
    _startFirstDown(r);
  }

  // -------------------------------------------------------------------------
  // 일반 플레이
  // -------------------------------------------------------------------------

  /// 공격/수비 카드로 한 번의 다운을 해결한다.
  Resolution runPlay(String offenseCardId, String defenseCardId) {
    assert(state.phase == GamePhase.play);
    final r = Resolution();
    final off = offenseById(offenseCardId);
    final def = defenseById(defenseCardId);
    r
      ..offCardId = off.id
      ..defCardId = def.id;

    final offense = state.possession;
    final offD10 = _d10(), defD10 = _d10();
    final offD12 = _d12(), defD12 = _d12();
    r
      ..offD10 = offD10
      ..defD10 = defD10
      ..offD12 = offD12
      ..defD12 = defD12;

    r.add(loc.playHeader(teamName(offense), off.name, def.name));
    _countPlay();

    // 패널티 체크: 양팀 10면체 합이 6 또는 16
    final d10Sum = offD10 + defD10;
    if (d10Sum == 6 || d10Sum == 16) {
      if (offD10 == defD10) {
        r.add(loc.penaltyOffset(offD10, defD10));
      } else {
        _resolvePenalty(r, offD10, defD10, offD12 + defD12);
        return _finish(r);
      }
    }

    final mod = def.modifierFor(off.id);
    final adjusted = (offD10 + mod).clamp(1, 10);
    final row = rowIndex(adjusted);
    final col = columnIndex(offD12 + defD12);
    final cell = off.cell(row, col);
    r
      ..row = row
      ..col = col
      ..cellValue = cell;
    if (mod != 0) {
      r.add(loc.defenseMod(mod, offD10, adjusted));
    }

    if (cell == 'I' || cell == 'F') {
      _resolveInterceptionOrFumble(r, off, cell);
      return _finish(r);
    }

    final yards = int.parse(cell);
    r.add(yards >= 0 ? loc.gain(yards) : loc.loss(-yards));
    state.ballPos += yards * offense.direction;

    if (_checkTouchdown(r, offense)) return _finish(r);
    if (_checkSafety(r, offense)) return _finish(r);
    r.ballPath.add(state.ballPos);
    _advanceDown(r);
    return _finish(r);
  }

  void _resolvePenalty(Resolution r, int offD10, int defD10, int d12Sum) {
    final offense = state.possession;
    final col = columnIndex(d12Sum);
    final yards = penaltyYards[col];
    final offenderIsOffense = offD10 < defD10;
    r
      ..chartCardId = 'penalty'
      ..col = col
      ..cellValue = '$yards';

    r.sfx.add(SfxEvent.penalty);
    if (offenderIsOffense) {
      r.add(loc.penaltyOnOffense(yards));
      state.ballPos -= yards * offense.direction;
      _clampInside();
    } else {
      r.add(loc.penaltyOnDefense(yards));
      state.ballPos += yards * offense.direction;
      _clampInside();
      // 패널티 야드로 퍼스트 다운 라인을 넘으면 새 퍼스트 다운
      final t = state.firstDownTarget;
      if (t != null &&
          ((offense == Team.home && state.ballPos >= t) ||
              (offense == Team.away && state.ballPos <= t))) {
        r.add(loc.penaltyFirstDown);
        _startFirstDown(r, quiet: true);
      }
    }
    r.ballPath.add(state.ballPos);
    r.add(loc.repeatDown(state.down));
  }

  void _resolveInterceptionOrFumble(Resolution r, OffenseCard off, String cell) {
    final offense = state.possession;
    r.sfx.add(SfxEvent.turnover);
    if (cell == 'I') {
      final fly = off.averageYards.round();
      r.add(loc.interception(fly));
      state.ballPos += fly * offense.direction;
      _clampInside();
    } else {
      r.add(loc.fumbleAtLine);
    }
    r.ballPath.add(state.ballPos);
    state.possession = offense.opponent;
    _resolveTurnoverChart(r);
  }

  /// 턴오버 카드 판정. state.possession == 리턴하는 팀(새 공격팀)인 상태로 호출.
  void _resolveTurnoverChart(Resolution r) {
    final returner = state.possession;
    final d10 = _d10();
    final d12a = _d12(), d12b = _d12();
    final row = rowIndex(d10);
    final col = columnIndex(d12a + d12b);
    final cell = turnoverCard.cell(row, col);
    r.add(loc.turnoverJudge(cell));

    if (cell == 'F') {
      final adv = turnoverCard.roundedAverage;
      state.ballPos += adv * returner.direction;
      _clampInside();
      r.ballPath.add(state.ballPos);
      r.add(loc.returnFumble(adv));
      _resolveFumbleChart(r);
      return;
    }

    final yards = int.parse(cell);
    state.ballPos += yards * returner.direction;
    r.add(loc.returnGain(teamName(returner), yards));

    if (_checkTouchdown(r, returner)) return;
    _clampInside();
    r.ballPath.add(state.ballPos);
    _startFirstDown(r);
  }

  /// 펌블 카드 판정. R = 리턴팀(현재 possession)이 확보, X = 상대팀이 회수.
  void _resolveFumbleChart(Resolution r) {
    final returner = state.possession;
    final d10 = _d10();
    final d12a = _d12(), d12b = _d12();
    final row = rowIndex(d10);
    final col = columnIndex(d12a + d12b);
    final cell = fumbleCard.cell(row, col);

    if (cell == 'R') {
      r.add(loc.fumbleRecovered(teamName(returner)));
    } else {
      r.add(loc.fumbleLost(teamName(returner.opponent)));
      state.possession = returner.opponent;
    }
    _startFirstDown(r);
  }

  // -------------------------------------------------------------------------
  // 펀트 / 필드골
  // -------------------------------------------------------------------------

  bool get canPunt => state.phase == GamePhase.play && state.down == 4;

  ChartCard? get availableFieldGoal => state.phase == GamePhase.play
      ? fieldGoalCardFor(state.distanceToGoal(state.possession))
      : null;

  Resolution punt(bool long) {
    assert(canPunt);
    final r = Resolution();
    final card = long ? longPuntCard : shortPuntCard;
    final offense = state.possession;
    final receiver = offense.opponent;

    final d10 = _d10();
    final d12a = _d12(), d12b = _d12();
    final row = rowIndex(d10);
    final col = columnIndex(d12a + d12b);
    final cell = card.cell(row, col);
    r
      ..offD10 = d10
      ..offD12 = d12a
      ..defD12 = d12b
      ..chartCardId = card.id
      ..row = row
      ..col = col
      ..cellValue = cell;

    int yards;
    if (cell == 'F') {
      yards = card.roundedAverage;
      r.add(loc.puntFallback(yards));
    } else {
      yards = int.parse(cell);
    }
    r.add(loc.puntLine(
        teamName(offense), loc.chartName(card.name, card.koName), yards));
    r.sfx.add(SfxEvent.kick);
    state.ballPos += yards * offense.direction;
    _countPlay();

    state.possession = receiver;
    if (_clampToEndLine(receiver)) {
      r.add(loc.endzoneChoicePunt);
      r.ballPath.add(state.ballPos);
      state.phase = GamePhase.returnChoice;
      state.pendingReturn = PendingReturn.punt;
      return _finish(r);
    }
    r.ballPath.add(state.ballPos);
    _doPuntReturn(r, receiver);
    return _finish(r);
  }

  void _doPuntReturn(Resolution r, Team receiver) {
    final d10 = _d10();
    final d12a = _d12(), d12b = _d12();
    final row = rowIndex(d10);
    final col = columnIndex(d12a + d12b);
    final cell = puntReturnCard.cell(row, col);
    r
      ..chartCardId = puntReturnCard.id
      ..row = row
      ..col = col
      ..cellValue = cell;

    final yards = int.parse(cell); // 펀트 리턴 차트에는 특수 결과가 없다
    state.ballPos += yards * receiver.direction;
    r.add(loc.puntReturnLine(teamName(receiver), yards));
    state.possession = receiver;

    if (_checkTouchdown(r, receiver)) return;
    _clampInside();
    r.ballPath.add(state.ballPos);
    _startFirstDown(r);
  }

  Resolution fieldGoalAttempt() {
    final card = availableFieldGoal;
    assert(card != null);
    final r = Resolution();
    final offense = state.possession;
    final distance = state.distanceToGoal(offense);

    final d10 = _d10();
    final d12a = _d12(), d12b = _d12();
    final row = rowIndex(d10);
    final col = columnIndex(d12a + d12b);
    final cell = card!.cell(row, col);
    r
      ..offD10 = d10
      ..offD12 = d12a
      ..defD12 = d12b
      ..chartCardId = card.id
      ..row = row
      ..col = col
      ..cellValue = cell;

    _countPlay();

    if (cell == 'G') {
      r.add(loc.fgSuccess(distance));
      _addScore(r, offense, 3);
      if (state.phase != GamePhase.gameOver) _setupKickoff(offense);
    } else {
      r.add(cell == 'F' ? loc.fgFumble : loc.fgFail(distance));
      r.add(loc.takeoverAtSpot(teamName(offense.opponent)));
      state.possession = offense.opponent;
      _startFirstDown(r);
    }
    return _finish(r);
  }

  // -------------------------------------------------------------------------
  // 터치다운 이후: 추가 득점 (플레이 마커 진행 없음)
  // -------------------------------------------------------------------------

  /// Extra Point Kick: 10야드 라인에서 PAT 시도 (+1점)
  Resolution extraPointKick() {
    assert(state.phase == GamePhase.extraPoint);
    final r = Resolution();
    final offense = state.possession;

    final d10 = _d10();
    final d12a = _d12(), d12b = _d12();
    final row = rowIndex(d10);
    final col = columnIndex(d12a + d12b);
    final cell = patFieldGoal.cell(row, col);
    r
      ..offD10 = d10
      ..offD12 = d12a
      ..defD12 = d12b
      ..chartCardId = patFieldGoal.id
      ..row = row
      ..col = col
      ..cellValue = cell;

    if (cell == 'G') {
      r.add(loc.extraKickSuccess);
      _addScore(r, offense, 1);
    } else {
      r.add(loc.extraKickFail);
    }
    if (state.phase != GamePhase.gameOver) _setupKickoff(offense);
    return _finish(r);
  }

  /// 2점 컨버전: 2야드 라인에서 한 번의 플레이 (+2점)
  Resolution twoPointConversion(String offenseCardId, String defenseCardId) {
    assert(state.phase == GamePhase.extraPoint);
    final r = Resolution();
    final off = offenseById(offenseCardId);
    final def = defenseById(defenseCardId);
    final offense = state.possession;
    r
      ..offCardId = off.id
      ..defCardId = def.id;

    state.ballPos = offense == Team.home ? 98 : 2;

    final offD10 = _d10(), defD10 = _d10();
    final offD12 = _d12(), defD12 = _d12();
    final mod = def.modifierFor(off.id);
    final adjusted = (offD10 + mod).clamp(1, 10);
    final row = rowIndex(adjusted);
    final col = columnIndex(offD12 + defD12);
    final cell = off.cell(row, col);
    r
      ..offD10 = offD10
      ..defD10 = defD10
      ..offD12 = offD12
      ..defD12 = defD12
      ..row = row
      ..col = col
      ..cellValue = cell;

    r.add(loc.twoPointAttempt(off.name, def.name));

    if (cell == 'I' || cell == 'F') {
      r.add(loc.conversionFailTurnover(cell == 'I'));
      r.sfx.add(SfxEvent.turnover);
    } else {
      final yards = int.parse(cell);
      if (yards >= 2) {
        r.add(loc.twoPointSuccess);
        _addScore(r, offense, 2);
      } else {
        r.add(loc.conversionFailShort(yards));
      }
    }
    if (state.phase != GamePhase.gameOver) _setupKickoff(offense);
    return _finish(r);
  }

  // -------------------------------------------------------------------------
  // 내부 헬퍼
  // -------------------------------------------------------------------------

  /// 공이 리시버 진영 엔드라인에 도달/통과했으면 엔드라인에 두고 true 반환
  bool _clampToEndLine(Team receiver) {
    if (receiver == Team.home && state.ballPos <= 0) {
      state.ballPos = 0;
      return true;
    }
    if (receiver == Team.away && state.ballPos >= 100) {
      state.ballPos = 100;
      return true;
    }
    return false;
  }

  void _clampInside() {
    state.ballPos = state.ballPos.clamp(1, 99);
  }

  /// 터치다운 체크. 발생 시 true. (추가득점 단계로 전환)
  bool _checkTouchdown(Resolution r, Team team) {
    final crossed =
        team == Team.home ? state.ballPos >= 100 : state.ballPos <= 0;
    if (!crossed) return false;
    state.ballPos = team == Team.home ? 100 : 0;
    r.ballPath.add(state.ballPos);
    r.add(loc.touchdown(teamName(team)));
    _addScore(r, team, 6);
    if (state.phase == GamePhase.gameOver) return true;
    state.possession = team;
    state.phase = GamePhase.extraPoint;
    return true;
  }

  /// 세이프티 체크: 공격팀이 자기 엔드존까지 밀렸을 때
  bool _checkSafety(Resolution r, Team offense) {
    final inOwnEndzone =
        offense == Team.home ? state.ballPos <= 0 : state.ballPos >= 100;
    if (!inOwnEndzone) return false;
    state.ballPos = offense == Team.home ? 0 : 100;
    r.ballPath.add(state.ballPos);
    r.add(loc.safety(teamName(offense.opponent)));
    _addScore(r, offense.opponent, 2);
    if (state.phase == GamePhase.gameOver) return true;
    // 세이프티를 허용한 팀이 프리킥(킥오프)
    _setupKickoff(offense.opponent, kicker: offense);
    return true;
  }

  void _addScore(Resolution r, Team team, int points) {
    state.score[team] = state.score[team]! + points;
    r.sfx.add(SfxEvent.score);
    r.add(loc.scoreLine(state.score[Team.home]!, state.score[Team.away]!));
    if (state.overtime) {
      // 서든 데스: 득점 즉시 종료
      state.winner = team;
      state.phase = GamePhase.gameOver;
      r.add(loc.suddenDeathWin(teamName(team)));
    }
  }

  void _setupKickoff(Team scorer, {Team? kicker}) {
    state.phase = GamePhase.kickoff;
    state.kickingTeam = kicker ?? scorer; // 득점한 팀이 킥오프
    state.firstDownTarget = null;
    state.down = 1;
  }

  void _startFirstDown(Resolution r, {bool quiet = false}) {
    final offense = state.possession;
    state.down = 1;
    final target = state.ballPos + 10 * offense.direction;
    // 골라인 10야드 이내면 목표는 골라인
    if (offense == Team.home && target >= 100 ||
        offense == Team.away && target <= 0) {
      state.firstDownTarget = null;
    } else {
      state.firstDownTarget = target;
    }
    state.phase = GamePhase.play;
    if (!quiet) {
      r.add(loc.firstDownLine(teamName(offense), state.yardsToFirstDown(),
          state.distanceToGoal(offense)));
    }
  }

  void _advanceDown(Resolution r) {
    final offense = state.possession;
    final t = state.firstDownTarget;
    final reached = t == null
        ? false
        : (offense == Team.home ? state.ballPos >= t : state.ballPos <= t);

    if (reached) {
      r.add(loc.firstDownRenewed);
      _startFirstDown(r);
      return;
    }
    if (state.down >= 4) {
      r.add(loc.downsExhausted(teamName(offense.opponent)));
      r.sfx.add(SfxEvent.turnover);
      state.possession = offense.opponent;
      _startFirstDown(r);
      return;
    }
    state.down++;
    r.add(loc.nextDown(state.down, state.yardsToFirstDown()));
  }

  /// 플레이 마커 진행. 16번째 플레이면 쿼터 전환을 예약한다.
  void _countPlay() {
    if (state.playCount < 16) {
      state.playCount++;
    } else {
      _pendingQuarterEnd = true;
    }
  }

  /// 모든 판정이 끝난 뒤 예약된 쿼터 전환을 적용한다.
  /// 추가득점/리턴 선택이 남아 있으면 그 해결 이후로 미룬다.
  Resolution _finish(Resolution r) {
    if (_pendingQuarterEnd &&
        state.phase != GamePhase.extraPoint &&
        state.phase != GamePhase.returnChoice &&
        state.phase != GamePhase.gameOver) {
      _pendingQuarterEnd = false;
      state.playCount = 1;
      state.quarter++;
      if (state.quarter == 3) {
        r.add(loc.halftime(teamName(state.openingKicker.opponent)));
        _setupKickoff(state.openingKicker.opponent,
            kicker: state.openingKicker.opponent);
      } else if (state.quarter >= 5) {
        _endRegulation(r);
      } else {
        r.add(loc.quarterEnd(state.quarter - 1, state.quarter));
      }
    }
    for (final line in r.log) {
      _log(line);
    }
    return r;
  }

  void _endRegulation(Resolution r) {
    final h = state.score[Team.home]!, a = state.score[Team.away]!;
    if (h != a) {
      state.winner = h > a ? Team.home : Team.away;
      state.phase = GamePhase.gameOver;
      r.add(loc.gameEnd(teamName(state.winner!), h, a));
      return;
    }
    if (!state.overtime) {
      state.overtime = true;
      r.add(loc.tieOvertime);
      final kicker = _rng.nextBool() ? Team.home : Team.away;
      _setupKickoff(kicker, kicker: kicker);
    } else {
      state.isDraw = true;
      state.phase = GamePhase.gameOver;
      r.add(loc.drawLine(h, a));
    }
  }
}
