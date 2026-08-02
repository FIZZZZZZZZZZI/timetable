import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'activity_category.g.dart';

@HiveType(typeId: 0)
enum ActivityCategory {
  @HiveField(0)
  kelas,
  @HiveField(1)
  gym,
  @HiveField(2)
  content,
  @HiveField(3)
  study,
  @HiveField(4)
  other,
}

extension ActivityCategoryX on ActivityCategory {
  String get label {
    switch (this) {
      case ActivityCategory.kelas:
        return 'Kelas';
      case ActivityCategory.gym:
        return 'Gym';
      case ActivityCategory.content:
        return 'Content';
      case ActivityCategory.study:
        return 'Study';
      case ActivityCategory.other:
        return 'Other';
    }
  }

  Color get color {
    switch (this) {
      case ActivityCategory.kelas:
        return const Color(0xFF3F51B5); // indigo
      case ActivityCategory.gym:
        return const Color(0xFFE53935); // red
      case ActivityCategory.content:
        return const Color(0xFF8E24AA); // purple
      case ActivityCategory.study:
        return const Color(0xFF00897B); // teal
      case ActivityCategory.other:
        return const Color(0xFFFB8C00); // orange
    }
  }

  IconData get icon {
    switch (this) {
      case ActivityCategory.kelas:
        return Icons.school;
      case ActivityCategory.gym:
        return Icons.fitness_center;
      case ActivityCategory.content:
        return Icons.videocam;
      case ActivityCategory.study:
        return Icons.menu_book;
      case ActivityCategory.other:
        return Icons.event;
    }
  }
}
