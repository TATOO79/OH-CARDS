import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/card_library.dart';
import '../data/draw_history.dart';
import '../theme/app_theme.dart';
import '../widgets/app_controls.dart';
import '../widgets/card_stage.dart';
import '../widgets/count_selector.dart';
import '../widgets/deck_drawer.dart';
import '../widgets/draw_summary.dart';
import '../widgets/parchment_background.dart';
import 'round_result_screen.dart';

/// 抽卡界面。
///
/// 单叠卡组：点牌堆 -> 翻牌 -> 显示牌面，可继续点牌面抽下一张。
/// 双叠卡组：两叠牌背各自可点，两叠都有牌面后出现退出按钮。
/// 本轮的牌面会按顺序汇总在下方框内。
class DrawScreen extends StatefulWidget {
  const DrawScreen({super.key, required this.deck, this.restore});

  final Deck deck;

  /// 由「还原」进入时直接展示的结果
  final DrawRecord? restore;

  @override
  State<DrawScreen> createState() => _DrawScreenState();
}

class _DrawScreenState extends State<DrawScreen> with TickerProviderStateMixin {
  static const Duration _flipDuration = Duration(milliseconds: 640);
  static const Duration _batchFlipDuration = Duration(milliseconds: 220);

  /// 底部控制区（数量选择 / 一键抽出 / 退出）的高度
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
  final Map<String, int> _counts = {};
  final List<DrawnCard> _round = [];
  final math.Random _random = math.Random();

  Set<String> _enabled = {};
  bool _batchRunning = false;

  Deck get _deck => widget.deck;

  List<CardCategory> get _enabledCategories =>
      _deck.categories.where((c) => _enabled.contains(c.id)).toList(growable: false);

  bool get _allRevealed {
    if (_batchRunning) return false;
    final cats = _enabledCategories;
    if (cats.isEmpty) return false;
    for (final c in cats) {
      if (!_drawn.containsKey(c.id)) return false;
      if (!_controllers[c.id]!.isCompleted) return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();

    for (final c in _deck.categories) {
      _controllers[c.id] = AnimationController(vsync: this, duration: _flipDuration);
      _counts[c.id] = 1;
    }

    if (_deck.hasChoices) {
      _enabled = _deck.categories.where((c) => c.defaultOn).map((c) => c.id).toSet();
      if (_enabled.isEmpty) _enabled = {_deck.categories.first.id};
    } else {
      _enabled = _deck.categories.map((c) => c.id).toSet();
    }

    final restore = widget.restore;
    if (restore != null) _applyRestore(restore);
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
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

  /// 逐次点击牌堆/牌面：每次翻出一张，并计入本轮汇总
  void _onTapCategory(String categoryId) {
    if (_batchRunning) return;
    final cat = _categoryOf(categoryId);
    final controller = _controllers[categoryId];
    if (cat == null || controller == null) return;

    final asset = cat.cards[_random.nextInt(cat.cards.length)];
    controller.duration = _flipDuration;
    setState(() => _drawn[categoryId] = asset);

    controller.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      setState(() {
        _round.add(_toDrawnCard(cat, asset));
        _rememberResult();
      });
    });
  }

  /// 一键抽出：按设定的张数，为每个尚未翻开的分类连续抽牌
  Future<void> _drawAll() async {
    if (_batchRunning) return;
    final targets = _enabledCategories
        .where((c) => !_drawn.containsKey(c.id))
        .toList(growable: false);
    if (targets.isEmpty) return;

    setState(() => _batchRunning = true);
    await Future.wait(targets.map(_runBatchForCategory));
    if (!mounted) return;
    setState(() {
      _batchRunning = false;
      _rememberResult();
    });
  }

  Future<void> _runBatchForCategory(CardCategory cat) async {
    final controller = _controllers[cat.id];
    if (controller == null) return;

    final count = (_counts[cat.id] ?? 1).clamp(1, 9);
    final pool = List<String>.from(cat.cards)..shuffle(_random);
    final picks = pool.take(count).toList(growable: false);

    controller.duration = _batchFlipDuration;
    for (final asset in picks) {
      if (!mounted) return;
      setState(() => _drawn[cat.id] = asset);
      try {
        await controller.forward(from: 0).orCancel;
      } on TickerCanceled {
        return;
      }
      if (!mounted) return;
      setState(() => _round.add(_toDrawnCard(cat, asset)));
    }
  }

  /// 本轮全部翻开后记下结果，供「还原」使用
  void _rememberResult() {
    if (_round.isEmpty || !_allRevealed) return;
    DrawHistory.instance.last = DrawRecord(
      deckId: _deck.def.id,
      cards: List<DrawnCard>.from(_round),
    );
  }

  void _resetRound() {
    _drawn.clear();
    _round.clear();
    for (final c in _controllers.values) {
      c.value = 0;
    }
  }

