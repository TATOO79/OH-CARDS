import 'package:flutter/material.dart';

import '../data/card_library.dart';
import '../data/draw_history.dart';
import '../theme/app_theme.dart';
import '../widgets/app_controls.dart';
import '../widgets/card_image.dart';
import '../widgets/parchment_background.dart';

/// 本轮结果：这一轮抽到的每张牌各占一格，上方序号、下方卡组与子卡组。
///
/// 卡牌整体水平居中，牌面高度固定，因此不同卡组的牌面与卡组名始终对齐；
/// 没有子卡组的卡组少一行，多出来的空间留在格子底部。
class RoundResultScreen extends StatelessWidget {
  const RoundResultScreen({
    super.key,
    required this.cards,
    this.eyebrow = kMixedNameEn,
    this.backLabel = '返回多组同抽界面',
  });

  final List<DrawnCard> cards;

  /// 标题上方的英文眉标（混卡为 MIXED，普通卡组为该组英文名）
  final String eyebrow;

  /// 第一个返回按钮的文案
  final String backLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ParchmentBackground(
        child: SafeArea(
          child: Column(
            children: [
              _ResultHeader(eyebrow: eyebrow),
              Expanded(
                child: cards.isEmpty
                    ? Center(child: Text('本轮还没有抽卡记录', style: AppText.caption))
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          const horizontalPadding = 22.0;
                          const spacing = 16.0;
                          final usable = constraints.maxWidth - horizontalPadding * 2;
                          final columns = (usable / 108).floor().clamp(2, 6);
                          final itemWidth = (usable - spacing * (columns - 1)) / columns;
                          final imageHeight = itemWidth / kCardAspect;

                          return SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(
                              horizontalPadding,
                              4,
                              horizontalPadding,
                              16,
                            ),
                            child: Wrap(
                              // 结果不足一行时整体居中，不靠左
                              alignment: WrapAlignment.center,
                              spacing: spacing,
                              runSpacing: 26,
                              children: [
                                for (var i = 0; i < cards.length; i++)
                                  SizedBox(
                                    width: itemWidth,
                                    child: _ResultCell(
                                      order: i + 1,
                                      card: cards[i],
                                      imageHeight: imageHeight,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              _ResultActions(
                backLabel: backLabel,
                onBack: () => Navigator.of(context).pop(),
                onHome: () => Navigator.of(context).popUntil((route) => route.isFirst),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultHeader extends StatelessWidget {
  const _ResultHeader({required this.eyebrow});

  final String eyebrow;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
      child: Column(
        children: [
          Text(
            eyebrow,
            style: AppText.eyebrow.copyWith(color: AppColors.wood, fontSize: 10, letterSpacing: 4),
          ),
          const SizedBox(height: 10),
          const Text('本轮结果', style: AppText.displaySm),
          const SizedBox(height: 6),
          const Text('ROUND RESULTS', style: AppText.eyebrow),
        ],
      ),
    );
  }
}

class _ResultCell extends StatelessWidget {
  const _ResultCell({required this.order, required this.card, required this.imageHeight});

  final int order;
  final DrawnCard card;
  final double imageHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$order',
          textAlign: TextAlign.center,
          style: AppText.eyebrow.copyWith(
            fontSize: 12,
            height: 1.3,
            letterSpacing: 0,
            color: AppColors.wood,
          ),
        ),
        const SizedBox(height: 6),
        // 牌面高度固定，所有卡片的图片在同一水平线上对齐
        SizedBox(
          height: imageHeight,
          child: CardThumb(asset: card.asset, radius: AppRadius.md, cacheWidth: 280),
        ),
        const SizedBox(height: 8),
        Text(
          card.deckNameZh,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.title.copyWith(fontSize: 12.5, height: 1.3, letterSpacing: 0.4),
        ),
        // 有子卡组的才多一行，排在卡组名下面
        if (!card.isWholeDeck) ...[
          const SizedBox(height: 2),
          Text(
            card.categoryLabelZh,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.eyebrow.copyWith(
              fontSize: 11,
              height: 1.3,
              letterSpacing: 0.8,
              color: AppColors.muted,
            ),
          ),
        ],
      ],
    );
  }
}

class _ResultActions extends StatelessWidget {
  const _ResultActions({
    required this.backLabel,
    required this.onBack,
    required this.onHome,
  });

  final String backLabel;
  final VoidCallback onBack;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: AppPillButton(
              label: backLabel,
              icon: Icons.arrow_back_rounded,
              onTap: onBack,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: AppPillButton(
              label: '返回主菜单',
              icon: Icons.home_outlined,
              filled: false,
              onTap: onHome,
            ),
          ),
        ],
      ),
    );
  }
}
