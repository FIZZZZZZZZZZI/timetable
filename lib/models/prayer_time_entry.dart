import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'prayer_time_entry.g.dart';

/// One zone's cached prayer times for a single calendar date, fetched from
/// the JAKIM-backed waktusolat API.
@HiveType(typeId: 5)
class PrayerTimeEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String zone;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  TimeOfDay subuh;

  @HiveField(4)
  TimeOfDay zohor;

  @HiveField(5)
  TimeOfDay asar;

  @HiveField(6)
  TimeOfDay maghrib;

  @HiveField(7)
  TimeOfDay isyak;

  PrayerTimeEntry({
    required this.id,
    required this.zone,
    required this.date,
    required this.subuh,
    required this.zohor,
    required this.asar,
    required this.maghrib,
    required this.isyak,
  });
}
