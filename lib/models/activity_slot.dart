import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'activity_category.dart';

part 'activity_slot.g.dart';

@HiveType(typeId: 1)
class ActivitySlot extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  ActivityCategory category;

  /// 1 = Monday ... 7 = Sunday
  @HiveField(3)
  int dayOfWeek;

  @HiveField(4)
  TimeOfDay startTime;

  @HiveField(5)
  TimeOfDay endTime;

  @HiveField(6)
  String? location;

  @HiveField(7)
  String? notes;

  ActivitySlot({
    required this.id,
    required this.title,
    required this.category,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.location,
    this.notes,
  });

  int get startMinutes => startTime.hour * 60 + startTime.minute;
  int get endMinutes => endTime.hour * 60 + endTime.minute;

  bool isOngoingAt(DateTime now) {
    final nowMinutes = now.hour * 60 + now.minute;
    return now.weekday == dayOfWeek &&
        nowMinutes >= startMinutes &&
        nowMinutes < endMinutes;
  }

  ActivitySlot copyWith({
    String? title,
    ActivityCategory? category,
    int? dayOfWeek,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? location,
    String? notes,
  }) {
    return ActivitySlot(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      notes: notes ?? this.notes,
    );
  }
}
