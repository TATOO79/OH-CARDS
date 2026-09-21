import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/card_library.dart';
import '../theme/app_theme.dart';
import 'card_pile.dart';

/// 抽卡舞台：中间一叠（或两叠）牌背朝上的牌，点击后有第一张牌翻转的动画。
///
/// 单叠 / 双叠由 categories 的长度决定；每叠独立抽卡与揭示。
class CardStage extends StatelessWidget {
  const CardStage({
    super.key,
    required this.categories,
    required this.controllers,
    required this.drawn,
    required this.onTapCategory,
    required this.hint,
    this.emptyHint = '请至少开启一类卡牌',
    this.hintTopPadding = 16,
  });

  final List<CardCategory> categories;
  final Map<String, AnimationController> controllers;
  final Map<String, String> drawn;
  final ValueChanged<String> onTapCategory;
  final String hint;
  final String emptyHint;

  /// 提示文字与上方内容之间的间距（混卡界面卡组栏较高，可加大）
  final double hintTopPadding;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Center(child: Text(emptyHint, style: AppText.caption));
    }

    return Column(
      children: [
        Padding(
          // 与上方标题栏 / 分类开关之间留出空白
          padding: EdgeInsets.fromLTRB(20, hintTopPadding, 20, 14),
          child: Text(hint, textAlign: TextAlign.center, style: AppText.caption),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const gap = 12.0;
                final count = categories.length;
                final areaWidth = (constraints.maxWidth - gap * (count - 1)) / count;

                return Row(
                  children: [
                    for (var i = 0; i < count; i++) ...[
                      if (i > 0) const SizedBox(width: gap),
                      SizedBox(
                        width: areaWidth,
                        child: _StageSlot(
                          category: categories[i],
                          controller: controllers[categories[i].id]!,
                          drawnAsset: drawn[categories[i].id],
                          multi: count > 1,
                          areaWidth: areaWidth,
                          areaHeight: constraints.maxHeight,
                          onTap: () => onTapCategory(categories[i].id),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _StageSlot extends StatelessWidget {
  const _StageSlot({
    required this.category,
    required this.controller,
    required this.drawnAsset,
    required this.multi,
    required this.areaWidth,
    required this.areaHeight,
    required this.onTap,
  });

  final CardCategory category;
  final AnimationController controller;
  final String? drawnAsset;
  final bool multi;
  final double areaWidth;
  final double areaHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // 并排两叠时才在牌面下方标分类名，单叠不需要为它预留高度
    final labelHeight = multi ? 26.0 : 0.0;

    // 底下两张错位叠放，牌堆会往右下多露出这一点边缘
    const stackPad = kPileOffset * 2;

    // 牌堆与牌面共用同一个尺寸：翻牌就是这张牌原地的翻转，不放大也不位移
    final cardWidth = math.min(
      areaWidth - stackPad,
      (areaHeight - labelHeight - stackPad) * kCardAspect * 0.97,
    );
    final cardHeight = cardWidth / kCardAspect;

    final label = multi ? '${category.labelZh} ${category.labelEn}' : null;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final asset = drawnAsset;

        return Center(
          child: PressScale(
            onTap: onTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: cardWidth + stackPad,
                  height: cardHeight + stackPad,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // 最上面那张就是被翻走的那张：翻开后只留下面的错位牌背
                      Positioned(
                        left: 0,
                        top: 0,
                        child: PileUnderlay(
                          backAsset: category.backAsset,
                          cardWidth: cardWidth,
                          topCard: asset == null,
                        ),
                      ),
                      if (asset != null)
                        Positioned(
                          left: 0,
                          top: 0,
                          width: cardWidth,
                          height: cardHeight,
                          child: FlipCard(
                            progress: controller.value,
                            backAsset: category.backAsset,
                            frontAsset: asset,
                            width: cardWidth,
                            height: cardHeight,
                          ),
                        ),
                    ],
                  ),
                ),
                if (label != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(label, style: AppText.eyebrow.copyWith(fontSize: 10)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
