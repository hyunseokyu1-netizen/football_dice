/// 메인 게임 화면: 사용자(HOME) vs AI(AWAY)
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../data/cards.dart';
import '../engine/ai.dart';
import '../engine/engine.dart';
import '../l10n/l10n.dart';
import 'settings.dart';
import 'sound.dart';
import 'widgets.dart';

class GameScreen extends StatefulWidget {
  final Difficulty difficulty;
  const GameScreen({super.key, this.difficulty = Difficulty.normal});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

/// 사용자에게 보여줄 입력 패널 종류
enum _Panel {
  none, // AI 진행 중 / 대기
  kickoff, // 내 킥오프 선택
  returnChoice, // 내 리턴/터치백 선택
  offense, // 내 공격 카드 선택
  defense, // 내 수비 카드 선택
  extraPoint, // 추가득점 방식 선택
  gameOver,
}

class _GameScreenState extends State<GameScreen> {
  late GameEngine engine;
  late AiPlayer ai;

  Resolution? lastRes;
  int resVersion = 0; // 판정마다 증가 (필드 애니메이션 트리거)
  String? aiRevealText; // 이번 플레이에서 AI가 낸 카드 공개
  _Panel panel = _Panel.none;
  bool busy = false; // AI 지연 처리 중

  /// 최근 플레이의 카드 매치업 (카드 보기 버튼 / 플라이바이 연출용)
  ({String offId, String defId, bool playerIsOffense})? matchup;

  /// 카드 대결 오버레이 표시 여부
  bool flybyVisible = false;

  /// 2점 컨버전용 공격 카드 선택 모드
  bool playerTwoPoint = false;

  /// AI 2점 컨버전 시 수비 선택 대기
  bool awaiting2ptDefense = false;

  String? selectedOffense;
  String? selectedDefense;

  static const player = Team.home;

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  void _newGame() {
    engine = GameEngine();
    ai = AiPlayer(Team.away, difficulty: widget.difficulty);
    lastRes = null;
    aiRevealText = null;
    matchup = null;
    flybyVisible = false;
    playerTwoPoint = false;
    awaiting2ptDefense = false;
    selectedOffense = null;
    selectedDefense = null;
    busy = false;
    _sync();
  }

  GameState get s => engine.state;

  /// 엔진 상태에 맞춰 패널 결정 + AI 차례면 자동 진행
  void _sync() {
    if (!mounted) return;
    setState(() {
      panel = _decidePanel();
    });
    _maybeRunAi();
  }

  _Panel _decidePanel() {
    switch (s.phase) {
      case GamePhase.gameOver:
        return _Panel.gameOver;
      case GamePhase.kickoff:
        return s.kickingTeam == player ? _Panel.kickoff : _Panel.none;
      case GamePhase.returnChoice:
        return s.possession == player ? _Panel.returnChoice : _Panel.none;
      case GamePhase.play:
        return s.possession == player ? _Panel.offense : _Panel.defense;
      case GamePhase.extraPoint:
        if (s.possession == player) {
          return playerTwoPoint ? _Panel.offense : _Panel.extraPoint;
        }
        return awaiting2ptDefense ? _Panel.defense : _Panel.none;
    }
  }

  Future<void> _maybeRunAi() async {
    if (busy || s.phase == GamePhase.gameOver) return;

    // AI 킥오프
    if (s.phase == GamePhase.kickoff && s.kickingTeam != player) {
      await _aiDelay(() {
        final r = ai.chooseOnsideKick(s) ? engine.onsideKick() : engine.kickoff();
        _show(r, reveal: null);
      });
      return;
    }
    // AI 리턴 선택
    if (s.phase == GamePhase.returnChoice && s.possession != player) {
      await _aiDelay(() {
        final r = ai.chooseTouchback(s)
            ? engine.chooseTouchback()
            : engine.chooseReturn();
        _show(r, reveal: null);
      });
      return;
    }
    // AI 공격 중 스페셜팀(펀트/필드골)은 수비 카드 없이 즉시 진행
    if (s.phase == GamePhase.play && s.possession != player) {
      final action = ai.chooseOffense(engine);
      if (action.type == AiOffenseActionType.punt) {
        await _aiDelay(() {
          final r = engine.punt(action.longPunt);
          _show(r, reveal: loc.aiPuntChoice(action.longPunt));
        });
        return;
      }
      if (action.type == AiOffenseActionType.fieldGoal) {
        await _aiDelay(() {
          final r = engine.fieldGoalAttempt();
          _show(r, reveal: loc.aiFieldGoal);
        });
        return;
      }
      // 일반 플레이면 사용자 수비 선택 대기 (panel == defense)
      _pendingAiOffense = action.offenseCardId;
      return;
    }
    // AI 추가득점
    if (s.phase == GamePhase.extraPoint && s.possession != player) {
      if (ai.chooseTwoPoint(s)) {
        setState(() => awaiting2ptDefense = true);
        _sync2();
        return;
      }
      await _aiDelay(() {
        final r = engine.extraPointKick();
        _show(r, reveal: loc.aiExtraKick);
      });
      return;
    }
  }

