import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 圆形图标按钮：奶油底 + 细描边（参考 Claude 的 icon-circular）
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.size = 38,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: AppColors.surface,
      shape: CircleBorder(side: const BorderSide(color: AppColors.hairline)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: size * 0.48, color: AppColors.inkSoft),
        ),
      ),
    );

    final hint = tooltip;
    if (hint == null) return button;
    return Tooltip(message: hint, child: button);
  }
}

/// 胶囊按钮：木色实心为主操作，奶油描边为次操作
class AppPillButton extends StatelessWidget {
  const AppPillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.filled = true,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.pill);
    final foreground = filled ? AppColors.canvasTop : AppColors.ink;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: filled ? AppShadows.flat : null,
      ),
      child: Material(
        color: filled ? AppColors.wood : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: filled ? AppColors.wood : AppColors.hairline),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(borderRadius: radius),
          onTap: onTap,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 被拉伸成全宽时（如登录页）文字也居中；其余场景收缩成胶囊
              final expand = constraints.hasTightWidth;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 13),
                child: Row(
                  mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18, color: foreground),
                      const SizedBox(width: 8),
                    ],
                    Text(label, style: AppText.button.copyWith(color: foreground)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// 分类开关（字卡 / 图卡 / 人物卡 …）
class AppToggleChip extends StatelessWidget {
  const AppToggleChip({
    super.key,
    required this.label,
    required this.on,
    required this.onTap,
  });

  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.pill);
    final style = AppText.eyebrow.copyWith(
      fontSize: 12,
      letterSpacing: 1.4,
      color: on ? AppColors.canvasTop : AppColors.muted,
    );

    return Material(
      color: on ? AppColors.wood : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: on ? AppColors.wood : AppColors.hairline),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(borderRadius: radius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                on ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 14,
                color: on ? AppColors.canvasTop : AppColors.faint,
              ),
              const SizedBox(width: 8),
              Text(label, style: style),
            ],
          ),
        ),
      ),
    );
  }
}
