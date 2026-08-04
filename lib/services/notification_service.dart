import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay, DayPeriod;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/activity_category.dart';
import '../models/activity_slot.dart';

/// Schedules and cancels weekly-recurring reminder notifications for
/// [ActivitySlot]s. Pure service layer: no BuildContext, no widgets.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const String _channelId = 'activity_reminders';
  static const String _channelName = 'Activity reminders';
  static const String _channelDescription = 'Reminders before your scheduled activities';

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _exactAlarmsAllowed = false;

  /// Only Android and iOS get real local notifications. Desktop/web builds
  /// of this app (used during development) silently no-op instead of
  /// throwing, since the plugin requires per-platform init settings we
  /// don't otherwise configure.
  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> init() async {
    if (!_supported || _initialized) return;

    tz_data.initializeTimeZones();
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
    } catch (_) {
      // Keep the UTC default location if the platform lookup fails; the
      // reminder will still fire, just anchored to UTC instead of local time.
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (_) {},
    );

    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      try {
        await android?.requestNotificationsPermission();
        await android?.requestExactAlarmsPermission();
        _exactAlarmsAllowed = await android?.canScheduleExactNotifications() ?? false;
      } catch (_) {
        // Permission APIs are only available on certain Android versions;
        // treat any failure as "no exact alarms" and fall back to inexact.
        _exactAlarmsAllowed = false;
      }
    }

    _initialized = true;
  }

  Future<void> scheduleReminder(ActivitySlot slot) async {
    if (!_supported) return;
    await init();

    final id = _notificationIdFor(slot.id);
    await _plugin.cancel(id: id);

    if (slot.reminderMinutes <= 0) return;

    final scheduledDate = _nextReminderOccurrence(slot);

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    final scheduleMode = _exactAlarmsAllowed
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    try {
      await _plugin.zonedSchedule(
        id: id,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: scheduleMode,
        title: '${slot.category.emoji} ${slot.title}',
        body: _bodyFor(slot),
        payload: slot.id,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (_) {
      // Never let a scheduling failure (e.g. a device that revokes exact
      // alarm rights mid-flight) crash the add/edit flow.
    }
  }

  Future<void> cancelReminder(String slotId) async {
    if (!_supported) return;
    await _plugin.cancel(id: _notificationIdFor(slotId));
  }

  String _bodyFor(ActivitySlot slot) {
    final time = '${_formatTime(slot.startTime)} - ${_formatTime(slot.endTime)}';
    final location = slot.location;
    if (location != null && location.isNotEmpty) {
      return '$time  •  $location';
    }
    return time;
  }

  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  /// Next future [tz.TZDateTime] matching the slot's day-of-week and
  /// reminder time. Only used to seed the first firing: the actual weekly
  /// recurrence is handled natively via `matchDateTimeComponents`.
  tz.TZDateTime _nextReminderOccurrence(ActivitySlot slot) {
    final now = tz.TZDateTime.now(tz.local);

    var minutesOfDay = slot.startMinutes - slot.reminderMinutes;
    var targetWeekday = slot.dayOfWeek;
    while (minutesOfDay < 0) {
      minutesOfDay += 24 * 60;
      targetWeekday = targetWeekday == 1 ? 7 : targetWeekday - 1;
    }

    final hour = minutesOfDay ~/ 60;
    final minute = minutesOfDay % 60;

    var candidate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    final dayDelta = (targetWeekday - candidate.weekday) % 7;
    candidate = candidate.add(Duration(days: dayDelta));
    if (!candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 7));
    }
    return candidate;
  }

  int _notificationIdFor(String id) {
    var hash = 0;
    for (final codeUnit in id.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7FFFFFFF;
    }
    return hash;
  }
}
