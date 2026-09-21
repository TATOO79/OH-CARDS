import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/account_store.dart';
import '../data/card_library.dart';
import '../data/draw_history.dart';
import '../theme/app_theme.dart';
import '../widgets/app_controls.dart';
import '../widgets/card_stage.dart';
import '../widgets/deck_drawer.dart';
import '../widgets/draw_summary.dart';
import '../widgets/parchment_background.dart';
import 'round_result_screen.dart';

/// 混卡抽卡界面：可用全部十一组牌组抽取，结果汇总在下方框内，
/// 结束时进入「本轮结果」。
class MixedDrawScreen extends StatefulWidget {
  const MixedDrawScreen({super.key});

  @override
  State<MixedDrawScreen> createState() => _MixedDrawScreenState();
}

class _MixedDrawScreenState extends State<MixedDrawScreen> with TickerProviderStateMixin {
  static const Duration _flipDuration = Duration(milliseconds: 640);

  /// 底部控制区（结束本轮抽卡）的高度
  static const double _controlsHeight = 58;

  /// 底部区域总高度：控制区 + 汇总框 + 底部留白。
  /// 高度固定，抽卡前后牌面尺寸才不会跳动。
  static const double _bottomAreaHeight =
      _controlsHeight + DrawSummaryPanel.panelHeight + DrawSummaryPanel.bottomMargin;

  /// 顶部栏图标（AppIconButton 默认 38）与间距，用于给标题计算左右配重
  static const double _iconSize = 38;
  static const double _iconGap = 8;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Map<String, AnimationController> _controllers = {};
  final Map<String, String> _drawn = {};
  final List<DrawnCard> _round = [];
  final math.Random _random = math.Random();

  late Deck _deck;

