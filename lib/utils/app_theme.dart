import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// HomeStash 品牌色调系统
///
/// 基于温暖的木色 + 清新的茶树绿，传递家庭收纳的温馨感。
class AppColors {
  AppColors._();

  // ── 品牌主色 ──
  /// 主品牌色：茶树绿 (tea green)
  static const Color primary = Color(0xFF2E7D32);

  /// 强调色：暖橙色 (warm amber)
  static const Color accent = Color(0xFFFF8F00);

  // ── 品牌色阶 ──
  static const Color green50 = Color(0xFFE8F5E9);
  static const Color green100 = Color(0xFFC8E6C9);
  static const Color green200 = Color(0xFFA5D6A7);
  static const Color green400 = Color(0xFF66BB6A);
  static const Color green600 = Color(0xFF43A047);
  static const Color green800 = Color(0xFF2E7D32);
  static const Color green900 = Color(0xFF1B5E20);

  static const Color amber200 = Color(0xFFFFE082);
  static const Color amber500 = Color(0xFFFFC107);
  static const Color amber700 = Color(0xFFFFA000);
  static const Color amber800 = Color(0xFFFF8F00);

  // ── 中性色 ──
  static const Color warmGray50 = Color(0xFFFAF8F5);
  static const Color warmGray100 = Color(0xFFF5F1EB);
  static const Color warmGray200 = Color(0xFFEBE3D8);
  static const Color warmGray400 = Color(0xFFC4B8A8);
  static const Color warmGray600 = Color(0xFF8B7D6B);
  static const Color warmGray800 = Color(0xFF4E4337);

  // ── 深色模式表面色 ──
  static const Color darkSurface = Color(0xFF1C1B1A);
  static const Color darkSurfaceVariant = Color(0xFF2C2A28);
  static const Color darkBackground = Color(0xFF121110);
}

/// 构建亮色主题
ThemeData buildLightTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    secondary: AppColors.accent,
    surface: AppColors.warmGray50,
    surfaceContainerHighest: AppColors.warmGray100,
    outline: AppColors.warmGray600,
  );

  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.warmGray50,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.warmGray50,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      shadowColor: AppColors.warmGray200.withAlpha(150),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      color: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 2,
      indicatorColor: colorScheme.primaryContainer,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}

/// 构建暗色主题
ThemeData buildDarkTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.green400,
    brightness: Brightness.dark,
    surface: AppColors.darkSurface,
  ).copyWith(
    primary: AppColors.green400,
    onPrimary: Colors.black,
    secondary: AppColors.amber500,
    surface: AppColors.darkSurface,
    surfaceContainerHighest: AppColors.darkSurfaceVariant,
    outline: AppColors.warmGray400,
    onSurface: Colors.white.withAlpha(230),
  );

  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.darkBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkBackground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      shadowColor: Colors.black54,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      color: AppColors.darkSurfaceVariant,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      filled: true,
      fillColor: AppColors.darkSurfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 2,
      indicatorColor: colorScheme.primaryContainer,
      backgroundColor: AppColors.darkSurface,
      surfaceTintColor: Colors.transparent,
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.green600,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
