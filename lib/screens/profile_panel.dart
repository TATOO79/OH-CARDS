import 'package:flutter/material.dart';

import '../data/account_store.dart';
import '../data/card_library.dart';
import '../theme/app_theme.dart';
import '../widgets/card_image.dart';
import 'auth_screen.dart';

/// 个人主页右侧栏：账户头像与名称 + 各牌组解锁进度。
///
/// 宽度由调用方约束为屏幕的一半。
class ProfilePanel extends StatelessWidget {
  const ProfilePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final account = AccountStore.instance;

    return ListenableBuilder(
      listenable: account,
      builder: (context, _) {
        final entries = account.sortUnlockedFirst(
          CardLibrary.instance.homeEntries,
          (e) => e.id,
        );
        return SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AccountHeader(account: account),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  '解锁进度',
                  style: AppText.eyebrow.copyWith(color: AppColors.wood, fontSize: 10),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final unlocked = account.isUnlocked(entry.id);
                    return _UnlockTile(entry: entry, unlocked: unlocked);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AccountHeader extends StatelessWidget {
  const _AccountHeader({required this.account});

  final AccountStore account;

  @override
  Widget build(BuildContext context) {
    final loggedIn = account.isLoggedIn;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.canvasSoft,
                child: Icon(
                  loggedIn ? Icons.person_rounded : Icons.person_outline_rounded,
                  size: 28,
                  color: AppColors.wood,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.title.copyWith(fontSize: 17),
                    ),
                    if (loggedIn) ...[
                      const SizedBox(height: 3),
                      Text(
                        account.displayEmail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caption.copyWith(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (loggedIn) ...[
            FilledButton(
              onPressed: () => _showRedeemDialog(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.wood,
                foregroundColor: AppColors.canvasTop,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('输入兑换码'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () async {
                await account.signOut();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.ink,
                side: const BorderSide(color: AppColors.hairline),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                padding: const EdgeInsets.symmetric(vertical: 11),
              ),
              child: const Text('退出登录'),
            ),
          ] else
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AuthScreen()),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.wood,
                foregroundColor: AppColors.canvasTop,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('登录 / 注册'),
            ),
        ],
      ),
    );
  }
}

/// 单个卡组的解锁进度条目：解锁后与「点击抵达」卡片一致，未解锁置灰并带锁。
class _UnlockTile extends StatelessWidget {
  const _UnlockTile({required this.entry, required this.unlocked});

  final HomeEntry entry;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: unlocked ? AppColors.surface : AppColors.canvasSoft,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: unlocked ? AppColors.hairline : Colors.transparent),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            _thumb(context),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.nameZh,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.title.copyWith(
                      fontSize: 15,
                      color: unlocked ? AppColors.ink : AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    entry.nameEn,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.eyebrow.copyWith(
                      fontSize: 9,
                      color: unlocked ? AppColors.muted : AppColors.faint,
                    ),
                  ),
                ],
              ),
            ),
            if (unlocked)
              const Icon(Icons.check_circle_rounded, size: 20, color: AppColors.wood)
            else
              const Icon(Icons.lock_rounded, size: 18, color: AppColors.faint),
          ],
        ),
      ),
    );
  }

  Widget _thumb(BuildContext context) {
    if (entry.isMixed) {
      return _mixedThumb();
    }
    final back = entry.deck!.thumbnailCategory.backAsset;
    return SizedBox(
      width: 34,
      height: 48,
      child: CardThumb(
        asset: back,
        radius: AppRadius.sm,
        cacheWidth: 120,
        grayscale: !unlocked,
      ),
    );
  }

  Widget _mixedThumb() {
    return Container(
      width: 34,
      height: 48,
      decoration: BoxDecoration(
        color: unlocked ? AppColors.wood : AppColors.faint,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(
        Icons.auto_awesome_mosaic_outlined,
        size: 20,
        color: AppColors.canvasTop,
      ),
    );
  }
}

void _showRedeemDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (_) => const _RedeemDialog(),
  );
}

/// 兑换码输入对话框。
class _RedeemDialog extends StatefulWidget {
  const _RedeemDialog();

  @override
  State<_RedeemDialog> createState() => _RedeemDialogState();
}

class _RedeemDialogState extends State<_RedeemDialog> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _controller.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AccountStore.instance.redeemCode(code);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('兑换成功，卡组已解锁')),
      );
    } on RedeemException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _busy = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '兑换失败，请稍后重试';
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('输入兑换码'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        onSubmitted: (_) {
          _submit();
        },
        decoration: InputDecoration(
          hintText: '请输入兑换码',
          errorText: _error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: _busy ? null : _submit,
          child: Text(_busy ? '兑换中…' : '兑换'),
        ),
      ],
    );
  }
}
