/// 멀티플레이(같은 Wi-Fi) 게임 화면.
///
/// 판정은 전부 호스트([HostSession])가 수행하고,
/// 이 화면은 [MpSession] 상태를 그리고 선택을 보내기만 한다.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../data/cards.dart';
import '../engine/engine.dart';
import '../l10n/l10n.dart';
import '../net/session.dart';
import 'settings.dart';
import 'sound.dart';
import 'widgets.dart';

class MpGameScreen extends StatefulWidget {
  final MpSession session;
  const MpGameScreen({super.key, required this.session});

  @override
  State<MpGameScreen> createState() => _MpGameScreenState();
}

class _MpGameScreenState extends State<MpGameScreen> {
  MpSession get session => widget.session;
  GameState get s => session.state;
  Team get me => session.myTeam;

  StreamSubscription<void>? _sub;
  int _seenVersion = -1;
  bool flybyVisible = false;
  bool _errorShown = false;

  String? selectedOffense;
  String? selectedDefense;

  @override
  void initState() {
    super.initState();
    _seenVersion = session.version;
    _sub = session.updates.listen((_) => _onUpdate());
  }

  @override
  void dispose() {
    _sub?.cancel();
    session.dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (!mounted) return;
    if (session.error != null) {
      _showDisconnected();
      return;
    }
    if (session.version != _seenVersion) {
      _seenVersion = session.version;
      selectedOffense = null;
      selectedDefense = null;
      final r = session.lastResolution;
      if (r != null) {
        _playSfx(r);
        flybyVisible =
            GameSettings.effects && r.offCardId != null && r.defCardId != null;
      } else {
        flybyVisible = false;
      }
    }
    setState(() {});
  }

