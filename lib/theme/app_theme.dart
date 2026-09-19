import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';
import '../models/todo_item.dart';

/// Central design tokens. Screens must use [AppColors.of] / Theme, not raw hex.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.textCompleted,
    required this.divider,
    required this.accent,
    required this.accentSoft,
    required this.overdue,
    required this.onAccent,
    required this.completed,
    required this.badgeBackground,
    required this.badgeForeground,
    required this.segmentTrack,
    required this.segmentSelected,
  });

  /// Page / scaffold background.
  final Color background;

  /// List rows, settings groups, elevated panels.
  final Color surface;

  final Color textPrimary;
  final Color textSecondary;
  final Color textCompleted;
  final Color divider;

  /// Red accent — alarm icon, selected nav/date, primary actions, errors.
  final Color accent;

  /// Soft red surface (badge / alarm-mode soft mark).
  final Color accentSoft;
  final Color overdue;
  final Color onAccent;

  /// Completed checkbox fill (grey, never green).
  final Color completed;

  final Color badgeBackground;
  final Color badgeForeground;

  /// Segmented control track / selected pill.
  final Color segmentTrack;
  final Color segmentSelected;

  static const light = AppColors(
    background: Color(0xFFF8F9FA),
    surface: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF18181B),
    textSecondary: Color(0xFF71717A),
    textCompleted: Color(0xFFA1A1AA),
    divider: Color(0xFFE4E4E7),
    accent: Color(0xFFC62828),
    accentSoft: Color(0xFFFEF2F2),
    overdue: Color(0xFFC62828),
    onAccent: Color(0xFFFFFFFF),
    completed: Color(0xFFA1A1AA),
    badgeBackground: Color(0xFFFEF2F2),
    badgeForeground: Color(0xFFC62828),
    segmentTrack: Color(0xFFE4E4E7),
    segmentSelected: Color(0xFFFFFFFF),
  );

  static const dark = AppColors(
    background: Color(0xFF121212),
    surface: Color(0xFF1E1E1E),
    textPrimary: Color(0xFFF5F5F5),
    textSecondary: Color(0xFFA6A6A6),
    textCompleted: Color(0xFF71717A),
    divider: Color(0xFF303030),
    accent: Color(0xFFFF5A55),
    accentSoft: Color(0xFF351515),
    overdue: Color(0xFFFF5A55),
    onAccent: Color(0xFFFFFFFF),
    completed: Color(0xFF71717A),
    badgeBackground: Color(0xFF351515),
    badgeForeground: Color(0xFFFF5A55),
    segmentTrack: Color(0xFF2A2A2A),
    segmentSelected: Color(0xFF1E1E1E),
  );

  static AppColors of(BuildContext context) {
    return Theme.of(context).extension<AppColors>() ??
        (Theme.of(context).brightness == Brightness.dark ? dark : light);
  }

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? textPrimary,
    Color? textSecondary,
    Color? textCompleted,
    Color? divider,
    Color? accent,
    Color? accentSoft,
    Color? overdue,
    Color? onAccent,
    Color? completed,
    Color? badgeBackground,
    Color? badgeForeground,
    Color? segmentTrack,
    Color? segmentSelected,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textCompleted: textCompleted ?? this.textCompleted,
      divider: divider ?? this.divider,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      overdue: overdue ?? this.overdue,
      onAccent: onAccent ?? this.onAccent,
      completed: completed ?? this.completed,
      badgeBackground: badgeBackground ?? this.badgeBackground,
      badgeForeground: badgeForeground ?? this.badgeForeground,
      segmentTrack: segmentTrack ?? this.segmentTrack,
      segmentSelected: segmentSelected ?? this.segmentSelected,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textCompleted: Color.lerp(textCompleted, other.textCompleted, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      overdue: Color.lerp(overdue, other.overdue, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      completed: Color.lerp(completed, other.completed, t)!,
      badgeBackground: Color.lerp(badgeBackground, other.badgeBackground, t)!,
      badgeForeground: Color.lerp(badgeForeground, other.badgeForeground, t)!,
      segmentTrack: Color.lerp(segmentTrack, other.segmentTrack, t)!,
      segmentSelected: Color.lerp(segmentSelected, other.segmentSelected, t)!,
    );
  }
}

enum AppThemePreference {
  system,
  light,
  dark;

  String get storageValue => name;

  String get displayName {
    switch (this) {
      case AppThemePreference.system:
        return '跟隨系統';
      case AppThemePreference.light:
        return '淺色';
      case AppThemePreference.dark:
        return '深色';
    }
  }

