import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 统一的卡牌图片：圆角、极细描边与柔和阴影
class CardImage extends StatelessWidget {
  const CardImage({
    super.key,
    required this.asset,
    this.width,
    this.height,
    this.radius = AppRadius.md,
    this.cacheWidth,
    this.shadows = AppShadows.flat,
    this.grayscale = false,
  });

  final String asset;
  final double? width;
  final double? height;
  final double radius;
  final int? cacheWidth;
  final List<BoxShadow> shadows;

  /// 置灰显示（用于未解锁的卡组）
  final bool grayscale;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: AppColors.surface,
        boxShadow: shadows,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColorFiltered(
              colorFilter: ColorFilter.matrix(
                grayscale ? _grayscaleMatrix : _identityMatrix,
              ),
              child: Image.asset(
                asset,
                fit: BoxFit.cover,
                cacheWidth: cacheWidth,
                filterQuality: FilterQuality.medium,
                gaplessPlayback: true,
              ),
            ),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  border: Border.all(color: AppColors.hairline.withValues(alpha: 0.85), width: 0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const List<double> _identityMatrix = [
    1, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0, 0, 0, 1, 0,
  ];

  static const List<double> _grayscaleMatrix = [
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ];
}

/// 在给定空间内等比缩放并居中的卡牌缩略图。
///
/// 高度由父级约束决定，因此放在 Expanded / Flexible 里也不会溢出。
class CardThumb extends StatelessWidget {
  const CardThumb({
    super.key,
    required this.asset,
    this.radius = AppRadius.sm,
    this.cacheWidth = 220,
    this.grayscale = false,
  });

  final String asset;
  final double radius;
  final int? cacheWidth;
  final bool grayscale;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : 0.0;
        final maxHeight = constraints.maxHeight.isFinite ? constraints.maxHeight : 0.0;
        final width = math.max(1.0, math.min(maxWidth, maxHeight * kCardAspect));
        return Center(
          child: CardImage(
            asset: asset,
            width: width,
            height: width / kCardAspect,
            radius: radius,
            cacheWidth: cacheWidth,
            grayscale: grayscale,
          ),
        );
      },
    );
  }
}

