import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Seed color choices offered in Settings (unlocked at level 8).
const List<Color> kSeedColorChoices = [Colors.indigo, Colors.teal, Colors.deepPurple, Colors.pink];
const List<String> kSeedColorNames = ['Indigo', 'Teal', 'Purple', 'Pink'];

/// Persists the chosen seed color + dark mode toggle in Hive and notifies
/// the app root to rebuild the [MaterialApp] theme live. Pure service
/// layer (a [ChangeNotifier] is not UI, just an observable value holder).
class ThemeService extends ChangeNotifier {
  ThemeService._();
  static final ThemeService instance = ThemeService._();

  static const String _boxName = 'app_settings';
  static const String _seedKey = 'seed_color_index';
  static const String _darkKey = 'is_dark_mode';

  late Box _box;

  int seedColorIndex = 0;
  bool isDarkMode = false;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    final storedIndex = _box.get(_seedKey) as int?;
    seedColorIndex = (storedIndex != null && storedIndex < kSeedColorChoices.length) ? storedIndex : 0;
    isDarkMode = (_box.get(_darkKey) as bool?) ?? false;
  }

  Color get seedColor => kSeedColorChoices[seedColorIndex];

  ThemeMode get themeMode => isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> setSeedColorIndex(int index) async {
    if (index == seedColorIndex) return;
    seedColorIndex = index;
    await _box.put(_seedKey, index);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    if (value == isDarkMode) return;
    isDarkMode = value;
    await _box.put(_darkKey, value);
    notifyListeners();
  }
}