  /// setState로 패널만 갱신 (AI 재귀 호출 없이)
  void _sync2() {
    if (!mounted) return;
    setState(() => panel = _decidePanel());
  }

  String? _pendingAiOffense;

  Future<void> _aiDelay(VoidCallback action) async {
    setState(() => busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    busy = false;
    action();
  }

  void _show(Resolution r, {String? reveal, bool? playerIsOffense}) {
    lastRes = r;
    resVersion++;
    aiRevealText = reveal;
    selectedOffense = null;
    selectedDefense = null;
    final offId = r.offCardId, defId = r.defCardId;
    if (offId != null && defId != null && playerIsOffense != null) {
      matchup = (offId: offId, defId: defId, playerIsOffense: playerIsOffense);
      flybyVisible = GameSettings.effects;
    } else {
      matchup = null;
      flybyVisible = false;
    }
    _playSfx(r);
    _sync();
  }

  void _playSfx(Resolution r) {
    final sfx = SoundService.instance;
    if (r.sfx.contains(SfxEvent.score)) {
      sfx.score();
    } else if (r.sfx.contains(SfxEvent.penalty)) {
      sfx.whistle();
    } else if (r.sfx.contains(SfxEvent.turnover)) {
      sfx.bad();
    } else if (r.sfx.contains(SfxEvent.kick)) {
      sfx.kick();
    } else {
      sfx.dice();
    }
  }

  // ---------------------------------------------------------------------
  // 사용자 액션
  // ---------------------------------------------------------------------

  void _playerKickoff(bool onside) {
    final r = onside ? engine.onsideKick() : engine.kickoff();
    _show(r);
  }

  void _playerReturnChoice(bool touchback) {
    final r = touchback ? engine.chooseTouchback() : engine.chooseReturn();
    _show(r);
  }

  void _playerOffenseConfirm() {
    final cardId = selectedOffense;
    if (cardId == null) return;
    if (playerTwoPoint) {
      playerTwoPoint = false;
      final defId = ai.chooseDefense(engine);
      final r = engine.twoPointConversion(cardId, defId);
      _show(r,
          reveal: loc.aiRevealDefense(defenseById(defId).name),
          playerIsOffense: true);
      return;
    }
    final defId = ai.chooseDefense(engine);
    ai.noteOpponentPlay(offenseById(cardId).type);
    final r = engine.runPlay(cardId, defId);
    _show(r,
        reveal: loc.aiRevealDefense(defenseById(defId).name),
        playerIsOffense: true);
  }

  void _playerDefenseConfirm() {
    final defId = selectedDefense;
    if (defId == null) return;
    if (awaiting2ptDefense) {
      awaiting2ptDefense = false;
      final offId = ai.chooseConversionPlay();
      final r = engine.twoPointConversion(offId, defId);
      _show(r,
          reveal: loc.aiTwoPoint(offenseById(offId).name),
          playerIsOffense: false);
      return;
    }
    final offId = _pendingAiOffense ?? ai.chooseOffense(engine).offenseCardId!;
    _pendingAiOffense = null;
    final r = engine.runPlay(offId, defId);
    _show(r,
        reveal: loc.aiRevealOffense(offenseById(offId).name),
        playerIsOffense: false);
  }

  void _playerPunt(bool long) => _show(engine.punt(long));

  void _playerFieldGoal() => _show(engine.fieldGoalAttempt());

  void _playerExtraKick() => _show(engine.extraPointKick());

  void _playerChooseTwoPoint() {
    setState(() {
      playerTwoPoint = true;
      panel = _Panel.offense;
    });
  }

  // ---------------------------------------------------------------------
  // 빌드
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        // 넓은 화면(웹/태블릿)에서도 폰 세로 비율을 유지한다
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Stack(
                children: [
                  Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: ScoreBoard(state: s)),
                      IconButton(
                        onPressed: () => setState(() =>
                            SoundService.instance.muted =
                                !SoundService.instance.muted),
                        icon: Icon(
                          SoundService.instance.muted
                              ? Icons.volume_off
                              : Icons.volume_up,
                          color: Colors.white38,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FieldView(
                    state: s,
                    path: lastRes?.ballPath ?? const [],
                    version: resVersion,
                  ),
                  const SizedBox(height: 8),
                  Expanded(flex: 5, child: _resultArea()),
                  const SizedBox(height: 8),
                  Expanded(flex: 7, child: _actionArea()),
                    ],
                  ),
                  // 플레이 판정 시 카드 대결 연출 (탭하면 스킵)
                  if (flybyVisible && matchup != null)
                    Positioned.fill(
                      child: CardFlyby(
                        key: ValueKey(resVersion),
                        offCardId: matchup!.offId,
                        defCardId: matchup!.defId,
                        playerIsOffense: matchup!.playerIsOffense,
                        onDone: () => setState(() => flybyVisible = false),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _resultArea() {
    final r = lastRes;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: r == null
          ? Center(
              child: Text(loc.welcome,
                  style: const TextStyle(color: Colors.white54)))
          : Column(
              children: [
                if (aiRevealText != null)
                  Text(aiRevealText!,
                      style: const TextStyle(
                          color: Color(0xFFEF9A9A),
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                DiceRow(res: r, version: resVersion),
                const SizedBox(height: 4),
                Expanded(
                  child: ListView(
                    children: [
                      for (final line in r.log)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: Text(line,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12)),
                        ),
                    ],
                  ),
                ),
                if (matchup != null || (r.row != null && r.offCardId != null))
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (matchup != null)
                        TextButton(
                          onPressed: () => showMatchupDialog(context,
                              res: r,
                              playerIsOffense: matchup!.playerIsOffense),
                          child: Text(loc.viewCards,
                              style: const TextStyle(
                                  color: kGold, fontSize: 11)),
                        ),
                      if (r.row != null && r.offCardId != null)
                        TextButton(
                          onPressed: () {
                            final card = offenseById(r.offCardId!);
                            showChartDialog(context,
                                title: card.name,
                                chart: card.chart,
                                highlightRow: r.row,
                                highlightCol: r.col);
                          },
                          child: Text(loc.viewChart,
                              style: const TextStyle(
                                  color: kGold, fontSize: 11)),
                        ),
                    ],
                  ),
              ],
            ),
    );
  }

  Widget _actionArea() {
    switch (panel) {
      case _Panel.none:
        return _waiting();
      case _Panel.kickoff:
        return _kickoffPanel();
      case _Panel.returnChoice:
        return _returnPanel();
      case _Panel.offense:
        return _offensePanel();
      case _Panel.defense:
        return _defensePanel();
      case _Panel.extraPoint:
        return _extraPointPanel();
      case _Panel.gameOver:
        return _gameOverPanel();
    }
  }

  Widget _panelBox({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2A1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Text(title,
              style: const TextStyle(
                  color: kGold, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _waiting() {
    return _panelBox(
      title: loc.aiThinking,
      child: const Center(
        child: CircularProgressIndicator(color: kGold),
      ),
    );
  }

  Widget _kickoffPanel() {
    return _panelBox(
      title: loc.kickoffTitle,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _bigButton(loc.kickoffButton, Icons.sports_football,
              () => _playerKickoff(false)),
          const SizedBox(height: 8),
          _bigButton(loc.onsideButton, Icons.casino,
              () => _playerKickoff(true)),
        ],
      ),
    );
  }

  Widget _returnPanel() {
    return _panelBox(
      title: loc.returnTitle,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _bigButton(loc.returnButton, Icons.directions_run,
              () => _playerReturnChoice(false)),
          const SizedBox(height: 8),
          _bigButton(loc.touchbackButton, Icons.flag,
              () => _playerReturnChoice(true)),
        ],
      ),
    );
  }

  /// 상황에 맞는 추천 공격 플레이 3장.
  /// 전체 플레이북에서 추천 밖의 카드를 선택하면 마지막 자리를 그 카드로 바꿔
  /// 선택 상태가 항상 라인에 보이게 한다.
  List<OffenseCard> _suggestedOffense() {
    final toFirst = s.yardsToFirstDown();
    final toGoal = s.distanceToGoal(player);
    List<String> ids;
    if (playerTwoPoint || toGoal <= 5) {
      ids = ['dive_plunge', 'sweep', 'short_pass'];
    } else if (toFirst <= 3) {
      ids = ['dive_plunge', 'qb_draw', 'sweep'];
    } else if (toFirst <= 7) {
      ids = ['pitch_out', 'short_pass', 'screen_pass'];
    } else {
      ids = ['long_pass', 'short_pass', 'rb_draw'];
    }
    final sel = selectedOffense;
    if (sel != null && !ids.contains(sel)) {
      ids = [...ids.sublist(0, 2), sel];
    }
    return [for (final id in ids) offenseById(id)];
  }

  String _situationLabel() {
    final toFirst = s.yardsToFirstDown();
    if (playerTwoPoint) return loc.situationTwoPoint;
    if (s.distanceToGoal(player) <= 5) return loc.situationGoalLine;
    if (toFirst <= 3) return loc.situationShort;
    if (toFirst <= 7) return loc.situationMedium;
    return loc.situationLong;
  }

  Widget _offensePanel() {
    final fg = engine.availableFieldGoal;
    final suggestions = _suggestedOffense();
    final title = playerTwoPoint
        ? loc.twoPointPanelTitle
        : loc.offensePanelTitle(s.down, s.yardsToFirstDown());
    final selectedCard =
        selectedOffense == null ? null : offenseById(selectedOffense!);
    return _panelBox(
      title: title,
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(loc.suggestion(_situationLabel()),
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Row(
              children: [
                for (final c in suggestions) ...[
                  Expanded(
                    child: GameplanCard(
                      cardId: c.id,
                      name: c.name,
                      subtitle: loc.offenseSubtitle(
                          c.type == PlayType.pass, c.averageYards),
                      selected: selectedOffense == c.id,
                      onTap: () => setState(() => selectedOffense = c.id),
                      onLongPress: () => showChartDialog(context,
                          title: c.name,
                          chart: c.chart,
                          subtitle:
                              loc.cardDescription(c.id, c.description)),
                    ),
                  ),
                  if (c != suggestions.last) const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _smallButton(loc.fullPlaybook, _openOffensePlaybook),
              const SizedBox(width: 6),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (!playerTwoPoint) ...[
                        if (engine.canPunt) ...[
                          _smallButton(
                              loc.longPuntButton, () => _playerPunt(true)),
                          const SizedBox(width: 6),
                          _smallButton(
                              loc.shortPuntButton, () => _playerPunt(false)),
                          const SizedBox(width: 6),
                        ],
                        if (fg != null)
                          _smallButton('FG ${s.distanceToGoal(player)}yd',
                              _playerFieldGoal),
                      ],
                    ],
                  ),
                ),
              ),
              // 선택한 카드의 차트/설명 보기 (전략 학습용)
              IconButton(
                onPressed: selectedCard == null
                    ? null
                    : () => showChartDialog(context,
                        title: selectedCard.name,
                        chart: selectedCard.chart,
                        subtitle: loc.cardDescription(
                            selectedCard.id, selectedCard.description)),
                icon: const Icon(Icons.menu_book, size: 20),
                color: kGold,
                disabledColor: Colors.white24,
                tooltip: loc.cardInfoTooltip,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 2),
              ElevatedButton(
                onPressed:
                    selectedOffense == null ? null : _playerOffenseConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGold,
                  foregroundColor: Colors.black,
                ),
                child: Text(
                  selectedCard == null ? loc.playButton : loc.execButton,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openOffensePlaybook() async {
    final picked = await showPlaybookSheet(
      context,
      title: loc.offensePlaybookTitle,
      children: [
        for (final c in offenseCards)
          (
            id: c.id,
            name: c.name,
            subtitle: loc.offenseSubtitle(
                c.type == PlayType.pass, c.averageYards),
            isDefense: false,
          ),
      ],
    );
    if (picked != null) setState(() => selectedOffense = picked);
  }

  /// AI 공격 상황에 맞는 추천 수비 대형 3장.
  /// 전체 수비 대형에서 추천 밖의 카드를 선택하면 마지막 자리를 그 카드로 바꿔
  /// 선택 상태가 항상 라인에 보이게 한다.
  List<DefenseCard> _suggestedDefense() {
    final toFirst = s.yardsToFirstDown();
    final toGoal = s.distanceToGoal(player.opponent);
    List<String> ids;
    if (awaiting2ptDefense || toGoal <= 5) {
      ids = ['goal_line', 'four_three', 'man_to_man'];
    } else if (toFirst <= 3) {
      ids = ['goal_line', 'four_three', 'blitz'];
    } else if (toFirst <= 7) {
      ids = ['three_four', 'man_to_man', 'zone'];
    } else {
      ids = ['nickel', 'dime', 'prevent'];
    }
    final sel = selectedDefense;
    if (sel != null && !ids.contains(sel)) {
      ids = [...ids.sublist(0, 2), sel];
    }
    return [for (final id in ids) defenseById(id)];
  }

  Widget _defensePanel() {
    final suggestions = _suggestedDefense();
    final title = awaiting2ptDefense
        ? loc.defenseTwoPointTitle
        : loc.defensePanelTitle(s.down, s.yardsToFirstDown());
    return _panelBox(
      title: title,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                for (final c in suggestions) ...[
                  Expanded(
                    child: GameplanCard(
                      cardId: c.id,
                      name: c.name,
                      isDefense: true,
                      selected: selectedDefense == c.id,
                      onTap: () => setState(() => selectedDefense = c.id),
                      onLongPress: () => showDefenseDialog(context, c),
                    ),
                  ),
                  if (c != suggestions.last) const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _smallButton(loc.fullDefense, _openDefensePlaybook),
              const Spacer(),
              // 선택한 수비 대형의 보정치 보기 (전략 학습용)
              IconButton(
                onPressed: selectedDefense == null
                    ? null
                    : () => showDefenseDialog(
                        context, defenseById(selectedDefense!)),
                icon: const Icon(Icons.menu_book, size: 20),
                color: kGold,
                disabledColor: Colors.white24,
                tooltip: loc.cardInfoTooltip,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 2),
              ElevatedButton(
                onPressed:
                    selectedDefense == null ? null : _playerDefenseConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGold,
                  foregroundColor: Colors.black,
                ),
                child: Text(
                  loc.defendButton,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openDefensePlaybook() async {
    final picked = await showPlaybookSheet(
      context,
      title: loc.fullDefense,
      children: [
        for (final c in defenseCards)
          (id: c.id, name: c.name, subtitle: null, isDefense: true),
      ],
    );
    if (picked != null) setState(() => selectedDefense = picked);
  }

  Widget _extraPointPanel() {
    return _panelBox(
      title: loc.extraPointTitle,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _bigButton(loc.extraKickButton, Icons.sports_soccer,
              _playerExtraKick),
          const SizedBox(height: 8),
          _bigButton(loc.twoPointButton, Icons.bolt, _playerChooseTwoPoint),
        ],
      ),
    );
  }

  Widget _gameOverPanel() {
    final String message;
    if (s.isDraw) {
      message = loc.drawMessage;
    } else if (s.winner == player) {
      message = loc.winMessage;
    } else {
      message = loc.loseMessage;
    }
    return _panelBox(
      title: loc.gameOverTitle,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            'HOME ${s.score[Team.home]} - ${s.score[Team.away]} AWAY',
            style: const TextStyle(color: kGold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          _bigButton(loc.newGame, Icons.replay, () => setState(_newGame)),
        ],
      ),
    );
  }

  Widget _bigButton(String label, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF33691E),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _smallButton(String label, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: kGold,
        side: const BorderSide(color: kGold),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 34),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }
}
