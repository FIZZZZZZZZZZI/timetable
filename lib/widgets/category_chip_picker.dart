import 'package:flutter/material.dart';

import '../models/activity_category.dart';
import '../models/custom_category.dart';

/// Category picker for the add/edit slot form. Shows the 5 built-in
/// categories plus any user-created ones (level 5+), as a single set of
/// chips addressed by a unified string id: a built-in [ActivityCategory]'s
/// `.name`, or a [CustomCategory]'s `id`.
class CategoryChipPicker extends StatelessWidget {
  final String selectedId;
  final List<CustomCategory> customCategories;
  final ValueChanged<String> onSelected;

  const CategoryChipPicker({
    super.key,
    required this.selectedId,
    required this.customCategories,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final category in ActivityCategory.values)
          _CategoryChip(
            id: category.name,
            label: category.label,
            emoji: category.emoji,
            color: category.color,
            isSelected: category.name == selectedId,
            onSelected: onSelected,
          ),
        for (final custom in customCategories)
          _CategoryChip(
            id: custom.id,
            label: custom.name,
            emoji: custom.emoji,
            color: Color(custom.colorValue),
            isSelected: custom.id == selectedId,
            onSelected: onSelected,
          ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String id;
  final String label;
  final String emoji;
  final Color color;
  final bool isSelected;
  final ValueChanged<String> onSelected;

  const _CategoryChip({
    required this.id,
    required this.label,
    required this.emoji,
    required this.color,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      avatar: Text(emoji, style: const TextStyle(fontSize: 14)),
      selected: isSelected,
      onSelected: (_) => onSelected(id),
      selectedColor: color,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
    );
  }
}
