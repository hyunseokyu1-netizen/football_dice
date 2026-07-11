/// AI 상대 로직.
///
/// 상황(다운, 남은 야드, 필드 위치, 점수차, 남은 시간)에 따라
/// 공격/수비 카드를 가중치 기반으로 선택한다.
library;

import 'dart:math';

import '../data/cards.dart';
import 'engine.dart';

/// AI 난이도 (표시 이름은 L10n에서 제공)
enum Difficulty { easy, normal, hard }

/// AI의 공격 턴 행동
enum AiOffenseActionType { play, punt, fieldGoal }

class AiOffenseAction {
  final AiOffenseActionType type;
  final String? offenseCardId;
  final bool longPunt;

  const AiOffenseAction.play(this.offenseCardId)
      : type = AiOffenseActionType.play,
        longPunt = false;
  const AiOffenseAction.punt({required this.longPunt})
      : type = AiOffenseActionType.punt,
        offenseCardId = null;
  const AiOffenseAction.fieldGoal()
      : type = AiOffenseActionType.fieldGoal,
        offenseCardId = null,
        longPunt = false;
}

class AiPlayer {
  final Team team;
  final Difficulty difficulty;
  final Random _rng;

  /// 상대(사람)가 최근에 낸 플레이 종류 기록 (어려움 난이도의 성향 학습용)
  final List<PlayType> _recentOpponentPlays = [];

  AiPlayer(this.team, {this.difficulty = Difficulty.normal, int? seed})
      : _rng = Random(seed);

  /// 상대가 공격 플레이를 낼 때마다 호출해 성향을 기록한다.
  void noteOpponentPlay(PlayType type) {
    _recentOpponentPlays.add(type);
    if (_recentOpponentPlays.length > 8) _recentOpponentPlays.removeAt(0);
  }

  /// 최근 상대 플레이 중 패스 비율 (기록 없으면 0.5)
  double get _opponentPassRate {
    if (_recentOpponentPlays.isEmpty) return 0.5;
    final passes =
        _recentOpponentPlays.where((t) => t == PlayType.pass).length;
    return passes / _recentOpponentPlays.length;
  }

  /// AI가 뒤지고 있는 점수차
  int _deficit(GameState s) =>
      s.score[team.opponent]! - s.score[team]!;

  bool _lateGame(GameState s) => s.quarter >= 4 && s.playCount >= 10;

  // -------------------------------------------------------------------------
  // 공격 선택
  // -------------------------------------------------------------------------

  AiOffenseAction chooseOffense(GameEngine engine) {
    final s = engine.state;
    final toFirst = s.yardsToFirstDown();
    final toGoal = s.distanceToGoal(team);
    final fg = engine.availableFieldGoal;

    // 쉬움: 4번째 다운에서도 가끔 상황 판단 없이 그냥 플레이
    if (difficulty == Difficulty.easy &&
        s.down == 4 &&
        _rng.nextDouble() < 0.35) {
      return AiOffenseAction.play(_pickOffenseCard(s, toFirst, toGoal));
    }

    // 4번째 다운: 펀트 / 필드골 / 강행 결정
    if (s.down == 4) {
      // 필드골 사정거리이고 킥이 합리적이면 킥
      if (fg != null && toFirst > 2) {
        return const AiOffenseAction.fieldGoal();
      }
      // 짧으면 강행 (특히 지고 있거나 종반이면 과감하게)
      final goForIt = toFirst <= 2 ||
          (_deficit(s) > 0 && _lateGame(s)) ||
          toGoal <= 5;
      if (!goForIt) {
        // 자기 진영 깊숙하면 롱 펀트, 상대 진영 근처면 숏 펀트
        return AiOffenseAction.punt(longPunt: toGoal > 45);
      }
    }

    // 막판이고 필드골로 동점/역전이 가능하면 킥
    final deficit = _deficit(s);
    if (fg != null && _lateGame(s) && deficit >= 1 && deficit <= 3) {
      return const AiOffenseAction.fieldGoal();
    }

    return AiOffenseAction.play(_pickOffenseCard(s, toFirst, toGoal));
  }

  String _pickOffenseCard(GameState s, int toFirst, int toGoal) {
    // 카드별 가중치
    final w = <String, double>{
      'dive_plunge': 10,
      'pitch_out': 10,
      'qb_draw': 8,
      'rb_draw': 8,
      'sweep': 8,
      'short_pass': 10,
      'screen_pass': 9,
      'long_pass': 8,
      'long_bomb': 3,
    };

    if (toFirst <= 3) {
      // 짧은 거리: 러닝 위주
      w['dive_plunge'] = w['dive_plunge']! * 3;
      w['qb_draw'] = w['qb_draw']! * 2;
      w['sweep'] = w['sweep']! * 2;
      w['long_bomb'] = 1;
    } else if (toFirst >= 8) {
      // 긴 거리: 패스 위주
      w['long_pass'] = w['long_pass']! * 3;
      w['short_pass'] = w['short_pass']! * 2;
      w['screen_pass'] = w['screen_pass']! * 2;
      w['long_bomb'] = w['long_bomb']! * 2;
      w['dive_plunge'] = 3;
    }

    // 골라인 근처: 확실한 러닝
    if (toGoal <= 5) {
      w['dive_plunge'] = w['dive_plunge']! * 3;
      w['long_bomb'] = 0.5;
      w['long_pass'] = w['long_pass']! * 0.5;
    }

    // 크게 지고 있고 종반: 한방 노림
    if (_deficit(s) >= 7 && _lateGame(s)) {
      w['long_bomb'] = w['long_bomb']! * 5;
      w['long_pass'] = w['long_pass']! * 3;
    }

    // 필드 중앙 장거리 상황에서 가끔 딥샷
    if (toGoal >= 60 && _rng.nextDouble() < 0.15) {
      w['long_bomb'] = w['long_bomb']! * 4;
    }

    return _weightedPick(w);
  }

