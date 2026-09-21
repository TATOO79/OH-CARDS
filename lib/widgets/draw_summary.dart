import 'package:flutter/material.dart';

import '../data/draw_history.dart';
import '../theme/app_theme.dart';
import 'card_image.dart';

/// 本次抽卡汇总框：按顺序排列已抽出的牌面，
/// 上方标注顺序、下方标注来自哪一类卡（图卡 / 字卡 …）。
///
/// 每行四张，牌多了在框内上下滑动。框高固定，与底部控制区一起构成
/// 固定高度的底部区域，这样抽卡前后牌面尺寸完全一致，不会跳动。
class DrawSummaryPanel extends StatelessWidget {
  const DrawSummaryPanel({
    super.key,
    required this.cards,
    this.showDeck = false,
    this.title = '本次汇总',
  });

  final List<DrawnCard> cards;

  /// 混卡模式下同一轮会跨卡组，需要在牌面下额外标出卡组名
  final bool showDeck;

  final String title;

  /// 框体高度
  static const double panelHeight = 156;

  /// 与屏幕下边缘之间的留白
  static const double bottomMargin = 12;

  /// 每行张数
  static const int columns = 4;

  static const double _horizontalMargin = 16;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: panelHeight,
      margin: const EdgeInsets.symmetric(horizontal: _horizontalMargin),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.hairline),
        boxShadow: AppShadows.flat,
      ),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                title,
                style: AppText.eyebrow.copyWith(color: AppColors.wood, fontSize: 10),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '共 ${cards.length} 张',
                  style: AppText.eyebrow.copyWith(color: AppColors.faint, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            // 每个格子正好占满框内可视高度，因此一屏看到一行，往下滑看更多
            child: LayoutBuilder(
              builder: (context, constraints) => GridView.builder(
                padding: EdgeInsets.zero,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: constraints.maxHeight,
                ),
                itemCount: cards.length,
                itemBuilder: (context, index) => _SummaryItem(
                  order: index + 1,
                  card: cards[index],
                  showDeck: showDeck,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.order,
    required this.card,
    required this.showDeck,
  });

  final int order;
  final DrawnCard card;
  final bool showDeck;

  @override
  Widget build(BuildContext context) {
    final labelStyle = AppText.eyebrow.copyWith(
      fontSize: 9,
      height: 1.3,
      letterSpacing: 0.4,
      color: AppColors.muted,
    );
    final orderStyle = AppText.eyebrow.copyWith(
      fontSize: 11,
      height: 1.3,
      letterSpacing: 0,
      color: AppColors.wood,
    );

    // 标注区高度固定（字号 9 × 行高 1.3，一行约 12px）。混卡时有的牌标两行
    // （卡组 + 子卡组）、有的只标一行，固定占位后同一行里的牌面才会一样大。
    // 高度跟着系统字号一起放大，避免用户放大字体时顶破这块固定区域。
    final lineHeight = MediaQuery.textScalerOf(context).scale(9) * 1.3;
    // 多留半像素，避免正好卡在边界上
    final labelHeight = lineHeight * (showDeck ? 2 : 1) + 0.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('$order', textAlign: TextAlign.center, style: orderStyle),
        const SizedBox(height: 4),
        // 牌面占据剩余空间，文字永远拿得到自己需要的高度，不会溢出
        Expanded(child: CardThumb(asset: card.asset, cacheWidth: 200)),
        const SizedBox(height: 5),
        SizedBox(
          height: labelHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 单组卡组（克服卡 …）没有子卡组，只标这一组自己的名字
              if (showDeck && !card.isWholeDeck)
                Text(
                  card.deckNameZh,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: labelStyle,
                ),
              Text(
                card.isWholeDeck ? card.deckNameZh : card.categoryLabelZh,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: labelStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
