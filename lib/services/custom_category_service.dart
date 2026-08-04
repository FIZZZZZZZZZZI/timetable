import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/activity_category.dart';
import '../models/activity_slot.dart';
import '../models/custom_category.dart';

/// Resolved category info for rendering — either from a built-in
/// [ActivityCategory] or a user-created [CustomCategory], so widgets don't
/// need to care which.
class CategoryDisplay {
  final String label;
  final String emoji;
  final Color color;

  const CategoryDisplay({required this.label, required this.emoji, required this.color});
}

/// CRUD for user-created categories (unlocked at level 5). Pure service
/// layer: no BuildContext — [resolve] returns plain data for widgets to
/// render.
class CustomCategoryService {
  CustomCategoryService._();
  static final CustomCategoryService instance = CustomCategoryService._();

  static const String _boxName = 'custom_categories';

  late Box<CustomCategory> _box;

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(CustomCategoryAdapter());
    }
    _box = await Hive.openBox<CustomCategory>(_boxName);
  }

  List<CustomCategory> getAll() => _box.values.toList();

  CustomCategory? get(String id) => _box.get(id);

  Future<CustomCategory> add({
    required String name,
    required String emoji,
    required Color color,
  }) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final category = CustomCategory(
      id: id,
      name: name,
      emoji: emoji,
      colorValue: color.toARGB32(),
    );
    await _box.put(id, category);
    return category;
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// The display info for [slot]: its custom category if it has one and
  /// that category still exists, otherwise its built-in category.
  CategoryDisplay resolve(ActivitySlot slot) {
    final customId = slot.customCategoryId;
    if (customId != null) {
      final custom = _box.get(customId);
      if (custom != null) {
        return CategoryDisplay(
          label: custom.name,
          emoji: custom.emoji,
          color: Color(custom.colorValue),
        );
      }
    }
    return CategoryDisplay(
      label: slot.category.label,
      emoji: slot.category.emoji,
      color: slot.category.color,
    );
  }
}
