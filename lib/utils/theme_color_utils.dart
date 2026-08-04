import 'package:flutter/material.dart';

/// Light-on-dark text pair, matching the Ninja preset's own text colors.
const int kLightTextPrimary = 0xFFE8EDF7;
const int kLightTextSecondary = 0xFF8A93A6;

/// Dark-on-light text pair, matching the Default preset's own text colors.
const int kDarkTextPrimary = 0xFF1B1B1F;
const int kDarkTextSecondary = 0xFF46464F;

/// Auto-derives a readable (textPrimary, textSecondary) pair for
/// [background]: light text on a dark background, dark text on a light
/// one. Used by the custom theme builder so users only ever pick the 5
/// "visual" colors and always end up with legible text.
({int textPrimary, int textSecondary}) deriveTextColors(Color background) {
  final isDark = background.computeLuminance() < 0.5;
  return isDark
      ? (textPrimary: kLightTextPrimary, textSecondary: kLightTextSecondary)
      : (textPrimary: kDarkTextPrimary, textSecondary: kDarkTextSecondary);
}
