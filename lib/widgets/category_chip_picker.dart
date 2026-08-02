import 'package:flutter/material.dart';

import '../models/activity_category.dart';

class CategoryChipPicker extends StatelessWidget {
  final ActivityCategory selected;
  final ValueChanged<ActivityCategory> onSelected;

  const CategoryChipPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ActivityCategory.values.map((category) {
        final isSelected = category == selected;
        return ChoiceChip(
          label: Text(category.label),
          avatar: Icon(
            category.icon,
            size: 18,
            color: isSelected ? Colors.white : category.color,
          ),
          selected: isSelected,
          onSelected: (_) => onSelected(category),
          selectedColor: category.color,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : null,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          backgroundColor: category.color.withValues(alpha: 0.12),
          side: BorderSide(color: category.color.withValues(alpha: 0.4)),
        );
      }).toList(),
    );
  }
}