  /// 结束本轮：进入「本轮结果」，返回后回到牌堆开始新一轮
  Future<void> _exitResults() async {
    // 一键抽出进行中不打断
    if (_batchRunning || _round.isEmpty) return;
    final cards = List<DrawnCard>.from(_round);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoundResultScreen(
          cards: cards,
          eyebrow: _deck.def.nameEn,
          backLabel: '返回抽卡界面',
        ),
      ),
    );
    if (!mounted) return;
    setState(_resetRound);
  }

  void _toggleCategory(String id, bool on) {
    if (_batchRunning) return;
    setState(() {
      if (on) {
        _enabled = {..._enabled, id};
      } else {
        if (_enabled.length <= 1) return;
        _enabled = _enabled.where((e) => e != id).toSet();
      }
      _resetRound();
    });
  }

  void _applyRestore(DrawRecord record) {
    _round
      ..clear()
      ..addAll(record.cards);

    final ids = <String>{};
    for (final card in record.cards) {
      for (final cat in _deck.categories) {
        if (cat.id != card.categoryId) continue;
        final controller = _controllers[cat.id];
        if (controller == null) continue;
        ids.add(cat.id);
        _drawn[cat.id] = card.asset;
        controller.value = 1;
        break;
      }
    }
    if (ids.isNotEmpty) _enabled = ids;
  }

  // ------------------------------------------------------------------ 导航类

  void _onRestore() {
    final last = DrawHistory.instance.last;
    if (last == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('还没有可以还原的抽卡结果')),
      );
      return;
    }

    if (last.deckId == _deck.def.id) {
      setState(() {
        _resetRound();
        _applyRestore(last);
      });
      return;
    }

    final target = CardLibrary.instance.decks.firstWhere((d) => d.def.id == last.deckId);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => DrawScreen(deck: target, restore: last)),
    );
  }

  void _goHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _openDeck(Deck deck) {
    _scaffoldKey.currentState?.closeDrawer();
    if (deck.def.id == _deck.def.id) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => DrawScreen(deck: deck)),
    );
  }

  // ------------------------------------------------------------------- 视图

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: DeckDrawer(currentDeckId: _deck.def.id, onSelect: _openDeck),
      drawerEnableOpenDragGesture: false,
      body: ParchmentBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              if (_deck.hasChoices) _buildCategoryBar(),
              Expanded(
                child: CardStage(
                  categories: _enabledCategories,
                  controllers: _controllers,
                  drawn: _drawn,
                  onTapCategory: _onTapCategory,
                  hint: _drawn.isNotEmpty
                      ? '单击牌面可直接抽出下一张\n结束本轮抽卡后，点击退出按键查看结果汇总'
                      : '单击牌堆进行抽卡\n也可在下方设置次数一次性抽出',
                ),
              ),
              _buildBottomArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomArea() {
    return SizedBox(
      height: _bottomAreaHeight,
      child: Column(
        children: [
          SizedBox(
            height: _controlsHeight,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                // 只要单击翻开过牌，就收起数量与一键抽出，只留退出键
                child: _drawn.isNotEmpty ? _buildExitButton() : _buildDrawControls(),
              ),
            ),
          ),
          // 汇总框：牌抽出来后出现在退出键下方，牌多了可在框内上下滑动
          Expanded(
            child: _round.isEmpty
                ? const SizedBox.shrink()
                : DrawSummaryPanel(cards: _round),
          ),
          const SizedBox(height: DrawSummaryPanel.bottomMargin),
        ],
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
                  _deck.def.nameZh,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppText.title,
                ),
                const SizedBox(height: 2),
                Text(
                  _deck.def.nameEn,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppText.eyebrow.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          AppIconButton(
            icon: Icons.restore_rounded,
            tooltip: '还原上次结果',
            onTap: _onRestore,
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

  Widget _buildCategoryBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 8,
        children: [
          for (final c in _deck.categories)
            AppToggleChip(
              label: '${c.labelZh} ${c.labelEn}',
              on: _enabled.contains(c.id),
              onTap: () => _toggleCategory(c.id, !_enabled.contains(c.id)),
            ),
        ],
      ),
    );
  }

  Widget _buildExitButton() {
    return AppPillButton(
      key: const ValueKey('exit'),
      label: '退出',
      onTap: _exitResults,
    );
  }

  Widget _buildDrawControls() {
    final cats = _enabledCategories;

    return Wrap(
      key: const ValueKey('controls'),
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in cats)
          CountSelector(
            label: c.labelZh,
            value: _counts[c.id] ?? 1,
            onChanged: (v) => setState(() => _counts[c.id] = v),
          ),
        AppPillButton(
          label: '一键抽出',
          icon: Icons.auto_awesome_outlined,
          onTap: _drawAll,
        ),
      ],
    );
  }
}
