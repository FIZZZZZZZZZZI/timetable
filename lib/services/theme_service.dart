import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:hive_flutter/hive_flutter.dart';

import '../data/theme_presets.dart';
import '../models/app_theme.dart';
import '../utils/theme_color_utils.dart';

/// Owns the theme box (presets + custom themes) and the selected theme id.
/// Pure service layer: no BuildContext — `main.dart` wraps `MaterialApp` in
/// a `ValueListenableBuilder` on [settingsListenable] and rebuilds via
/// `buildThemeData(currentTheme)`.
class ThemeService {
  ThemeService._();
  static final ThemeService instance = ThemeService._();

  static const String _themesBoxName = 'app_themes';
  static const String _settingsBoxName = 'app_settings';
  static const String _selectedIdKey = 'selected_theme_id';
  static const String _touchKey = 'themes_touched_at';

  late Box<AppTheme> _themesBox;
  late Box _settingsBox;

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(8)) {
      Hive.registerAdapter(AppThemeAdapter());
    }
    _themesBox = await Hive.openBox<AppTheme>(_themesBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);

    // Presets aren't user data — always re-seed them so code changes to
    // preset colors take effect on the next app start. Custom (isCustom:
    // true) entries are never touched here.
    for (final preset in buildPresetThemes()) {
      await _themesBox.put(preset.id, preset);
    }
  }

  /// Fires whenever the selected theme id changes, or any theme (custom
  /// create/edit/delete) changes — see [_touch].
  ValueListenable<Box> get settingsListenable => _settingsBox.listenable();

  String get selectedThemeId => (_settingsBox.get(_selectedIdKey) as String?) ?? kDefaultThemeId;

  AppTheme get currentTheme =>
      _themesBox.get(selectedThemeId) ??
      _themesBox.get(kDefaultThemeId) ??
      buildPresetThemes().first;

  List<AppTheme> get presets {
    final list = _themesBox.values.where((t) => !t.isCustom).toList();
    list.sort(
      (a, b) => (kPresetUnlockLevels[a.id] ?? 999).compareTo(kPresetUnlockLevels[b.id] ?? 999),
    );
    return list;
  }

  List<AppTheme> get customThemes => _themesBox.values.where((t) => t.isCustom).toList();

  Future<void> selectTheme(String id) async {
    await _settingsBox.put(_selectedIdKey, id);
    await _touch();
  }

  /// Creates a new custom theme, or updates an existing one if [id] is
  /// given. [textPrimary]/[textSecondary] are always derived from
  /// [background]'s luminance, never picked directly.
  Future<AppTheme> saveCustomTheme({
    String? id,
    required String name,
    required Color background,
    required Color card,
    required Color primary,
    required Color accent,
    required Color streakColor,
  }) async {
    final derived = deriveTextColors(background);
    final themeId = id ?? 'custom_${DateTime.now().microsecondsSinceEpoch}';
    final theme = AppTheme(
      id: themeId,
      name: name,
      isCustom: true,
      background: background.toARGB32(),
      card: card.toARGB32(),
      primary: primary.toARGB32(),
      accent: accent.toARGB32(),
      textPrimary: derived.textPrimary,
      textSecondary: derived.textSecondary,
      streakColor: streakColor.toARGB32(),
    );
    await _themesBox.put(themeId, theme);
    await _touch();
    return theme;
  }

  Future<void> deleteCustomTheme(String id) async {
    final wasSelected = selectedThemeId == id;
    await _themesBox.delete(id);
    if (wasSelected) {
      await _settingsBox.put(_selectedIdKey, kDefaultThemeId);
    }
    await _touch();
  }

  Future<void> _touch() async {
    await _settingsBox.put(_touchKey, DateTime.now().microsecondsSinceEpoch);
  }
}