  @override
  void initState() {
    super.initState();
    _deck = CardLibrary.instance.decks.first;
    _createControllers();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _createControllers() {
    for (final c in _deck.categories) {
      _controllers[c.id] = AnimationController(vsync: this, duration: _flipDuration);
    }
  }

  // ---------------------------------------------------------------- 卡组切换

  void _switchDeck(Deck deck) {
    _scaffoldKey.currentState?.closeDrawer();
    if (deck.def.id == _deck.def.id) return;
    setState(() {
      for (final c in _controllers.values) {
        c.dispose();
      }
      _controllers.clear();
      _drawn.clear();
      _deck = deck;
      _createControllers();
    });
  }

  // ---------------------------------------------------------------- 抽卡动作

  CardCategory? _categoryOf(String id) {
    for (final c in _deck.categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  DrawnCard _toDrawnCard(CardCategory cat, String asset) => DrawnCard(
        deckId: _deck.def.id,
        deckNameZh: _deck.def.nameZh,
        deckNameEn: _deck.def.nameEn,
        categoryId: cat.id,
        categoryLabelZh: cat.labelZh,
        categoryLabelEn: cat.labelEn,
        asset: asset,
      );

  void _tapCategory(String categoryId) {
    final cat = _categoryOf(categoryId);
    final controller = _controllers[categoryId];
    if (cat == null || controller == null) return;

    // 统一抽卡：单击牌面即直接抽出下一张（不再有「收起」逻辑）
    final asset = cat.cards[_random.nextInt(cat.cards.length)];
    setState(() => _drawn[categoryId] = asset);
    controller.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      setState(() => _round.add(_toDrawnCard(cat, asset)));
    });
  }

  // ------------------------------------------------------------------ 导航类

  Future<void> _finishRound() async {
    if (_round.isEmpty) return;
    final cards = List<DrawnCard>.from(_round);
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RoundResultScreen(cards: cards)),
    );
    if (!mounted) return;
    // 本轮已结束，回到混卡界面即开始新一轮
    setState(() {
      _round.clear();
      _drawn.clear();
      for (final c in _controllers.values) {
        c.value = 0;
      }
    });
  }

  void _goHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // ------------------------------------------------------------------- 视图

  @override
  Widget build(BuildContext context) {
    final deck = _deck;

    return Scaffold(
      key: _scaffoldKey,
      drawer: DeckDrawer(currentDeckId: deck.def.id, onSelect: _switchDeck),
      drawerEnableOpenDragGesture: false,
      body: ParchmentBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              _buildDeckBar(),
              Expanded(
                child: CardStage(
                  categories: deck.categories,
                  controllers: _controllers,
                  drawn: _drawn,
                  onTapCategory: _tapCategory,
                  hintTopPadding: 24,
                  hint: _drawn.isEmpty
                      ? '单击牌堆进行抽卡\n可切换上方卡组抽取任意牌组'
                      : '单击牌面可直接抽出下一张\n结束本轮抽卡后，点击下方按键查看结果汇总',
                ),
              ),
              _buildBottomArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      child: Row(
        children: [
          // 左侧留出与右侧图标组等宽的占位，标题因此绝对居中
          SizedBox(
            width: _iconSize * 2 + _iconGap,
            child: Align(
              alignment: Alignment.centerLeft,
              child: AppIconButton(
                icon: Icons.menu_rounded,
                tooltip: '切换卡组',
                onTap: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  kMixedNameZh,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppText.title,
                ),
                const SizedBox(height: 2),
                Text(
                  kMixedNameEn,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppText.eyebrow.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          AppIconButton(
            icon: Icons.arrow_back_rounded,
            tooltip: '返回',
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: _iconGap),
          AppIconButton(
            icon: Icons.home_outlined,
            tooltip: '回到主页面',
            onTap: _goHome,
          ),
        ],
      ),
    );
  }

  Widget _buildDeckBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ListenableBuilder(
        listenable: AccountStore.instance,
        builder: (context, _) {
          final account = AccountStore.instance;
          final decks = account.sortUnlockedFirst(
            CardLibrary.instance.decks,
            (d) => d.def.id,
          );

          return SizedBox(
            height: 58,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: decks.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final deck = decks[index];
                final locked = !account.isUnlocked(deck.def.id);
                return _DeckChip(
                  nameZh: deck.def.nameZh,
                  nameEn: deck.def.nameEn,
                  on: deck.def.id == _deck.def.id,
                  locked: locked,
                  onTap: locked ? null : () => _switchDeck(deck),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomArea() {
    final enabled = _round.isNotEmpty;

    return SizedBox(
      height: _bottomAreaHeight,
      child: Column(
        children: [
          SizedBox(
            height: _controlsHeight,
            child: Center(
              child: Opacity(
                opacity: enabled ? 1 : 0.4,
                child: IgnorePointer(
                  ignoring: !enabled,
                  child: AppPillButton(
                    label: '结束本轮抽卡',
                    icon: Icons.flag_outlined,
                    onTap: _finishRound,
                  ),
                ),
              ),
            ),
          ),
          // 汇总框：牌抽出来后出现在结束键下方，牌多了可在框内上下滑动
          Expanded(
            child: _round.isEmpty
                ? const SizedBox.shrink()
                : DrawSummaryPanel(cards: _round, showDeck: true),
          ),
          const SizedBox(height: DrawSummaryPanel.bottomMargin),
        ],
      ),
    );
  }
}

class _DeckChip extends StatelessWidget {
  const _DeckChip({
    required this.nameZh,
    required this.nameEn,
    required this.on,
    this.locked = false,
    this.onTap,
  });

  final String nameZh;
  final String nameEn;
  final bool on;
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.pill);
    final background = on
        ? AppColors.wood
        : (locked ? AppColors.faint : AppColors.surface);
    final side = on ? AppColors.wood : AppColors.hairline;
    final nameColor = on
        ? AppColors.canvasTop
        : (locked ? AppColors.muted : AppColors.ink);
    final enColor = on ? AppColors.canvasTop : AppColors.muted;

    return Center(
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: side),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(borderRadius: radius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      nameZh,
                      style: AppText.title.copyWith(
                        fontSize: 14,
                        color: nameColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      nameEn,
                      style: AppText.eyebrow.copyWith(
                        fontSize: 9,
                        letterSpacing: 1.6,
                        color: enColor,
                      ),
                    ),
                  ],
                ),
                if (locked)
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Icon(
                      Icons.lock_rounded,
                      size: 12,
                      color: AppColors.muted,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
