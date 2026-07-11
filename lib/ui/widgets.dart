/// 공용 UI 위젯: 스코어보드, 필드, 카드 타일, 차트 다이얼로그, 주사위 표시
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/cards.dart';
import '../engine/engine.dart';
import '../l10n/l10n.dart';
import 'play_diagram.dart';
import 'settings.dart';

const kFieldGreen = Color(0xFF2E7D32);
const kFieldDark = Color(0xFF1B5E20);
const kEndzoneHome = Color(0xFF283593);
const kEndzoneAway = Color(0xFFB71C1C);
const kGold = Color(0xFFFFC107);
const kPassBorder = Colors.white;
const kRunBorder = Color(0xFFFFEB3B);

// ---------------------------------------------------------------------------
// 스코어보드
// ---------------------------------------------------------------------------

class ScoreBoard extends StatelessWidget {
  final GameState state;

  /// null이면 기본(나/AI) 라벨 사용
  final String? homeLabel;
  final String? awayLabel;

  const ScoreBoard(
      {super.key, required this.state, this.homeLabel, this.awayLabel});

  String get _quarterLabel =>
      state.overtime ? 'OT' : 'Q${state.quarter.clamp(1, 4)}';

  @override
  Widget build(BuildContext context) {
    final possession = state.possession;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF212121),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _teamScore(homeLabel ?? loc.homeTeamLabel, state.score[Team.home]!,
              possession == Team.home, kEndzoneHome),
          Expanded(
            child: Column(
              children: [
                Text(_quarterLabel,
                    style: const TextStyle(
                        color: kGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
                Text('PLAY ${state.playCount}/16',
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 11)),
                if (state.phase == GamePhase.play)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      loc.downAndDistance(
                          state.down, state.yardsToFirstDown()),
                      style:
                          const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          _teamScore(awayLabel ?? loc.awayTeamLabel, state.score[Team.away]!,
              possession == Team.away, kEndzoneAway),
        ],
      ),
    );
  }