  void _showDisconnected() {
    if (_errorShown || !mounted) return;
    _errorShown = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF212121),
        title: Text(
          loc.connectionLost,
          style: const TextStyle(color: kGold, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // 다이얼로그
              Navigator.of(context).pop(); // 게임 화면
            },
            child: Text(loc.close, style: const TextStyle(color: kGold)),
          ),
        ],
      ),
    );
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

  /// 최근 판정의 카드 공개 문구
  String? get _revealText {
    final r = session.lastResolution;
    final offTeam = session.lastOffTeam;
    if (r == null || offTeam == null) return null;
    final offId = r.offCardId, defId = r.defCardId;
    if (offId == null || defId == null) return null;
    return offTeam == me
        ? loc.oppRevealDefense(defenseById(defId).name)
        : loc.oppRevealOffense(offenseById(offId).name);
  }

  // ---------------------------------------------------------------------
  // 빌드
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final r = session.lastResolution;
    final offTeam = session.lastOffTeam;
    final homeName = GameEngine.teamName(Team.home);
    final awayName = GameEngine.teamName(Team.away);
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
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
                          Expanded(
                            child: ScoreBoard(
                              state: s,
                              homeLabel: me == Team.home
                                  ? loc.youLabel(homeName)
                                  : loc.friendLabel(homeName),
                              awayLabel: me == Team.away
                                  ? loc.youLabel(awayName)
                                  : loc.friendLabel(awayName),
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(
                              () => SoundService.instance.muted =
                                  !SoundService.instance.muted,
                            ),
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
                        path: r?.ballPath ?? const [],
                        version: session.version,
                      ),
                      const SizedBox(height: 8),
                      Expanded(flex: 5, child: _resultArea()),
                      const SizedBox(height: 8),
                      Expanded(flex: 7, child: _actionArea()),
                    ],
                  ),
                  if (flybyVisible &&
                      r != null &&
                      r.offCardId != null &&
                      r.defCardId != null &&
                      offTeam != null)
                    Positioned.fill(
                      child: CardFlyby(
                        key: ValueKey(session.version),
                        offCardId: r.offCardId!,
                        defCardId: r.defCardId!,
                        playerIsOffense: offTeam == me,
                        vsAi: false,
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
    final r = session.lastResolution;
    final reveal = _revealText;
    final offTeam = session.lastOffTeam;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: r == null
          ? Center(
              child: Text(
                loc.welcome,
                style: const TextStyle(color: Colors.white54),
              ),
            )
          : Column(
              children: [
                if (reveal != null)
                  Text(
                    reveal,
                    style: const TextStyle(
                      color: Color(0xFFEF9A9A),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                DiceRow(res: r, version: session.version),
                const SizedBox(height: 4),
                Expanded(
                  child: ListView(
                    children: [
                      for (final line in r.log)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: Text(
                            line,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (r.offCardId != null || r.row != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (r.offCardId != null &&
                          r.defCardId != null &&
                          offTeam != null)
                        TextButton(
                          onPressed: () => showMatchupDialog(
                            context,
                            res: r,
                            playerIsOffense: offTeam == me,
                            vsAi: false,
                          ),
                          child: Text(
                            loc.viewCards,
                            style: const TextStyle(color: kGold, fontSize: 11),
                          ),
                        ),
                      if (r.row != null && r.offCardId != null)
                        TextButton(
                          onPressed: () {
                            final card = offenseById(r.offCardId!);
                            showChartDialog(
                              context,
                              title: card.name,
                              chart: card.chart,
                              highlightRow: r.row,
                              highlightCol: r.col,
                            );
                          },
                          child: Text(
                            loc.viewChart,
                            style: const TextStyle(color: kGold, fontSize: 11),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
    );
  }

  // ---------------------------------------------------------------------
  // 액션 패널
  // ---------------------------------------------------------------------

  Widget _actionArea() {
    switch (s.phase) {
      case GamePhase.gameOver:
        return _gameOverPanel();
      case GamePhase.kickoff:
        return s.kickingTeam == me
            ? _kickoffPanel()
            : _waiting(loc.opponentTurn);
      case GamePhase.returnChoice:
        return s.possession == me ? _returnPanel() : _waiting(loc.opponentTurn);
      case GamePhase.play:
        if (session.iSubmitted) return _waiting(loc.opponentWaiting);
        return s.possession == me ? _offensePanel() : _defensePanel();
      case GamePhase.extraPoint:
        if (session.awaiting2pt) {
          if (session.iSubmitted) return _waiting(loc.opponentWaiting);
          return s.possession == me
              ? _offensePanel(twoPoint: true)
              : _defensePanel(twoPoint: true);
        }
        return s.possession == me
            ? _extraPointPanel()
            : _waiting(loc.opponentTurn);
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
          Text(
            title,
            style: const TextStyle(
              color: kGold,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _waiting(String title) {
    return _panelBox(
      title: title,
      child: const Center(child: CircularProgressIndicator(color: kGold)),
    );
  }

  Widget _kickoffPanel() {
    return _panelBox(
      title: loc.kickoffTitle,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _bigButton(
            loc.kickoffButton,
            Icons.sports_football,
            () => session.chooseKickoff(onside: false),
          ),
          const SizedBox(height: 8),
          _bigButton(
            loc.onsideButton,
            Icons.casino,
            () => session.chooseKickoff(onside: true),
          ),
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
          _bigButton(
            loc.returnButton,
            Icons.directions_run,
            () => session.chooseReturn(touchback: false),
          ),
          const SizedBox(height: 8),
          _bigButton(
            loc.touchbackButton,
            Icons.flag,
            () => session.chooseReturn(touchback: true),
          ),
        ],
      ),
    );
  }

  List<OffenseCard> _suggestedOffense(bool twoPoint) {
    final toFirst = s.yardsToFirstDown();
    final toGoal = s.distanceToGoal(me);
    List<String> ids;
    if (twoPoint || toGoal <= 5) {
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

  String _situationLabel(bool twoPoint) {
    final toFirst = s.yardsToFirstDown();
    if (twoPoint) return loc.situationTwoPoint;
    if (s.distanceToGoal(me) <= 5) return loc.situationGoalLine;
    if (toFirst <= 3) return loc.situationShort;
    if (toFirst <= 7) return loc.situationMedium;
    return loc.situationLong;
  }

  Widget _offensePanel({bool twoPoint = false}) {
    final canPunt = !twoPoint && s.phase == GamePhase.play && s.down == 4;
    final fg = !twoPoint && s.phase == GamePhase.play
        ? fieldGoalCardFor(s.distanceToGoal(me))
        : null;
    final suggestions = _suggestedOffense(twoPoint);
    final title = twoPoint
        ? loc.twoPointPanelTitle
        : loc.offensePanelTitle(s.down, s.yardsToFirstDown());
    final selectedCard = selectedOffense == null
        ? null
        : offenseById(selectedOffense!);
    return _panelBox(
      title: title,
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              loc.suggestion(_situationLabel(twoPoint)),
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
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
                        c.type == PlayType.pass,
                        c.averageYards,
                      ),
                      selected: selectedOffense == c.id,
                      onTap: () => setState(() => selectedOffense = c.id),
                      onLongPress: () => showChartDialog(
                        context,
                        title: c.name,
                        chart: c.chart,
                        subtitle: loc.cardDescription(c.id, c.description),
                      ),
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
                      if (canPunt) ...[
                        _smallButton(
                          loc.longPuntButton,
                          () => session.choosePunt(long: true),
                        ),
                        const SizedBox(width: 6),
                        _smallButton(
                          loc.shortPuntButton,
                          () => session.choosePunt(long: false),
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (fg != null)
                        _smallButton(
                          'FG ${s.distanceToGoal(me)}yd',
                          session.chooseFieldGoal,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: selectedCard == null
                    ? null
                    : () => showChartDialog(
                        context,
                        title: selectedCard.name,
                        chart: selectedCard.chart,
                        subtitle: loc.cardDescription(
                          selectedCard.id,
                          selectedCard.description,
                        ),
                      ),
                icon: const Icon(Icons.menu_book, size: 20),
                color: kGold,
                disabledColor: Colors.white24,
                tooltip: loc.cardInfoTooltip,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 2),
              ElevatedButton(
                onPressed: selectedOffense == null
                    ? null
                    : () => session.chooseOffense(selectedOffense!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGold,
                  foregroundColor: Colors.black,
                ),
                child: Text(
                  selectedCard == null ? loc.playButton : loc.execButton,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
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
              c.type == PlayType.pass,
              c.averageYards,
            ),
            isDefense: false,
          ),
      ],
    );
    if (picked != null) setState(() => selectedOffense = picked);
  }

  List<DefenseCard> _suggestedDefense(bool twoPoint) {
    final toFirst = s.yardsToFirstDown();
    final toGoal = s.distanceToGoal(me.opponent);
    List<String> ids;
    if (twoPoint || toGoal <= 5) {
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

  Widget _defensePanel({bool twoPoint = false}) {
    final suggestions = _suggestedDefense(twoPoint);
    final title = twoPoint
        ? loc.defenseTwoPointTitleMp
        : loc.defensePanelTitleMp(s.down, s.yardsToFirstDown());
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
              IconButton(
                onPressed: selectedDefense == null
                    ? null
                    : () => showDefenseDialog(
                        context,
                        defenseById(selectedDefense!),
                      ),
                icon: const Icon(Icons.menu_book, size: 20),
                color: kGold,
                disabledColor: Colors.white24,
                tooltip: loc.cardInfoTooltip,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 2),
              ElevatedButton(
                onPressed: selectedDefense == null
                    ? null
                    : () => session.chooseDefense(selectedDefense!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGold,
                  foregroundColor: Colors.black,
                ),
                child: Text(
                  loc.defendButton,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
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
          _bigButton(
            loc.extraKickButton,
            Icons.sports_soccer,
            () => session.chooseExtraPoint(twoPoint: false),
          ),
          const SizedBox(height: 8),
          _bigButton(
            loc.twoPointButton,
            Icons.bolt,
            () => session.chooseExtraPoint(twoPoint: true),
          ),
        ],
      ),
    );
  }

  Widget _gameOverPanel() {
    final String message;
    if (s.isDraw) {
      message = loc.drawMessage;
    } else if (s.winner == me) {
      message = loc.winMessage;
    } else {
      message = loc.loseMessage;
    }
    return _panelBox(
      title: loc.gameOverTitle,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'HOME ${s.score[Team.home]} - ${s.score[Team.away]} AWAY',
            style: const TextStyle(color: kGold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          _bigButton(loc.newGame, Icons.replay, session.restart),
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
