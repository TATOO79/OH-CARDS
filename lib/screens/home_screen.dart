import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/account_store.dart';
import '../data/card_library.dart';
import '../theme/app_theme.dart';
import '../widgets/card_image.dart';
import '../widgets/parchment_background.dart';
import 'draw_screen.dart';
import 'mixed_draw_screen.dart';
import 'profile_panel.dart';

/// 主界面：混卡入口 + 十一组卡牌的选取入口，顶部带「快速抵达」，
/// 右上角有个人主页入口。
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const double _horizontalPadding = 22;
  static const double _crossSpacing = 18;
  static const double _mainSpacing = 22;
  static const double _gridTopPadding = 4;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _topKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  /// 快速抵达当前选中的入口（对应 homeEntries 下标）
  int _quickIndex = 0;

  /// 由 build 阶段测得，供快速抵达计算跳转位置
  int _columns = 2;
  double _tileExtent = 320;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _jumpToEntry(int entryIndex) {
    if (!_scrollController.hasClients) return;
    final box = _topKey.currentContext?.findRenderObject() as RenderBox?;
    final topHeight = box?.size.height ?? 0;
    // 网格与快速抵达共用同一份顺序，入口下标即网格行号
    final row = entryIndex ~/ _columns;
    final target = topHeight + _gridTopPadding + row * (_tileExtent + _mainSpacing);
    final maxExtent = _scrollController.position.maxScrollExtent;
    _scrollController.animateTo(
      target.clamp(0.0, maxExtent),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: Drawer(
        width: MediaQuery.sizeOf(context).width / 2,
        child: const ProfilePanel(),
      ),
      body: ParchmentBackground(
        mystic: true,
        child: SafeArea(
          child: ListenableBuilder(
            listenable: AccountStore.instance,
            builder: (context, _) {
              final account = AccountStore.instance;
              final entries = account.sortUnlockedFirst(
                CardLibrary.instance.homeEntries,
                (e) => e.id,
              );
              return LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 1024
                      ? 4
                      : constraints.maxWidth >= 700
                          ? 3
                          : 2;
                  final tileWidth = (constraints.maxWidth -
                          _horizontalPadding * 2 -
                          _crossSpacing * (columns - 1)) /
                      columns;
                  final tileExtent = tileWidth / kCardAspect + 70;

                  _columns = columns;
                  _tileExtent = tileExtent;

                  return CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          key: _topKey,
                          children: [
                            _HomeHeader(
                              onProfileTap: () => _scaffoldKey.currentState?.openEndDrawer(),
                            ),
                            _QuickAccess(
                              entries: entries,
                              selected: _quickIndex,
                              unlocked: account,
                              onSelect: (i) {
                                setState(() => _quickIndex = i);
                                _jumpToEntry(i);
                              },
                            ),
                          ],
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          _horizontalPadding,
                          _gridTopPadding,
                          _horizontalPadding,
                          32,
                        ),
                        sliver: SliverGrid(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            crossAxisSpacing: _crossSpacing,
                            mainAxisSpacing: _mainSpacing,
                            mainAxisExtent: tileExtent,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final entry = entries[index];
                              final unlocked = account.isUnlocked(entry.id);
                              if (entry.isMixed) {
                                return _MixedTile(locked: !unlocked);
                              }
                              return _DeckTile(deck: entry.deck!, locked: !unlocked);
                            },
                            childCount: entries.length,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.onProfileTap});

  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 26),
      child: Stack(
        children: [
          const SizedBox(
            width: double.infinity,
            child: Padding(
              padding: EdgeInsets.only(top: 14),
              child: Column(
                children: [
                  Text(
                    'OH CARDS',
                    style: TextStyle(
                      fontFamily: AppText.serif,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 7,
                      color: AppColors.wood,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text('OH卡', style: AppText.display),
                  SizedBox(height: 12),
                  Text('点击牌组进入抽卡', style: AppText.caption),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: _ProfileButton(onTap: onProfileTap),
          ),
        ],
      ),
    );
  }
}

class _ProfileButton extends StatelessWidget {
  const _ProfileButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(side: BorderSide(color: AppColors.hairline)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.person_rounded, size: 22, color: AppColors.inkSoft),
        ),
      ),
    );
  }
}

/// 快速抵达：滑动选择卡组，点击某一项即跳到主界面该入口
class _QuickAccess extends StatelessWidget {
  const _QuickAccess({
    required this.entries,
    required this.selected,
    required this.unlocked,
    required this.onSelect,
  });