  String localizedName(AppStrings s) {
    switch (this) {
      case AppThemePreference.system:
        return s.themeSystem;
      case AppThemePreference.light:
        return s.themeLight;
      case AppThemePreference.dark:
        return s.themeDark;
    }
  }

  ThemeMode get themeMode {
    switch (this) {
      case AppThemePreference.system:
        return ThemeMode.system;
      case AppThemePreference.light:
        return ThemeMode.light;
      case AppThemePreference.dark:
        return ThemeMode.dark;
    }
  }

  static AppThemePreference fromStorage(String? raw) {
    switch (raw) {
      case 'light':
        return AppThemePreference.light;
      case 'dark':
        return AppThemePreference.dark;
      case 'system':
        return AppThemePreference.system;
      default:
        return AppThemePreference.system;
    }
  }
}

class AppTheme {
  /// Priority markers stay monochrome + red urgent (no green/blue/purple).
  static Color getPriorityColor(TodoPriority priority, AppColors colors) {
    switch (priority) {
      case TodoPriority.urgent:
        return colors.accent;
      case TodoPriority.high:
        return colors.textPrimary;
      case TodoPriority.normal:
        return colors.textSecondary;
      case TodoPriority.low:
        return colors.divider;
    }
  }

  static const String fontFamily = 'Roboto';
  static const List<String> fontFamilyFallback = [
    'Noto Sans TC',
    'Noto Sans CJK TC',
    'sans-serif',
  ];

  static TextTheme _textTheme(AppColors colors) {
    TextStyle base({
      double size = 15,
      FontWeight weight = FontWeight.w400,
      Color? color,
      double height = 1.35,
    }) {
      return TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        fontSize: size,
        fontWeight: weight,
        color: color ?? colors.textPrimary,
        height: height,
      );
    }

    return TextTheme(
      displayLarge: base(size: 36, weight: FontWeight.w800),
      headlineMedium: base(size: 18, weight: FontWeight.w600),
      titleLarge: base(size: 18, weight: FontWeight.w600),
      titleMedium: base(size: 17, weight: FontWeight.w600),
      titleSmall: base(size: 16, weight: FontWeight.w600),
      bodyLarge: base(size: 16, weight: FontWeight.w400),
      bodyMedium: base(size: 15, weight: FontWeight.w400),
      bodySmall: base(
        size: 13,
        weight: FontWeight.w400,
        color: colors.textSecondary,
      ),
      labelLarge: base(size: 15, weight: FontWeight.w600),
      labelMedium: base(
        size: 13,
        weight: FontWeight.w400,
        color: colors.textSecondary,
      ),
      labelSmall: base(
        size: 12,
        weight: FontWeight.w400,
        color: colors.textSecondary,
      ),
    );
  }

  static ThemeData _build(AppColors colors, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: colors.accent,
      onPrimary: colors.onAccent,
      secondary: colors.textPrimary,
      onSecondary: colors.surface,
      error: colors.accent,
      onError: colors.onAccent,
      surface: colors.surface,
      onSurface: colors.textPrimary,
      onSurfaceVariant: colors.textSecondary,
      outline: colors.divider,
      outlineVariant: colors.divider,
    );

    final textTheme = _textTheme(colors);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      dividerColor: colors.divider,
      fontFamily: fontFamily,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      extensions: [colors],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle: brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadowColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        elevation: 0,
        height: 64,
        indicatorColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: fontFamily,
            fontFamilyFallback: fontFamilyFallback,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? colors.accent : colors.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: selected ? colors.accent : colors.textSecondary,
          );
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.accent,
        foregroundColor: colors.onAccent,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: const CircleBorder(),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colors.onAccent;
          return colors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colors.accent;
          return colors.divider;
        }),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colors.textSecondary,
        textColor: colors.textPrimary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.divider),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: colors.divider),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: colors.divider),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: colors.accent, width: 1.5),
        ),
        labelStyle: TextStyle(color: colors.textSecondary),
        hintStyle: TextStyle(color: colors.textSecondary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: colors.onAccent,
          elevation: 0,
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size.fromHeight(48),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.accent,
          textStyle: textTheme.labelLarge,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.textPrimary,
        contentTextStyle: TextStyle(color: colors.surface),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),
      iconTheme: IconThemeData(color: colors.textSecondary, size: 22),
      primaryIconTheme: IconThemeData(color: colors.textPrimary, size: 22),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: colors.accent),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colors.completed;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(colors.surface),
        side: BorderSide(color: colors.divider, width: 1.5),
      ),
    );
  }

  static ThemeData get lightTheme => _build(AppColors.light, Brightness.light);

  static ThemeData get darkTheme => _build(AppColors.dark, Brightness.dark);
}