  // -------------------------------------------------------------------------
  // 수비 선택
  // -------------------------------------------------------------------------

  String chooseDefense(GameEngine engine) {
    final s = engine.state;
    final offense = team.opponent;
    final toFirst = s.yardsToFirstDown();
    final toGoal = s.distanceToGoal(offense);
    final opponentDeficit =
        s.score[team]! - s.score[offense]!; // 상대(공격팀)가 뒤진 점수

    final w = <String, double>{
      'four_three': 10,
      'three_four': 10,
      'man_to_man': 9,
      'zone': 8,
      'nickel': 8,
      'blitz': 7,
      'dime': 5,
      'prevent': 3,
      'goal_line': 3,
    };

    if (toFirst <= 3) {
      // 짧은 거리 → 러닝 저지 대형
      w['goal_line'] = w['goal_line']! * 5;
      w['four_three'] = w['four_three']! * 2;
      w['blitz'] = w['blitz']! * 1.5;
      w['dime'] = 2;
      w['prevent'] = 1;
    } else if (toFirst >= 8) {
      // 긴 거리 → 패스 수비 대형
      w['nickel'] = w['nickel']! * 3;
      w['dime'] = w['dime']! * 3;
      w['man_to_man'] = w['man_to_man']! * 1.5;
      w['goal_line'] = 1;
    }

    // 골라인 앞 → 골라인 수비
    if (toGoal <= 5) {
      w['goal_line'] = w['goal_line']! * 8;
      w['prevent'] = 0.5;
      w['dime'] = 1;
    }

    // 상대가 크게 지고 있는 종반 → 롱패스 견제
    if (opponentDeficit >= 7 && _lateGame(s)) {
      w['prevent'] = w['prevent']! * 6;
      w['dime'] = w['dime']! * 3;
    }

    // 3rd/4th down 장거리 → 패스 수비 강화
    if (s.down >= 3 && toFirst >= 6) {
      w['nickel'] = w['nickel']! * 2;
      w['dime'] = w['dime']! * 2;
    }

    // 어려움: 상대의 최근 패스/러닝 성향에 맞춰 수비를 조정
    if (difficulty == Difficulty.hard && _recentOpponentPlays.length >= 3) {
      final passRate = _opponentPassRate;
      if (passRate >= 0.65) {
        // 패스 성향 → 패스 수비 강화
        w['nickel'] = w['nickel']! * 2.5;
        w['dime'] = w['dime']! * 2.5;
        w['man_to_man'] = w['man_to_man']! * 1.5;
      } else if (passRate <= 0.35) {
        // 러닝 성향 → 러닝 저지 강화
        w['goal_line'] = w['goal_line']! * 2.5;
        w['four_three'] = w['four_three']! * 2;
        w['blitz'] = w['blitz']! * 1.5;
      }
    }

    return _weightedPick(w);
  }

  // -------------------------------------------------------------------------
  // 기타 결정
  // -------------------------------------------------------------------------

  /// 킥오프 시 온사이드 킥을 할지
  bool chooseOnsideKick(GameState s) {
    // 종반에 지고 있을 때만
    return _deficit(s) > 0 && s.quarter >= 4 && s.playCount >= 12;
  }

  /// 엔드존 도달 시 터치백을 받을지 (true = 터치백)
  bool chooseTouchback(GameState s) {
    // 종반에 크게 지면 리턴 도박, 평소엔 터치백
    if (_deficit(s) >= 7 && _lateGame(s)) return _rng.nextDouble() < 0.5;
    return true;
  }

  /// 터치다운 후 2점 컨버전을 시도할지 (true = 2점)
  bool chooseTwoPoint(GameState s) {
    final deficit = _deficit(s); // 득점 반영 후의 점수차
    if (s.quarter < 4) return false;
    // 2점이 필요한 전형적 상황 (동점/역전 만들기)
    return deficit == 2 || deficit == 5 || deficit == 10;
  }

  /// 2점 컨버전용 공격 카드
  String chooseConversionPlay() =>
      _weightedPick({'dive_plunge': 4, 'qb_draw': 2, 'short_pass': 3, 'sweep': 2});

  String _weightedPick(Map<String, double> weights) {
    // 난이도에 따라 가중치를 뭉개거나(쉬움) 날카롭게(어려움) 만든다
    final exponent = switch (difficulty) {
      Difficulty.easy => 0.35,
      Difficulty.normal => 1.0,
      Difficulty.hard => 1.6,
    };
    final adjusted = {
      for (final e in weights.entries)
        e.key: e.value <= 0 ? 0.0 : pow(e.value, exponent).toDouble(),
    };
    final total = adjusted.values.fold(0.0, (a, b) => a + b);
    var roll = _rng.nextDouble() * total;
    for (final e in adjusted.entries) {
      roll -= e.value;
      if (roll <= 0) return e.key;
    }
    return adjusted.keys.last;
  }
}
