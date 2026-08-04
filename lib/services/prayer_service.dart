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

/// Fetches, caches, and exposes JAKIM prayer times (via the solat.my API)
/// for the user's selected zone, and keeps prayer-time notifications
/// scheduled. Pure service layer: no BuildContext, no widgets.
class PrayerService {
  PrayerService._();
  static final PrayerService instance = PrayerService._();

  static const String _apiBase = 'https://solat.my/api';

  static const String _cacheBoxName = 'prayer_times_cache';
  static const String _settingsBoxName = 'prayer_settings';
  static const String _zoneKey = 'zone';
  static const String _zonesJsonKey = 'zones_json';

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
    // already cached (or the hardcoded zone list) if any of this fails —
    // no network, API down, first launch offline, etc.
    try {
      await refreshZonesIfNeeded();
    } catch (_) {}
    try {
      await refreshIfNeeded();
    } catch (_) {}
  }

  Future<void> setZone(String zoneCode) async {
    if (zoneCode == selectedZone) return;
    await _settingsBox.put(_zoneKey, zoneCode);
    try {
      await refreshIfNeeded();
    } catch (_) {}
  }

  // ---------------------------------------------------------------------
  // Zones (requirement 3): fetched from /api/locations and cached; falls
  // back to the hardcoded kJakimZones if that's never succeeded.
  // ---------------------------------------------------------------------

  /// The zone list to show in the picker: whatever was last fetched from
  /// the API, or [kJakimZones] if nothing has been cached yet.
  List<JakimZone> getAvailableZones() {
    final raw = _settingsBox.get(_zonesJsonKey) as String?;
    if (raw == null) return kJakimZones;

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final zones = decoded
          .cast<Map<String, dynamic>>()
          .map((m) => JakimZone(
                code: m['code'] as String,
                state: m['state'] as String,
                area: m['area'] as String,
              ))
          .toList();
      return zones.isEmpty ? kJakimZones : zones;
    } catch (_) {
      return kJakimZones;
    }
  }

  Future<void> refreshZonesIfNeeded({bool force = false}) async {
    if (!force && _settingsBox.containsKey(_zonesJsonKey)) return;
    await _fetchAndCacheZones();
  }

  Future<void> _fetchAndCacheZones() async {
    final uri = Uri.parse('$_apiBase/locations');
    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch zones (${response.statusCode})');
    }

    final rows = jsonDecode(response.body) as List<dynamic>;

    // The API returns one row per named location, with several rows
    // sharing the same zone code (and, occasionally, differing "state"
    // labels for the same code — e.g. WLY01 covers both Kuala Lumpur and
    // Putrajaya). Group by code, keep the first state seen, and merge the
    // location names into a single description.
    final statesByCode = <String, String>{};
    final areasByCode = <String, List<String>>{};
    for (final raw in rows) {
      final map = raw as Map<String, dynamic>;
      final code = map['code'] as String;
      final state = map['state'] as String;
      final location = map['location'] as String;
      statesByCode.putIfAbsent(code, () => state);
      final areas = areasByCode.putIfAbsent(code, () => []);
      if (!areas.contains(location)) areas.add(location);
    }

    final zones = statesByCode.keys.map((code) {
      return JakimZone(
        code: code,
        state: statesByCode[code]!,
        area: areasByCode[code]!.join(', '),
      );
    }).toList()
      ..sort((a, b) => a.code.compareTo(b.code));

    if (zones.isEmpty) return;

    final encoded = jsonEncode(
      zones.map((z) => {'code': z.code, 'state': z.state, 'area': z.area}).toList(),
    );
    await _settingsBox.put(_zonesJsonKey, encoded);
  }

  // ---------------------------------------------------------------------
  // Prayer times cache (requirement 1)
  // ---------------------------------------------------------------------

  String _monthCacheKey(String zone, DateTime monthOf) =>
      'cached_${zone}_${monthOf.year}-${monthOf.month.toString().padLeft(2, '0')}';

  bool _isMonthCached(String zone, DateTime monthOf) =>
      _settingsBox.get(_monthCacheKey(zone, monthOf)) == true;

  /// Fetches and caches the current month if it isn't cached yet for the
  /// selected zone, plus tomorrow's month too if today is the last day of
  /// the month (otherwise tomorrow's prayer times/notifications would
  /// silently go missing right at the month boundary). Reschedules
  /// notifications either way, so this is safe to call on every app open.
  Future<void> refreshIfNeeded() async {
    final zone = selectedZone;
    final today = DateTime.now();

    if (!_isMonthCached(zone, today)) {
      await fetchAndCacheMonth(zone, today);
    }

    final tomorrow = today.add(const Duration(days: 1));
    if (tomorrow.month != today.month && !_isMonthCached(zone, tomorrow)) {
      await fetchAndCacheMonth(zone, tomorrow);
    }

    await rescheduleNotifications();
  }

  Future<void> fetchAndCacheMonth(String zone, DateTime monthOf) async {
    final month = monthOf.month;
    final uri = Uri.parse('$_apiBase/monthly/$zone/$month');
    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch prayer times (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final prayerTimes = data['prayerTime'] as List<dynamic>?;
    if (prayerTimes == null) {
      throw Exception('Unexpected prayer time response shape');
    }

    for (final raw in prayerTimes) {
      final map = raw as Map<String, dynamic>;
      // "date" looks like "01-Ogos-2026" (day-MalayMonthName-year). The
      // month name is in Malay and its abbreviation isn't consistent
      // (e.g. "Ogos" vs "Dis"), so rather than parse it, we take only the
      // numeric day and year from it and use the month we explicitly
      // requested.
      final dateStr = map['date'] as String?;
      final parts = dateStr?.split('-');
      if (parts == null || parts.length != 3) continue;
      final day = int.tryParse(parts[0]);
      final year = int.tryParse(parts[2]);
      final fajr = map['fajr'] as String?;
      final dhuhr = map['dhuhr'] as String?;
      final asr = map['asr'] as String?;
      final maghrib = map['maghrib'] as String?;
      final isha = map['isha'] as String?;
      if (day == null ||
          year == null ||
          fajr == null ||
          dhuhr == null ||
          asr == null ||
          maghrib == null ||
          isha == null) {
        continue;
      }

      final date = DateTime(year, month, day);
      final entry = PrayerTimeEntry(
        id: _entryKey(zone, date),
        zone: zone,
        date: date,
        subuh: _parseTimeOfDay(fajr),
        zohor: _parseTimeOfDay(dhuhr),
        asar: _parseTimeOfDay(asr),
        maghrib: _parseTimeOfDay(maghrib),
        isyak: _parseTimeOfDay(isha),
      );
      await _cacheBox.put(entry.id, entry);
    }

    await _settingsBox.put(_monthCacheKey(zone, monthOf), true);
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

  // ---------------------------------------------------------------------
  // Notifications (requirement 6)
  // ---------------------------------------------------------------------

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

  TimeOfDay _parseTimeOfDay(String hhmmss) {
    final parts = hhmmss.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _dateKeyFor(DateTime date) {
    final d = normalizeDate(date);
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String _entryKey(String zone, DateTime date) => '${zone}_${_dateKeyFor(date)}';
}
