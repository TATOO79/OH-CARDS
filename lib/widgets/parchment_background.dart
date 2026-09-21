import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 羊皮纸底：缓渐变 + 两处极淡柔光，避免纯色的塑料感。
///
/// [mystic] 为 true 时叠加极淡的神秘学线描装饰（弦月、星点、曼陀罗），
/// 用于主界面营造自我沉思、冥想的氛围；装饰固定在背景层，不随内容滚动。
class ParchmentBackground extends StatelessWidget {
  const ParchmentBackground({
    super.key,
    required this.child,
    this.mystic = false,
  });

  final Widget child;

  /// 是否叠加神秘学装饰（仅主界面开启）
  final bool mystic;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppTheme.parchment),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned(
            top: -160,
            left: -140,
            child: _Glow(size: 420, color: AppColors.canvasTop),
          ),
          const Positioned(
            bottom: -200,
            right: -160,
            child: _Glow(size: 520, color: AppColors.canvasSoft),
          ),
          if (mystic)
            const Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _MysticPainter()),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.9), color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

/// 神秘学装饰画笔：与网页版 index/app 中的装饰同源——
/// 左上弦月与星点、右下大型曼陀罗、左下同心圆，全部用极淡的木色线描。
class _MysticPainter extends CustomPainter {
  const _MysticPainter();

  // 浓度与网页端 styles.css 的玄学装饰保持一致
  static const double _moonAlpha = 0.13;
  static const double _starAlpha = 0.20;
  static const double _dotAlpha = 0.22;
  static const double _mandalaAlpha = 0.11;
  static const double _ringsAlpha = 0.09;

  double _clamp(double v, double low, double high) =>
      v < low ? low : (v > high ? high : v);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _paintMoon(canvas, w, h);
    _paintMandala(canvas, w, h);
    _paintRings(canvas, w, h);
  }

  // ---------- 弦月 + 星点（对应网页 .ml-moon，160×200 坐标系） ----------
  void _paintMoon(Canvas canvas, double w, double h) {
    final moonW = _clamp(w * 0.13, 86, 140);
    final scale = moonW / 160;
    final left = _clamp(w * 0.03, 8, 40);
    final top = _clamp(h * 0.09, 56, 110);

    canvas.save();
    canvas.translate(left, top);
    canvas.scale(scale);

    // 弦月：外弧 r=22、内弧 r=30，开口朝右
    final moon = Path()
      ..moveTo(22 + 18, 0 + 10)
      ..arcToPoint(
        const Offset(22 + 18, 44 + 10),
        radius: const Radius.circular(22),
        clockwise: false,
        largeArc: true,
      )
      ..arcToPoint(
        const Offset(22 + 18, 0 + 10),
        radius: const Radius.circular(30),
        clockwise: false,
        largeArc: true,
      )
      ..close();
    canvas.drawPath(
      moon,
      Paint()
        ..color = AppColors.wood.withValues(alpha: _moonAlpha)
        ..style = PaintingStyle.fill,
    );

    final starPaint = Paint()
      ..color = AppColors.wood.withValues(alpha: _starAlpha)
      ..style = PaintingStyle.fill;
    final dotPaint = Paint()
      ..color = AppColors.wood.withValues(alpha: _dotAlpha)
      ..style = PaintingStyle.fill;

    _star(canvas, 104, 20, 0.8, starPaint);
    _star(canvas, 132, 66, 0.5, starPaint);
    _star(canvas, 40, 128, 0.45, starPaint);
    canvas.drawCircle(const Offset(84, 78), 1.6, dotPaint);
    canvas.drawCircle(const Offset(118, 104), 1.2, dotPaint);

    canvas.restore();
  }

  /// 四角星芒（与网页 star path 同形，基准半径约 7）
  void _star(Canvas canvas, double cx, double cy, double s, Paint paint) {
    final p = Path()
      ..moveTo(cx, cy - 7 * s)
      ..lineTo(cx + 1.8 * s, cy - 1.8 * s)
      ..lineTo(cx + 7 * s, cy)
      ..lineTo(cx + 1.8 * s, cy + 1.8 * s)
      ..lineTo(cx, cy + 7 * s)
      ..lineTo(cx - 1.8 * s, cy + 1.8 * s)
      ..lineTo(cx - 7 * s, cy)
      ..lineTo(cx - 1.8 * s, cy - 1.8 * s)
      ..close();
    canvas.drawPath(p, paint);
  }

  // ---------- 右下曼陀罗（对应网页 .ml-mandala，560×560 坐标系） ----------
  void _paintMandala(Canvas canvas, double w, double h) {
    final mandalaSize = _clamp(w * 0.38, 230, 520);
    final scale = mandalaSize / 560;
    final rightOff = _clamp(w * 0.10, 40, 120);
    final bottomOff = _clamp(h * 0.12, 60, 150);
    final cx = w - rightOff; // 280/560 中心点
    final cy = h - bottomOff;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(scale);

    final linePaint = Paint()
      ..color = AppColors.wood.withValues(alpha: _mandalaAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8 / scale;

    for (final r in [268.0, 232.0, 150.0, 104.0, 46.0]) {
      canvas.drawCircle(Offset.zero, r, linePaint);
    }

    // 两圈花瓣：12 片外圈 + 12 片内圈交错
    final petalPaint = Paint()
      ..color = AppColors.wood.withValues(alpha: _mandalaAlpha * 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7 / scale;
    for (var i = 0; i < 12; i++) {
      canvas.save();
      canvas.rotate(i * 30 * math.pi / 180);
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, -172), width: 48, height: 132),
        petalPaint,
      );
      canvas.restore();
    }
    for (var i = 0; i < 12; i++) {
      canvas.save();
      canvas.rotate((i * 30 + 15) * math.pi / 180);
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, -116), width: 28, height: 80),
        petalPaint,
      );
      canvas.restore();
    }

    // 外圈 24 道放射线
    for (var i = 0; i < 24; i++) {
      canvas.save();
      canvas.rotate(i * 15 * math.pi / 180);
      canvas.drawLine(
        const Offset(0, -232),
        const Offset(0, -250),
        linePaint,
      );
      canvas.restore();
    }

    canvas.restore();
  }

  // ---------- 左下同心圆（对应网页 .ml-rings，200×200 坐标系） ----------
  void _paintRings(Canvas canvas, double w, double h) {
    final ringSize = _clamp(w * 0.18, 130, 200);
    final scale = ringSize / 200;
    final leftOff = _clamp(w * 0.06, 24, 70);
    final cx = -leftOff; // 100/200 中心点
    final cy = h - h * 0.06;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(scale);

    final paint = Paint()
      ..color = AppColors.wood.withValues(alpha: _ringsAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8 / scale;
    for (final r in [92.0, 64.0, 36.0]) {
      canvas.drawCircle(Offset.zero, r, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MysticPainter oldDelegate) => false;
}
