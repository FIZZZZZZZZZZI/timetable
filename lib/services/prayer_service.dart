import 'dart:convert';

import 'package:flutter/material.dart' show TimeOfDay, DayPeriod;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

import '../models/jakim_zone.dart';
import '../models/prayer_time_entry.dart';
import '../utils/week_dates.dart';
import 'notification_service.dart';

/// One daily prayer, generated at render time from cached [PrayerTimeEntry]
/// data — never persisted as its own record.
class PrayerActivity {
  final String id;
  final String name;
  final TimeOfDay time;

  const PrayerActivity({required this.id, required this.name, required this.time});
}

/// Fetches, caches, and exposes JAKIM prayer times for the user's selected
/// zone, and keeps prayer-time notifications scheduled. Pure service layer:
/// no BuildContext, no widgets.
class PrayerService {
  PrayerService._();
  static final PrayerService instance = PrayerService._();

  static const String _cacheBoxName = 'prayer_times_cache';
  static const String _settingsBoxName = 'prayer_settings';
  static const String _zoneKey = 'zone';

  /// Stable ids for the 5 daily prayers, in order. Shared with
  /// [GamificationService] so "all prayers done" checks stay in sync with
  /// whatever this service actually generates.
  static const List<String> prayerIds = [
    'prayer_subuh',
    'prayer_zohor',
    'prayer_asar',
    'prayer_maghrib',
    'prayer_isyak',
  ];

  static const Map<String, String> _prayerLabels = {
    'prayer_subuh': 'Subuh',
    'prayer_zohor': 'Zohor',
    'prayer_asar': 'Asar',
    'prayer_maghrib': 'Maghrib',
    'prayer_isyak': 'Isyak',
  };

  late Box<PrayerTimeEntry> _cacheBox;
  late Box _settingsBox;

  String get selectedZone => (_settingsBox.get(_zoneKey) as String?) ?? kDefaultJakimZone;

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(PrayerTimeEntryAdapter());
    }
    _cacheBox = await Hive.openBox<PrayerTimeEntry>(_cacheBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);

    // Best-effort: the app must keep working offline on whatever is
    // already cached if this fails (no network, API down, etc).
    try {
      await refreshIfNeeded();
    } catch (_) {}
  }

  Future<void> setZone(String zoneCode) async {
    if (zoneCode == selectedZone) return;
    await _settingsBox.put(_zoneKey, zoneCode);
    try {
      await fetchAndCacheMonth(zoneCode, DateTime.now());
    } catch (_) {}
    await rescheduleNotifications();
  }

  bool _needsRefresh() {
    final cachedMonth = _settingsBox.get('cached_month_$selectedZone') as String?;
    return cachedMonth != _monthKey(DateTime.now());
  }

  /// Fetches the current month's data if it hasn't been cached yet for the
  /// selected zone, then (re)schedules prayer notifications either way.
  Future<void> refreshIfNeeded() async {
    if (_needsRefresh()) {
      await fetchAndCacheMonth(selectedZone, DateTime.now());
    }
    await rescheduleNotifications();
  }

  Future<void> fetchAndCacheMonth(String zone, DateTime monthOf) async {
    final uri = Uri.parse('https://api.waktusolat.app/v2/solat/$zone');
    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch prayer times (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final year = data['year'] as int;
    final monthNumber = data['month_number'] as int;
    final prayers = data['prayers'] as List<dynamic>;

    for (final raw in prayers) {
      final map = raw as Map<String, dynamic>;
      final day = map['day'] as int;
      final date = DateTime(year, monthNumber, day);

      final entry = PrayerTimeEntry(
        id: _entryKey(zone, date),
        zone: zone,
        date: date,
        subuh: _toMalaysiaTime(map['fajr'] as int),
        zohor: _toMalaysiaTime(map['dhuhr'] as int),
        asar: _toMalaysiaTime(map['asr'] as int),
        maghrib: _toMalaysiaTime(map['maghrib'] as int),
        isyak: _toMalaysiaTime(map['isha'] as int),
      );
      await _cacheBox.put(entry.id, entry);
    }

    await _settingsBox.put('cached_month_$zone', _monthKey(monthOf));
  }

  /// The 5 daily prayers for [date] as render-time activities, or an empty
  /// list if nothing is cached for that date/zone (e.g. first launch
  /// offline before any successful fetch).
  List<PrayerActivity> getPrayerActivitiesForDate(DateTime date) {
    final entry = _cacheBox.get(_entryKey(selectedZone, date));
    if (entry == null) return const [];

    return [
      PrayerActivity(id: prayerIds[0], name: _prayerLabels[prayerIds[0]]!, time: entry.subuh),
      PrayerActivity(id: prayerIds[1], name: _prayerLabels[prayerIds[1]]!, time: entry.zohor),
      PrayerActivity(id: prayerIds[2], name: _prayerLabels[prayerIds[2]]!, time: entry.asar),
      PrayerActivity(id: prayerIds[3], name: _prayerLabels[prayerIds[3]]!, time: entry.maghrib),
      PrayerActivity(id: prayerIds[4], name: _prayerLabels[prayerIds[4]]!, time: entry.isyak),
    ];
  }

  /// Schedules a one-off notification at each of today's and tomorrow's
  /// prayer times (whatever is cached), cancelling/skipping any that have
  /// already passed. Called after every cache refresh and zone change so
  /// the schedule never drifts from what's actually cached.
  Future<void> rescheduleNotifications() async {
    final today = normalizeDate(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));

    for (final date in [today, tomorrow]) {
      for (final activity in getPrayerActivitiesForDate(date)) {
        final id = NotificationService.instance.idFor(
          '${activity.id}_${_dateKeyFor(date)}',
        );
        final scheduledDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          activity.time.hour,
          activity.time.minute,
        );

        if (!scheduledDateTime.isAfter(DateTime.now())) {
          await NotificationService.instance.cancelById(id);
          continue;
        }

        await NotificationService.instance.scheduleOneOff(
          id: id,
          dateTime: scheduledDateTime,
          title: 'Masuk waktu ${activity.name} 🕌',
          body: _formatTime(activity.time),
        );
      }
    }
  }

  TimeOfDay _toMalaysiaTime(int epochSeconds) {
    // Malaysia is a fixed UTC+8 with no daylight saving, so this is always
    // correct regardless of the device's own timezone setting.
    final utc = DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000, isUtc: true);
    final myt = utc.add(const Duration(hours: 8));
    return TimeOfDay(hour: myt.hour, minute: myt.minute);
  }

  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _monthKey(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}';

  String _dateKeyFor(DateTime date) {
    final d = normalizeDate(date);
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String _entryKey(String zone, DateTime date) => '${zone}_${_dateKeyFor(date)}';
}
