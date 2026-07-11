/// 플레이별 전술 다이어그램 (X/O 표기).
///
/// 좌표계: 가로 0~1, 세로 0~1. 공격은 아래(y=0.62 라인)에서 위로 진행.
library;

import 'dart:math';

import 'package:flutter/material.dart';

class PlayDiagram extends StatelessWidget {
  final String cardId;
  final bool isDefense;
  const PlayDiagram({super.key, required this.cardId, this.isDefense = false});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: isDefense
          ? _DefenseDiagramPainter(cardId)
          : _OffenseDiagramPainter(cardId),
      size: Size.infinite,
    );
  }
}

// ---------------------------------------------------------------------------
// 공통 그리기 헬퍼
// ---------------------------------------------------------------------------

abstract class _DiagramPainter extends CustomPainter {
  static const losY = 0.62; // 스크리미지 라인 y 비율

  late Size _size;
  late Canvas _canvas;

  Offset p(double x, double y) => Offset(x * _size.width, y * _size.height);

  void drawBackground() {
    final paint = Paint()..color = const Color(0xFF1E3B24);
    _canvas.drawRect(Offset.zero & _size, paint);
    // 야드 라인
    final line = Paint()
      ..color = Colors.white12
      ..strokeWidth = 1;
    for (final y in [0.15, 0.38, losY, 0.85]) {
      _canvas.drawLine(p(0, y), p(1, y), line);
    }
    // 스크리미지 라인 강조
    _canvas.drawLine(
        p(0, losY),
        p(1, losY),
        Paint()
          ..color = Colors.white38
          ..strokeWidth = 1.5);
  }

  /// 공격수 (O)
  void o(double x, double y, {Color color = Colors.white}) {
    _canvas.drawCircle(
        p(x, y),
        _size.shortestSide * 0.045,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6);
  }

  /// 수비수 (X)
  void xMark(double x, double y, {Color color = const Color(0xFFEF9A9A)}) {
    final r = _size.shortestSide * 0.04;
    final c = p(x, y);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6;
    _canvas.drawLine(c + Offset(-r, -r), c + Offset(r, r), paint);
    _canvas.drawLine(c + Offset(-r, r), c + Offset(r, -r), paint);
  }

  /// 루트 화살표 (점 목록을 잇고 끝에 화살촉)
  void route(List<Offset> pts,
      {Color color = const Color(0xFFFFC107), bool dashed = false}) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final abs = [for (final pt in pts) p(pt.dx, pt.dy)];

