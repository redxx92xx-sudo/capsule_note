import 'package:flutter/material.dart';

class AppTheme {
  // 色彩常數定義 (墨水屏 / E-ink 調色盤)
  static const Color paperWhite = Color(0xFFF9F9F8);
  static const Color paperWhiteCard = Color(0xFFFFFFFF);
  static const Color inkBlack = Color(0xFF1E1E1E);
  static const Color inkSecondary = Color(0xFF757575);
  static const Color inkBlue = Color(0xFF2C3E50);
  static const Color inkBorderLight = Color(0xFFE2E2DF);
  static const Color inkHighlightLight = Color(0xFFEDEDEA);

  // 夜間模式色彩
  static const Color nightDark = Color(0xFF121212);
  static const Color nightCard = Color(0xFF1E1E1E);
  static const Color nightText = Color(0xFFE8E8E8);
  static const Color nightSecondary = Color(0xFFA0A0A0);
  static const Color nightBorder = Color(0xFF2C2C2C);
  static const Color nightHighlight = Color(0xFF252525);

  // 淺色模式主題
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: paperWhite,
      colorScheme: const ColorScheme.light(
        primary: inkBlue,
        onPrimary: Colors.white,
        secondary: inkBlack,
        onSecondary: Colors.white,
        surface: paperWhiteCard,
        onSurface: inkBlack,
        outline: inkBorderLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: paperWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: inkBlack),
        titleTextStyle: TextStyle(
          color: inkBlack,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: paperWhiteCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: inkBorderLight, width: 1.2),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),
      dividerTheme: const DividerThemeData(
        color: inkBorderLight,
        thickness: 1,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: inkBlack,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
        ),
        headlineMedium: TextStyle(
          color: inkBlack,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleMedium: TextStyle(
          color: inkBlack,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: inkBlack,
          fontSize: 15,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: inkSecondary,
          fontSize: 13,
          height: 1.4,
        ),
        labelSmall: TextStyle(
          color: inkSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // 深色模式主題
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: nightDark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF6B8CAE),
        onPrimary: nightDark,
        secondary: nightText,
        onSecondary: nightDark,
        surface: nightCard,
        onSurface: nightText,
        outline: nightBorder,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: nightDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: nightText),
        titleTextStyle: TextStyle(
          color: nightText,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: nightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: nightBorder, width: 1.2),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),
      dividerTheme: const DividerThemeData(
        color: nightBorder,
        thickness: 1,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: nightText,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
        ),
        headlineMedium: TextStyle(
          color: nightText,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleMedium: TextStyle(
          color: nightText,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: nightText,
          fontSize: 15,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: nightSecondary,
          fontSize: 13,
          height: 1.4,
        ),
        labelSmall: TextStyle(
          color: nightSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
