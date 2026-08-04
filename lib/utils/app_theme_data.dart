import 'package:flutter/material.dart';

import '../models/app_theme.dart';

/// Extra named theme colors beyond what [ColorScheme] has a slot for —
/// currently just the streak flame color. Read via
/// `Theme.of(context).extension<AppColorsExtension>()`.
@immutable
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color streakColor;

  const AppColorsExtension({required this.streakColor});

  @override
  AppColorsExtension copyWith({Color? streakColor}) {
    return AppColorsExtension(streakColor: streakColor ?? this.streakColor);
  }

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      streakColor: Color.lerp(streakColor, other.streakColor, t) ?? streakColor,
    );
  }
}

/// Converts a persisted [AppTheme] into a full [ThemeData], so every
/// screen reading `Theme.of(context)` picks up the user's chosen theme
/// automatically instead of hardcoded colors.
ThemeData buildThemeData(AppTheme appTheme) {
  final background = Color(appTheme.background);
  final card = Color(appTheme.card);
  final primary = Color(appTheme.primary);
  final accent = Color(appTheme.accent);
  final textPrimary = Color(appTheme.textPrimary);
  final textSecondary = Color(appTheme.textSecondary);
  final streak = Color(appTheme.streakColor);
  final brightness = ThemeData.estimateBrightnessForColor(background);
  final radius = BorderRadius.circular(appTheme.borderRadius);

  final colorScheme = ColorScheme.fromSeed(
    seedColor: primary,
    brightness: brightness,
  ).copyWith(
    primary: primary,
    onPrimary: brightness == Brightness.dark ? Colors.black : Colors.white,
    secondary: accent,
    surface: card,
    onSurface: textPrimary,
    onSurfaceVariant: textSecondary,
    surfaceTint: primary,
  );

  final base = ThemeData(brightness: brightness, useMaterial3: true, colorScheme: colorScheme);

  return base.copyWith(
    scaffoldBackgroundColor: background,
    textTheme: base.textTheme.apply(bodyColor: textPrimary, displayColor: textPrimary),
    cardTheme: CardThemeData(
      color: card,
      shape: RoundedRectangleBorder(borderRadius: radius),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: textPrimary,
      elevation: 0,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: card,
      selectedItemColor: primary,
      unselectedItemColor: textSecondary,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: card,
      indicatorColor: primary.withValues(alpha: 0.2),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(color: textPrimary, fontSize: 12),
      ),
      iconTheme: WidgetStatePropertyAll(IconThemeData(color: textPrimary)),
    ),
    extensions: [AppColorsExtension(streakColor: streak)],
  );
}