    if (dashed) {
      for (var i = 0; i < abs.length - 1; i++) {
        _dashedLine(abs[i], abs[i + 1], paint);
      }
    } else {
      final path = Path()..moveTo(abs.first.dx, abs.first.dy);
      for (final pt in abs.skip(1)) {
        path.lineTo(pt.dx, pt.dy);
      }
      _canvas.drawPath(path, paint);
    }
    // 화살촉
    final end = abs.last;
    final prev = abs[abs.length - 2];
    final dir = (end - prev).direction;
    final len = _size.shortestSide * 0.07;
    for (final spread in [-0.5, 0.5]) {
      _canvas.drawLine(
          end,
          end - Offset.fromDirection(dir + spread, len),
          paint);
    }
  }

  void _dashedLine(Offset a, Offset b, Paint paint) {
    const dash = 4.0, gap = 3.0;
    final total = (b - a).distance;
    final dir = (b - a) / total;
    var t = 0.0;
    while (t < total) {
      final end = min(t + dash, total);
      _canvas.drawLine(a + dir * t, a + dir * end, paint);
      t = end + gap;
    }
  }

  /// 오펜시브 라인 5명 + QB
  void offenseBase() {
    for (var i = -2; i <= 2; i++) {
      o(0.5 + i * 0.09, losY + 0.06);
    }
    o(0.5, losY + 0.17); // QB
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// 공격 플레이 다이어그램
// ---------------------------------------------------------------------------

class _OffenseDiagramPainter extends _DiagramPainter {
  final String cardId;
  _OffenseDiagramPainter(this.cardId);

  @override
  void paint(Canvas canvas, Size size) {
    _canvas = canvas;
    _size = size;
    drawBackground();
    const losY = _DiagramPainter.losY;

    switch (cardId) {
      case 'dive_plunge':
        offenseBase();
        o(0.5, losY + 0.28); // RB
        route([const Offset(0.5, losY + 0.26), const Offset(0.46, 0.30)]);
      case 'pitch_out':
        offenseBase();
        o(0.42, losY + 0.28);
        route([
          const Offset(0.5, losY + 0.15),
          const Offset(0.66, losY + 0.24),
        ], dashed: true); // 피치
        route([
          const Offset(0.68, losY + 0.24),
          const Offset(0.84, losY + 0.10),
          const Offset(0.86, 0.30),
        ]);
      case 'sweep':
        offenseBase();
        o(0.44, losY + 0.28);
        route([
          const Offset(0.44, losY + 0.26),
          const Offset(0.70, losY + 0.18),
          const Offset(0.88, losY - 0.05),
          const Offset(0.90, 0.28),
        ]);
      case 'qb_draw':
        offenseBase();
        route([
          const Offset(0.5, losY + 0.17),
          const Offset(0.5, losY + 0.26),
        ], dashed: true); // 페이크 드롭
        route([const Offset(0.5, losY + 0.26), const Offset(0.55, 0.30)]);
        // 넓게 벌린 리시버 (미끼)
        o(0.08, losY + 0.04);
        o(0.92, losY + 0.04);
      case 'rb_draw':
        offenseBase();
        o(0.5, losY + 0.28);
        route([
          const Offset(0.5, losY + 0.28),
          const Offset(0.44, losY + 0.30),
        ], dashed: true); // 딜레이
        route([const Offset(0.44, losY + 0.30), const Offset(0.42, 0.30)]);
        o(0.08, losY + 0.04);
        o(0.92, losY + 0.04);
      case 'short_pass':
        offenseBase();
        o(0.10, losY + 0.04);
        o(0.90, losY + 0.04);
        route([
          const Offset(0.10, losY + 0.02),
          const Offset(0.10, 0.46),
          const Offset(0.30, 0.36),
        ]); // 슬랜트
        route([
          const Offset(0.90, losY + 0.02),
          const Offset(0.90, 0.44),
          const Offset(0.74, 0.40),
        ]);
      case 'screen_pass':
        offenseBase();
        o(0.40, losY + 0.28);
        route([
          const Offset(0.5, losY + 0.17),
          const Offset(0.44, losY + 0.30),
        ], dashed: true);
        route([
          const Offset(0.40, losY + 0.28),
          const Offset(0.22, losY + 0.20),
          const Offset(0.16, 0.42),
        ]);
        o(0.90, losY + 0.04);
        route([
          const Offset(0.90, losY + 0.02),
          const Offset(0.90, 0.34),
        ], dashed: true); // 미끼 딥 루트
      case 'long_pass':
        offenseBase();
        o(0.10, losY + 0.04);
        o(0.90, losY + 0.04);
        route([
          const Offset(0.10, losY + 0.02),
          const Offset(0.10, 0.28),
          const Offset(0.28, 0.12),
        ]); // 포스트
        route([
          const Offset(0.90, losY + 0.02),
          const Offset(0.90, 0.30),
          const Offset(0.76, 0.18),
        ]);
      case 'long_bomb':
        offenseBase();
        o(0.10, losY + 0.04);
        o(0.90, losY + 0.04);
        route([const Offset(0.10, losY + 0.02), const Offset(0.10, 0.06)]);
        route([const Offset(0.90, losY + 0.02), const Offset(0.90, 0.06)]);
        route([
          const Offset(0.5, losY + 0.17),
          const Offset(0.52, 0.10),
        ], dashed: true); // 긴 패스 궤적
    }
  }
}

// ---------------------------------------------------------------------------
// 수비 대형 다이어그램
// ---------------------------------------------------------------------------

class _DefenseDiagramPainter extends _DiagramPainter {
  final String cardId;
  _DefenseDiagramPainter(this.cardId);

  @override
  void paint(Canvas canvas, Size size) {
    _canvas = canvas;
    _size = size;
    drawBackground();
    const losY = _DiagramPainter.losY;

    // 공격 라인 (참고용 O)
    for (var i = -2; i <= 2; i++) {
      o(0.5 + i * 0.09, losY + 0.06, color: Colors.white30);
    }

    void linemen(int n) {
      final start = 0.5 - (n - 1) * 0.045;
      for (var i = 0; i < n; i++) {
        xMark(start + i * 0.09, losY - 0.07);
      }
    }

    void lbs(int n, {double y = 0.42}) {
      final start = 0.5 - (n - 1) * 0.06;
      for (var i = 0; i < n; i++) {
        xMark(start + i * 0.12, y);
      }
    }

    void corners({double y = 0.50}) {
      xMark(0.08, y);
      xMark(0.92, y);
    }

    void safeties(int n, {double y = 0.16}) {
      if (n == 1) {
        xMark(0.5, y);
      } else {
        xMark(0.32, y);
        xMark(0.68, y);
      }
    }

    switch (cardId) {
      case 'four_three':
        linemen(4);
        lbs(3);
        corners();
        safeties(2);
      case 'three_four':
        linemen(3);
        lbs(4);
        corners();
        safeties(2);
      case 'nickel':
        linemen(4);
        lbs(2);
        corners();
        xMark(0.24, 0.50); // 니켈백
        safeties(2);
      case 'dime':
        linemen(4);
        lbs(1);
        corners();
        xMark(0.24, 0.50);
        xMark(0.76, 0.50);
        safeties(2);
      case 'prevent':
        linemen(3);
        corners(y: 0.36);
        xMark(0.28, 0.24);
        xMark(0.72, 0.24);
        safeties(2, y: 0.10);
        xMark(0.5, 0.30);
      case 'zone':
        linemen(4);
        lbs(3);
        corners();
        safeties(2);
        // 존 커버 원
        for (final z in [const Offset(0.2, 0.34), const Offset(0.5, 0.30), const Offset(0.8, 0.34)]) {
          _canvas.drawCircle(
              p(z.dx, z.dy),
              _size.shortestSide * 0.11,
              Paint()
                ..color = Colors.white24
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1);
        }
      case 'man_to_man':
        linemen(4);
        lbs(3);
        // 프레스 커버 (라인 바로 위)
        xMark(0.08, losY - 0.09);
        xMark(0.92, losY - 0.09);
        safeties(2);
      case 'blitz':
        linemen(4);
        lbs(3, y: 0.46);
        // 블리츠 돌진 화살표
        route([const Offset(0.38, 0.46), const Offset(0.44, losY + 0.02)],
            color: const Color(0xFFEF5350));
        route([const Offset(0.62, 0.46), const Offset(0.56, losY + 0.02)],
            color: const Color(0xFFEF5350));
        corners();
        safeties(1);
      case 'goal_line':
        linemen(6);
        lbs(3, y: 0.48);
        corners(y: 0.40);
    }
  }
}
