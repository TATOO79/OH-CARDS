import 'package:flutter/material.dart';

import '../data/account_store.dart';
import '../data/card_library.dart';
import '../theme/app_theme.dart';

/// 侧栏：只显示中英文名的卡组快捷入口
class DeckDrawer extends StatelessWidget {
  const DeckDrawer({
    super.key,
    required this.currentDeckId,
    required this.onSelect,
    this.subtitle = '切换卡组',
  });

  final String currentDeckId;
  final ValueChanged<Deck> onSelect;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AccountStore.instance,
      builder: (context, _) {
        final account = AccountStore.instance;
        final decks = account.sortUnlockedFirst(
          CardLibrary.instance.decks,
          (d) => d.def.id,
        );
        return Drawer(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DECKS',
                        style: AppText.eyebrow.copyWith(color: AppColors.wood, fontSize: 10),
                      ),
                      const SizedBox(height: 8),
                      Text(subtitle, style: AppText.displaySm),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: decks.length,
                    itemBuilder: (context, index) {
                      final deck = decks[index];
                      final locked = !account.isUnlocked(deck.def.id);
                      return DeckDrawerItem(
                        nameZh: deck.def.nameZh,
                        nameEn: deck.def.nameEn,
                        active: deck.def.id == currentDeckId,
                        locked: locked,
                        onTap: locked ? null : () => onSelect(deck),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class DeckDrawerItem extends StatelessWidget {
  const DeckDrawerItem({
    super.key,
    required this.nameZh,
    required this.nameEn,
    required this.active,
    required this.onTap,
    this.locked = false,
  });

  final String nameZh;
  final String nameEn;
  final bool active;
  final VoidCallback? onTap;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: active ? AppColors.canvasSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 30,
                  decoration: BoxDecoration(
                    color: active ? AppColors.wood : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nameZh,
                        style: AppText.title.copyWith(
                          color: locked ? AppColors.muted : AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        nameEn,
                        style: AppText.eyebrow.copyWith(
                          fontSize: 10,
                          color: locked ? AppColors.faint : AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (locked)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.lock_rounded, size: 16, color: AppColors.faint),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
