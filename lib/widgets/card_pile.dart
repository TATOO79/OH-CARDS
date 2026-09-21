import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'card_image.dart';

/// 叠放牌堆时每张牌背的错位量（像素）
const double kPileOffset = 4;

/// 按下时轻微缩小，给点击一点手感。
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        child: widget.child,
      ),
    );
  }
}

/// 牌堆的错位叠放：底下 [layers] 张牌背往右下错开，最上面可以再压一张没翻开的牌。
///
/// 最上面那张固定画在 (0, 0)，翻牌时它就是被翻走的那张，
/// 因此牌堆到牌面的过程没有任何位移。
class PileUnderlay extends StatelessWidget {
  const PileUnderlay({
    super.key,
    required this.backAsset,
    required this.cardWidth,
    this.layers = 2,
    this.topCard = true,
  });

  final String backAsset;
  final double cardWidth;

  /// 错位叠放的张数
  final int layers;

  /// 最上面是否还压着一张没翻开的牌背
  final bool topCard;

  @override
  Widget build(BuildContext context) {
    final cardHeight = cardWidth / kCardAspect;

    return SizedBox(
      width: cardWidth + kPileOffset * layers,
      height: cardHeight + kPileOffset * layers,
      child: Stack(
        children: [
          // 由下往上画，越靠上的越后画
          for (var i = layers; i >= 1; i--)
            Positioned(
              left: kPileOffset * i,
              top: kPileOffset * i,
              width: cardWidth,
              height: cardHeight,
              child: CardImage(
                asset: backAsset,
                radius: AppRadius.md,
                cacheWidth: 320,
                shadows: const [
                  BoxShadow(color: Color(0x1F2E241C), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
            ),
          if (topCard)
            Positioned(
              left: 0,
              top: 0,
              width: cardWidth,
              height: cardHeight,
              child: CardImage(
                asset: backAsset,
                radius: AppRadius.md,
                cacheWidth: 420,
                shadows: AppShadows.flat,
              ),
            ),
        ],
      ),
    );
  }
}

/// 翻牌动画：绕 Y 轴原地翻转，前半程显示牌背，后半程显示牌面。
///
/// 尺寸在整个过程中保持不变，观感上就是同一张牌翻了过来。
class FlipCard extends StatelessWidget {
  const FlipCard({
    super.key,
    required this.progress,
    required this.backAsset,
    required this.frontAsset,
    required this.width,
    required this.height,
  });

  final double progress;
  final String backAsset;
  final String frontAsset;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final angle = progress * math.pi;
    final showFront = angle > math.pi / 2;
    final perspective = Matrix4.identity()..setEntry(3, 2, 0.0015);

    Widget face;
    if (showFront) {
      final dpr = MediaQuery.devicePixelRatioOf(context);
      face = CardImage(
        asset: frontAsset,
        width: width,
        height: height,
        radius: AppRadius.md,
        cacheWidth: math.min(800, (width * dpr).round()),
        shadows: AppShadows.lifted,
      );
      // 牌面已经跟着外层转了 180°，这里再转回来，避免镜像
      face = Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0015)
          ..rotateY(math.pi),
        child: face,
      );
    } else {
      face = CardImage(
        asset: backAsset,
        width: width,
        height: height,
        radius: AppRadius.md,
        cacheWidth: 460,
        shadows: AppShadows.flat,
      );
    }

    return Transform(
      alignment: Alignment.center,
      transform: perspective..rotateY(angle),
      child: face,
    );
  }
}
