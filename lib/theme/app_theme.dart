import 'package:flutter/material.dart';

/// 木系羊皮纸设计语言。
///
/// 结构参考 Notion（暖纸底 + 衬线标题 + 柔和表面 + 8px 间距体系），
/// 配色参考 Claude（奶油画布 + 陶土点缀 + 极少的硬阴影）。
class AppColors {
  const AppColors._();

  /// 墨：标题与正文
  static const Color ink = Color(0xFF2E241C);
  static const Color inkSoft = Color(0xFF4A3A2C);
  static const Color muted = Color(0xFF8A7A66);
  static const Color faint = Color(0xFFB3A48D);

  /// 木：主色
  static const Color wood = Color(0xFF7A5636);
  static const Color woodDeep = Color(0xFF5A3D25);

  /// 点缀
  static const Color clay = Color(0xFFB5714E);
  static const Color moss = Color(0xFF6E7F5C);

  /// 羊皮纸表面
  static const Color canvas = Color(0xFFF6EFE2);
  static const Color canvasTop = Color(0xFFFCF8F0);
  static const Color canvasBottom = Color(0xFFF0E5D0);
  static const Color canvasSoft = Color(0xFFEFE6D5);
  static const Color surface = Color(0xFFFDFAF4);
  static const Color hairline = Color(0xFFE2D5BE);
}

class AppShadows {
  const AppShadows._();

  /// 卡片默认：多层近乎透明的叠加，避免硬投影
  static const List<BoxShadow> flat = [
    BoxShadow(color: Color(0x142E241C), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x122E241C), blurRadius: 8, offset: Offset(0, 3)),
    BoxShadow(color: Color(0x0D2E241C), blurRadius: 20, offset: Offset(0, 10)),
  ];

  /// 抬起：抽出的卡牌
  static const List<BoxShadow> lifted = [
    BoxShadow(color: Color(0x1F2E241C), blurRadius: 3, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x1F2E241C), blurRadius: 14, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x142E241C), blurRadius: 36, offset: Offset(0, 20)),
  ];
}

class AppRadius {
  const AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 22;
  static const double pill = 999;
}

/// 卡牌宽高比（源图为 733 × 1027）
const double kCardAspect = 733 / 1027;

class AppText {
  const AppText._();

  /// 标题使用衬线体，营造沉思、纸感的语气；正文用系统无衬线保证中文清晰。
  static const String serif = 'serif';

  static const TextStyle display = TextStyle(
    fontFamily: serif,
    fontSize: 30,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: 5,
    color: AppColors.ink,
  );

  static const TextStyle displaySm = TextStyle(
    fontFamily: serif,
    fontSize: 21,
    height: 1.3,
    fontWeight: FontWeight.w700,
    letterSpacing: 2.5,
    color: AppColors.ink,
  );

  static const TextStyle title = TextStyle(
    fontSize: 16,
    height: 1.35,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    color: AppColors.ink,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    height: 1.6,
    fontWeight: FontWeight.w400,
    color: AppColors.inkSoft,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 13,
    height: 1.5,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    color: AppColors.muted,
  );

  /// 全大写英文名 / 眉标
  static const TextStyle eyebrow = TextStyle(
    fontSize: 11,
    height: 1.45,
    fontWeight: FontWeight.w600,
    letterSpacing: 2.6,
    color: AppColors.muted,
  );

  static const TextStyle button = TextStyle(
    fontSize: 15,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.6,
  );
}

class AppTheme {
  const AppTheme._();

  /// 羊皮纸底：极缓的垂直渐变，避免死板的纯色
  static const LinearGradient parchment = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.canvasTop, AppColors.canvas, AppColors.canvasBottom],
    stops: [0.0, 0.55, 1.0],
  );

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.wood,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.wood,
      onPrimary: AppColors.canvasTop,
      secondary: AppColors.clay,
      onSecondary: AppColors.canvasTop,
      surface: AppColors.canvas,
      onSurface: AppColors.ink,
      surfaceContainerHighest: AppColors.canvasSoft,
      outline: AppColors.hairline,
      outlineVariant: AppColors.hairline,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.canvas,
      dividerColor: AppColors.hairline,
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.inkSoft,
        displayColor: AppColors.ink,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.ink,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.canvasTop,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        width: 296,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: TextStyle(color: AppColors.canvasTop, fontSize: 14),
        behavior: SnackBarBehavior.floating,
      ),
      iconTheme: const IconThemeData(color: AppColors.inkSoft, size: 22),
    );
  }
}