  Widget _teamScore(String name, int score, bool hasBall, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasBall)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Text('🏈', style: TextStyle(fontSize: 12)),
              ),
            Text(name,
                style: TextStyle(
                    color: hasBall ? kGold : Colors.white70, fontSize: 12)),
          ],
        ),
        Text('$score',
            style: TextStyle(
                color: color == kEndzoneHome
                    ? const Color(0xFF90CAF9)
                    : const Color(0xFFEF9A9A),
                fontSize: 28,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 필드
// ---------------------------------------------------------------------------

class FieldView extends StatefulWidget {
  final GameState state;

  /// 최근 판정의 공 궤적 (절대 야드 좌표 목록)
  final List<int> path;

  /// 새 판정마다 증가하는 버전 (애니메이션 트리거)
  final int version;

  const FieldView({
    super.key,
    required this.state,
    this.path = const [],
    this.version = 0,
  });

  @override
  State<FieldView> createState() => _FieldViewState();
}

class _FieldViewState extends State<FieldView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  Animation<double>? _posAnim;
  late double _displayPos;

  @override
  void initState() {
    super.initState();
    _displayPos = widget.state.ballPos.toDouble();
    _ctrl = AnimationController(vsync: this)
      ..addListener(() {
        setState(() {
          final a = _posAnim;
          if (a != null) _displayPos = a.value;
        });
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant FieldView old) {
    super.didUpdateWidget(old);
    if (widget.version != old.version && widget.path.length >= 2) {
      _animatePath(widget.path);
    } else if (!_ctrl.isAnimating &&
        widget.state.ballPos.toDouble() != _displayPos &&
        widget.path.length < 2) {
      // 궤적 없는 위치 변경(킥오프 배치 등)은 즉시 이동
      _displayPos = widget.state.ballPos.toDouble();
    }
  }

  void _animatePath(List<int> path) {
    final items = <TweenSequenceItem<double>>[];
    var from = _displayPos;
    var totalDist = 0.0;
    for (final to in path) {
      final dist = (to - from).abs().toDouble();
      if (dist < 0.5) {
        from = to.toDouble();
        continue;
      }
      items.add(TweenSequenceItem(
        tween: Tween(begin: from, end: to.toDouble())
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: dist,
      ));
      totalDist += dist;
      from = to.toDouble();
    }
    if (items.isEmpty) {
      _displayPos = widget.state.ballPos.toDouble();
      return;
    }
    _posAnim = TweenSequence<double>(items).animate(_ctrl);
    _ctrl.duration = Duration(
        milliseconds: (350 + totalDist * 12).clamp(400, 2200).toInt());
    _ctrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return AspectRatio(
      aspectRatio: 3.2,
      child: LayoutBuilder(builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        const ezRatio = 0.08; // 엔드존 폭 비율
        final playW = w * (1 - ezRatio * 2);

        double xFor(num pos) => w * ezRatio + playW * (pos / 100);

        final ballX = xFor(_displayPos);
        final target = state.firstDownTarget;

        // 이동 중 포물선 점프 + 살짝 커지는 효과
        final flight =
            _ctrl.isAnimating ? math.sin(_ctrl.value * math.pi) : 0.0;
        final lift = flight * h * 0.22;
        final scale = 1.0 + flight * 0.25;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24, width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              CustomPaint(
                size: Size(w, h),
                painter: _FieldPainter(ezRatio: ezRatio),
              ),
              // 퍼스트 다운 라인
              if (target != null && state.phase == GamePhase.play)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  left: xFor(target) - 1,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 2, color: kGold),
                ),
              // 스크리미지 라인
              if (state.phase == GamePhase.play && !_ctrl.isAnimating)
                Positioned(
                  left: ballX - 1,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 2, color: Colors.white24),
                ),
              // 공 마커
              Positioned(
                left: ballX - 10,
                top: h / 2 - 10 - lift,
                child: Transform.scale(
                  scale: scale,
                  child: const Text('🏈', style: TextStyle(fontSize: 20)),
                ),
              ),
              // 공격 방향 화살표
              if (!_ctrl.isAnimating &&
                  (state.phase == GamePhase.play ||
                      state.phase == GamePhase.extraPoint))
                Positioned(
                  left: state.possession == Team.home ? ballX + 14 : null,
                  right: state.possession == Team.away
                      ? (w - ballX + 14)
                      : null,
                  top: h / 2 - 8,
                  child: Icon(
                    state.possession == Team.home
                        ? Icons.arrow_forward
                        : Icons.arrow_back,
                    color: kGold,
                    size: 16,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _FieldPainter extends CustomPainter {
  final double ezRatio;
  _FieldPainter({required this.ezRatio});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final ezW = w * ezRatio;
    final playW = w - ezW * 2;

    // 잔디 (10야드 줄무늬)
    for (var i = 0; i < 10; i++) {
      final paint = Paint()..color = i.isEven ? kFieldGreen : kFieldDark;
      canvas.drawRect(
          Rect.fromLTWH(ezW + playW * i / 10, 0, playW / 10, h), paint);
    }
    // 엔드존
    canvas.drawRect(
        Rect.fromLTWH(0, 0, ezW, h), Paint()..color = kEndzoneHome);
    canvas.drawRect(
        Rect.fromLTWH(w - ezW, 0, ezW, h), Paint()..color = kEndzoneAway);

    // 야드 라인 + 숫자
    final linePaint = Paint()
      ..color = Colors.white38
      ..strokeWidth = 1;
    for (var i = 1; i < 10; i++) {
      final x = ezW + playW * i / 10;
      canvas.drawLine(Offset(x, 0), Offset(x, h), linePaint);
      final yard = i <= 5 ? i * 10 : (10 - i) * 10;
      final tp = TextPainter(
        text: TextSpan(
            text: '$yard',
            style: const TextStyle(color: Colors.white38, fontSize: 9)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, h - tp.height - 2));
    }

    // 엔드존 라벨
    void ezLabel(String text, double cx) {
      final tp = TextPainter(
        text: TextSpan(
            text: text,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 9,
                fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.save();
      canvas.translate(cx, h / 2);
      canvas.rotate(-1.5708);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    ezLabel('HOME', ezW / 2);
    ezLabel('AWAY', w - ezW / 2);
  }

  @override
  bool shouldRepaint(covariant _FieldPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// 주사위 표시
// ---------------------------------------------------------------------------

class DiceRow extends StatefulWidget {
  final Resolution res;

  /// 새 판정마다 증가하는 버전 (롤링 애니메이션 트리거)
  final int version;

  const DiceRow({super.key, required this.res, this.version = 0});

  @override
  State<DiceRow> createState() => _DiceRowState();
}

class _DiceRowState extends State<DiceRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1300))
      ..addListener(() => setState(() {}));
    if (GameSettings.effects) {
      _ctrl.forward();
    } else {
      _ctrl.value = 1.0; // 연출 끔: 결과값 즉시 표시
    }
  }

  @override
  void didUpdateWidget(covariant DiceRow old) {
    super.didUpdateWidget(old);
    if (widget.version != old.version) {
      if (GameSettings.effects) {
        _ctrl.forward(from: 0);
      } else {
        _ctrl.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final res = widget.res;
    final t = _ctrl.value;
    final dice = <Widget>[];
    var index = 0;

    void add(String label, int? v, int sides, Color color) {
      if (v == null) return;
      final i = index++;
      // 주사위가 왼쪽부터 순차적으로 멈춘다
      final settleAt = 0.45 + i * 0.13;
      final rolling = _ctrl.isAnimating && t < settleAt;
      // 굴러가는 동안은 의사 난수로 눈이 빠르게 바뀐다
      final shown = rolling
          ? 1 + (widget.version * 7 + i * 5 + (t * 20).floor()) % sides
          : v;
      // 멈춘 직후 살짝 커졌다 돌아오는 팝 효과
      final sinceSettle = ((t - settleAt) / 0.12).clamp(0.0, 1.0);
      final pop = _ctrl.isAnimating && !rolling ? 1.0 - sinceSettle : 0.0;
      // 구르는 동안: 회전하며 테이블 위에서 통통 튀고, 점점 잦아든다
      final decay = rolling ? 1.0 - (t / settleAt).clamp(0.0, 1.0) : 0.0;
      final angle = rolling ? math.sin(t * 48 + i * 2.1) * 0.5 * decay : 0.0;
      final bounce =
          rolling ? math.sin(t * 32 + i * 1.7).abs() * 9 * decay : 0.0;
      final drop = pop * 2; // 멈출 때 살짝 내려앉는 느낌

      dice.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 44,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Transform.translate(
                  offset: Offset(0, -bounce + drop),
                  child: Transform.rotate(
                    angle: angle,
                    child: Transform.scale(
                      scale: 1.0 + pop * 0.3,
                      child: Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black45,
                                blurRadius: 3 + bounce * 0.6,
                                offset: Offset(0, 1 + bounce * 0.4)),
                          ],
                        ),
                        child: Text('$shown',
                            style: TextStyle(
                                color: rolling ? Colors.white70 : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Text(label,
                style: const TextStyle(color: Colors.white54, fontSize: 9)),
          ],
        ),
      ));
    }

    add(loc.offD10Label, res.offD10, 10, const Color(0xFFC62828));
    add(loc.defD10Label, res.defD10, 10, const Color(0xFF283593));
    add('D12', res.offD12, 12, const Color(0xFFAD1457));
    add('D12', res.defD12, 12, const Color(0xFF4527A0));

    if (dice.isEmpty) return const SizedBox.shrink();
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: dice);
  }
}

// ---------------------------------------------------------------------------
// 카드 타일
// ---------------------------------------------------------------------------

class OffenseCardTile extends StatelessWidget {
  final OffenseCard card;
  final bool selected;
  final VoidCallback onTap;
  const OffenseCardTile({
    super.key,
    required this.card,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = card.type == PlayType.pass ? kPassBorder : kRunBorder;
    return GestureDetector(
      onTap: onTap,
      onLongPress: () => showChartDialog(context,
          title: card.name,
          chart: card.chart,
          subtitle: loc.cardDescription(card.id, card.description)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF33691E) : const Color(0xFF263238),
          border: Border.all(color: selected ? kGold : border, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  card.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  loc.offenseSubtitle(
                      card.type == PlayType.pass, card.averageYards),
                  style: TextStyle(color: border, fontSize: 9),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DefenseCardTile extends StatelessWidget {
  final DefenseCard card;
  final bool selected;
  final VoidCallback onTap;
  const DefenseCardTile({
    super.key,
    required this.card,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: () => showDefenseDialog(context, card),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF33691E) : const Color(0xFF1B2A1B),
          border: Border.all(
              color: selected ? kGold : const Color(0xFF81C784), width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            card.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 게임플랜 카드 (전술 다이어그램 포함)
// ---------------------------------------------------------------------------

class GameplanCard extends StatelessWidget {
  final String cardId;
  final String name;
  final String? subtitle;
  final bool isDefense;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const GameplanCard({
    super.key,
    required this.cardId,
    required this.name,
    this.subtitle,
    this.isDefense = false,
    required this.selected,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? kGold
        : isDefense
            ? const Color(0xFF81C784)
            : kPassBorder;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2E4A1E) : const Color(0xFF20281E),
          border: Border.all(color: borderColor, width: selected ? 2.5 : 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              child: PlayDiagram(cardId: cardId, isDefense: isDefense),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              color: selected ? const Color(0xFF33691E) : Colors.black38,
              child: Column(
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11),
                    ),
                  ),
                  if (subtitle != null)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        subtitle!,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 9),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 카드 대결 연출 (플레이 판정 시 양쪽에서 카드가 날아 들어온다)
// ---------------------------------------------------------------------------

const kPlayerLabelColor = Color(0xFF90CAF9);
const kAiLabelColor = Color(0xFFEF9A9A);

class CardFlyby extends StatefulWidget {
  final String offCardId;
  final String defCardId;
  final bool playerIsOffense;

  /// 상대가 AI인지 (false면 '친구/상대' 라벨 사용)
  final bool vsAi;

  /// 연출 종료(또는 탭 스킵) 시 호출
  final VoidCallback onDone;

  const CardFlyby({
    super.key,
    required this.offCardId,
    required this.defCardId,
    required this.playerIsOffense,
    this.vsAi = true,
    required this.onDone,
  });

  @override
  State<CardFlyby> createState() => _CardFlybyState();
}

class _CardFlybyState extends State<CardFlyby>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1700))
      ..addListener(() => setState(() {}))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onDone();
      })
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _ctrl.value;
    // 0~0.28: 슬라이드 인 / 중반: 유지 / 0.82~1: 페이드 아웃
    final tIn = Curves.easeOutBack.transform((t / 0.28).clamp(0.0, 1.0));
    final tOut = ((t - 0.82) / 0.18).clamp(0.0, 1.0);
    final slide = (1 - tIn) * 260;
    final opacity = (1.0 - Curves.easeIn.transform(tOut)).clamp(0.0, 1.0);

    final offCard = offenseById(widget.offCardId);
    final defCard = defenseById(widget.defCardId);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _ctrl.stop();
        widget.onDone();
      },
      child: Opacity(
        opacity: opacity,
        child: Container(
          color: const Color(0xB3000000),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.translate(
                offset: Offset(-slide, 0),
                child: _card(
                  label: widget.playerIsOffense
                      ? loc.myOffenseLabel
                      : (widget.vsAi
                          ? loc.aiOffenseLabel
                          : loc.oppOffenseLabel),
                  isPlayer: widget.playerIsOffense,
                  cardId: offCard.id,
                  name: offCard.name,
                  isDefense: false,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Opacity(
                  opacity: tIn.clamp(0.0, 1.0),
                  child: const Text('VS',
                      style: TextStyle(
                          color: kGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 22)),
                ),
              ),
              Transform.translate(
                offset: Offset(slide, 0),
                child: _card(
                  label: widget.playerIsOffense
                      ? (widget.vsAi
                          ? loc.aiDefenseLabel
                          : loc.oppDefenseLabel)
                      : loc.myDefenseLabel,
                  isPlayer: !widget.playerIsOffense,
                  cardId: defCard.id,
                  name: defCard.name,
                  isDefense: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({
    required String label,
    required bool isPlayer,
    required String cardId,
    required String name,
    required bool isDefense,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: TextStyle(
                color: isPlayer ? kPlayerLabelColor : kAiLabelColor,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
        const SizedBox(height: 6),
        SizedBox(
          width: 122,
          height: 152,
          child: IgnorePointer(
            child: GameplanCard(
              cardId: cardId,
              name: name,
              isDefense: isDefense,
              selected: false,
              onTap: () {},
            ),
          ),
        ),
      ],
    );
  }
}

/// 최근 플레이에 사용된 공격/수비 카드를 나란히 보여주는 다이얼로그.
/// 카드를 탭하면 상세(차트/보정) 정보를 볼 수 있다.
void showMatchupDialog(
  BuildContext context, {
  required Resolution res,
  required bool playerIsOffense,
  bool vsAi = true,
}) {
  final offId = res.offCardId, defId = res.defCardId;
  if (offId == null || defId == null) return;
  final off = offenseById(offId);
  final def = defenseById(defId);

  Widget card({
    required String label,
    required bool isPlayer,
    required Widget child,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: TextStyle(
                color: isPlayer ? kPlayerLabelColor : kAiLabelColor,
                fontWeight: FontWeight.bold,
                fontSize: 12)),
        const SizedBox(height: 6),
        SizedBox(width: 118, height: 148, child: child),
      ],
    );
  }

  showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: const Color(0xFF212121),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(loc.matchupTitle,
                style: const TextStyle(
                    color: kGold, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                card(
                  label: playerIsOffense
                      ? loc.myOffenseLabel
                      : (vsAi ? loc.aiOffenseLabel : loc.oppOffenseLabel),
                  isPlayer: playerIsOffense,
                  child: GameplanCard(
                    cardId: off.id,
                    name: off.name,
                    subtitle: loc.offenseSubtitle(
                        off.type == PlayType.pass, off.averageYards),
                    selected: false,
                    onTap: () => showChartDialog(context,
                        title: off.name,
                        chart: off.chart,
                        subtitle:
                            loc.cardDescription(off.id, off.description),
                        highlightRow: res.row,
                        highlightCol: res.col),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text('VS',
                      style: TextStyle(
                          color: kGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                ),
                card(
                  label: playerIsOffense
                      ? (vsAi ? loc.aiDefenseLabel : loc.oppDefenseLabel)
                      : loc.myDefenseLabel,
                  isPlayer: !playerIsOffense,
                  child: GameplanCard(
                    cardId: def.id,
                    name: def.name,
                    isDefense: true,
                    selected: false,
                    onTap: () => showDefenseDialog(context, def),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(loc.matchupHint,
                style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// 전체 플레이북 바텀시트
// ---------------------------------------------------------------------------

/// 전체 플레이북/수비 대형 선택 시트. 선택된 카드 id 또는 null 반환.
Future<String?> showPlaybookSheet(
  BuildContext context, {
  required String title,
  required List<({String id, String name, String? subtitle, bool isDefense})>
      children,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: const Color(0xFF1A231A),
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                style: const TextStyle(
                    color: kGold, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Text(loc.longPressHint,
                style: const TextStyle(color: Colors.white38, fontSize: 10)),
            const SizedBox(height: 8),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.95,
                children: [
                  for (final c in children)
                    GameplanCard(
                      cardId: c.id,
                      name: c.name,
                      subtitle: c.subtitle,
                      isDefense: c.isDefense,
                      selected: false,
                      onTap: () => Navigator.of(context).pop(c.id),
                      onLongPress: () {
                        if (c.isDefense) {
                          showDefenseDialog(context, defenseById(c.id));
                        } else {
                          final card = offenseById(c.id);
                          showChartDialog(context,
                              title: card.name,
                              chart: card.chart,
                              subtitle: loc.cardDescription(
                                  card.id, card.description));
                        }
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// 차트 다이얼로그
// ---------------------------------------------------------------------------

void showChartDialog(
  BuildContext context, {
  required String title,
  required List<List<String>> chart,
  String? subtitle,
  int? highlightRow,
  int? highlightCol,
}) {
  showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: const Color(0xFF212121),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                style: const TextStyle(
                    color: kGold, fontWeight: FontWeight.bold, fontSize: 16)),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(subtitle,
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 11)),
              ),
            const SizedBox(height: 8),
            FittedBox(
              child: ChartTable(
                chart: chart,
                highlightRow: highlightRow,
                highlightCol: highlightCol,
              ),
            ),
            const SizedBox(height: 4),
            Text(loc.chartLegend,
                style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
      ),
    ),
  );
}

void showDefenseDialog(BuildContext context, DefenseCard card) {
  final passes = ['long_bomb', 'long_pass', 'screen_pass', 'short_pass'];
  final runs = ['dive_plunge', 'pitch_out', 'qb_draw', 'rb_draw', 'sweep'];
  String fmt(int v) => v > 0 ? '+$v' : '$v';

  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF212121),
      title: Text(card.name,
          style: const TextStyle(color: kGold, fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.cardDescription(card.id, card.description),
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 12),
          Text(loc.passModifiers,
              style: const TextStyle(color: kPassBorder, fontSize: 12)),
          for (final id in passes)
            Text('  ${offenseById(id).name}: ${fmt(card.modifierFor(id))}',
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          const SizedBox(height: 8),
          Text(loc.runModifiers,
              style: const TextStyle(color: kRunBorder, fontSize: 12)),
          for (final id in runs)
            Text('  ${offenseById(id).name}: ${fmt(card.modifierFor(id))}',
                style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    ),
  );
}

class ChartTable extends StatelessWidget {
  final List<List<String>> chart;
  final int? highlightRow;
  final int? highlightCol;
  const ChartTable({
    super.key,
    required this.chart,
    this.highlightRow,
    this.highlightCol,
  });

  @override
  Widget build(BuildContext context) {
    Widget cell(String text,
        {bool header = false, bool highlight = false, bool special = false}) {
      return Container(
        width: 34,
        height: 24,
        alignment: Alignment.center,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: highlight
              ? kGold
              : header
                  ? const Color(0xFF37474F)
                  : const Color(0xFF455A64),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: highlight
                ? Colors.black
                : special
                    ? const Color(0xFFFF8A65)
                    : Colors.white,
            fontSize: 10,
            fontWeight:
                header || highlight ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      );
    }

    final specials = {'I', 'F', 'X', 'G', 'R'};
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            cell('', header: true),
            for (final c in columnLabels) cell(c, header: true),
          ],
        ),
        for (var r = 0; r < 5; r++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              cell(rowLabels[r], header: true),
              for (var c = 0; c < 10; c++)
                cell(
                  chart[r][c],
                  highlight: r == highlightRow && c == highlightCol,
                  special: specials.contains(chart[r][c]),
                ),
            ],
          ),
      ],
    );
  }
}