  final List<HomeEntry> entries;
  final int selected;
  final AccountStore unlocked;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.hairline),
          boxShadow: AppShadows.flat,
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '您想要抽取的卡组是（点击抵达）',
                    style: AppText.eyebrow.copyWith(color: AppColors.wood, fontSize: 10),
                  ),
                ),
                // 提示用户这一行可以左右滑动
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '可左右滑动',
                      style: AppText.eyebrow.copyWith(
                        fontSize: 10,
                        color: AppColors.faint,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.swap_horiz_rounded,
                      size: 14,
                      color: AppColors.faint,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: entries.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final locked = !unlocked.isUnlocked(entry.id);
                  return _QuickChip(
                    nameZh: entry.nameZh,
                    nameEn: entry.nameEn,
                    on: index == selected && !locked,
                    locked: locked,
                    onTap: locked ? null : () => onSelect(index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.nameZh,
    required this.nameEn,
    required this.on,
    required this.locked,
    required this.onTap,
  });

  final String nameZh;
  final String nameEn;
  final bool on;
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.pill);
    final baseColor = locked ? AppColors.canvasSoft : (on ? AppColors.wood : AppColors.canvasSoft);
    final borderColor = locked
        ? Colors.transparent
        : (on ? AppColors.wood : AppColors.hairline);

    return Material(
      color: baseColor,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(borderRadius: radius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    nameZh,
                    style: AppText.title.copyWith(
                      fontSize: 14,
                      color: locked ? AppColors.muted : (on ? AppColors.canvasTop : AppColors.ink),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    nameEn,
                    style: AppText.eyebrow.copyWith(
                      fontSize: 9,
                      letterSpacing: 1.8,
                      color: locked ? AppColors.faint : (on ? AppColors.canvasTop : AppColors.muted),
                    ),
                  ),
                ],
              ),
              if (locked)
                const Positioned(
                  top: -6,
                  right: -10,
                  child: Icon(Icons.lock_rounded, size: 14, color: AppColors.muted),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 混卡入口：三张不同的牌背叠放
class _MixedTile extends StatelessWidget {
  const _MixedTile({required this.locked});

  final bool locked;

  @override
  Widget build(BuildContext context) {
    final decks = CardLibrary.instance.decks;
    final backs = [
      decks[0].thumbnailCategory.backAsset,
      decks[decks.length ~/ 2].thumbnailCategory.backAsset,
      decks.last.thumbnailCategory.backAsset,
    ];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: locked
            ? null
            : () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MixedDrawScreen()),
                ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    _MixedBackStack(backs: backs, grayscale: locked),
                    if (locked)
                      const Positioned(
                        top: 0,
                        right: 0,
                        child: Icon(Icons.lock_rounded, size: 18, color: AppColors.muted),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                kMixedNameZh,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.title.copyWith(color: locked ? AppColors.muted : AppColors.ink),
              ),
              const SizedBox(height: 4),
              Text(
                kMixedNameEn,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.eyebrow.copyWith(color: locked ? AppColors.faint : AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MixedBackStack extends StatelessWidget {
  const _MixedBackStack({required this.backs, required this.grayscale});

  final List<String> backs;
  final bool grayscale;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final cardWidth = math.max(
          1.0,
          math.min(width * 0.52, height * 0.62 * kCardAspect),
        );
        final cardHeight = cardWidth / kCardAspect;

        return Stack(
          alignment: Alignment.center,
          children: [
            for (var i = 0; i < backs.length; i++)
              Transform.translate(
                offset: Offset(
                  (i - 1) * cardWidth * 0.42,
                  i == 1 ? -cardHeight * 0.04 : cardHeight * 0.06,
                ),
                child: Transform.rotate(
                  angle: (i - 1) * 0.13,
                  child: CardImage(
                    asset: backs[i],
                    width: cardWidth,
                    height: cardHeight,
                    radius: AppRadius.md,
                    cacheWidth: 240,
                    grayscale: grayscale,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DeckTile extends StatelessWidget {
  const _DeckTile({required this.deck, required this.locked});

  final Deck deck;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final backAsset = deck.thumbnailCategory.backAsset;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: locked
            ? null
            : () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => DrawScreen(deck: deck)),
                ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    CardImage(
                      asset: backAsset,
                      radius: AppRadius.lg,
                      cacheWidth: 420,
                      grayscale: locked,
                    ),
                    if (locked)
                      const Positioned(
                        top: 4,
                        right: 4,
                        child: Icon(Icons.lock_rounded, size: 18, color: AppColors.muted),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                deck.def.nameZh,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.title.copyWith(color: locked ? AppColors.muted : AppColors.ink),
              ),
              const SizedBox(height: 4),
              Text(
                deck.def.nameEn,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.eyebrow.copyWith(color: locked ? AppColors.faint : AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
