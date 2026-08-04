import 'dart:async';

import 'package:flutter/material.dart';

import '../models/activity_slot.dart';
import '../services/completion_service.dart';
import '../services/gamification_service.dart';
import '../services/prayer_service.dart';
import '../services/storage_service.dart';
import '../utils/week_dates.dart';
import '../widgets/activity_slot_tile.dart';
import '../widgets/add_edit_slot_sheet.dart';
import '../widgets/badge_unlock_dialog.dart';
import '../widgets/day_tabs.dart';
import '../widgets/level_up_dialog.dart';
import '../widgets/prayer_tile.dart';
import '../widgets/progress_header_card.dart';
import 'settings_screen.dart';

sealed class _TimelineEntry {
  int get minutesOfDay;
}

class _ActivityEntry extends _TimelineEntry {
  final ActivitySlot slot;
  _ActivityEntry(this.slot);

  @override
  int get minutesOfDay => slot.startMinutes;
}

class _PrayerEntry extends _TimelineEntry {
  final PrayerActivity prayer;
  _PrayerEntry(this.prayer);

  @override
  int get minutesOfDay => prayer.time.hour * 60 + prayer.time.minute;
}

class DailyViewScreen extends StatefulWidget {
  const DailyViewScreen({super.key});

  @override
  State<DailyViewScreen> createState() => _DailyViewScreenState();
}

class _DailyViewScreenState extends State<DailyViewScreen> {
  final _storage = StorageService.instance;
  final _completion = CompletionService.instance;
  final _gamification = GamificationService.instance;
  final _prayer = PrayerService.instance;
  late int _selectedDay;
  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now().weekday;
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  List<ActivitySlot> get _slotsForSelectedDay => _storage.getForDay(_selectedDay);

  Future<void> _openAddEditSheet({ActivitySlot? existing}) async {
    final result = await showModalBottomSheet<ActivitySlot>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => AddEditSlotSheet(
        existing: existing,
        initialDay: _selectedDay,
      ),
    );

    if (result == null) return;

    if (existing == null) {
      await _storage.addSlot(result);
    } else {
      await _storage.updateSlot(result);
    }
    setState(() => _selectedDay = result.dayOfWeek);
  }

  Future<void> _toggleDone(ActivitySlot slot, DateTime date, bool currentlyDone) async {
    debugPrint('[checkin] toggle tapped: slot=${slot.id} date=$date currentlyDone=$currentlyDone');
    final daySlots = _storage.getForDay(slot.dayOfWeek);

    if (currentlyDone) {
      await _completion.unmarkDone(slot.id, date);
      await _gamification.onSlotUnmarkedDone(
        slotId: slot.id,
        date: date,
        allSlotsForDate: daySlots,
      );
      if (mounted) setState(() {});
      return;
    }

    await _completion.markDone(slot.id, date);
    final result = await _gamification.onSlotMarkedDone(
      slotId: slot.id,
      date: date,
      allSlotsForDate: daySlots,
    );
    if (!mounted) return;
    setState(() {});
    await _showCelebrations(result);
  }

  Future<void> _togglePrayerDone(
    PrayerActivity prayer,
    DateTime date,
    bool currentlyDone,
  ) async {
    if (currentlyDone) {
      await _completion.unmarkDone(prayer.id, date);
      await _gamification.onPrayerUnmarkedDone(prayerId: prayer.id, date: date);
      if (mounted) setState(() {});
      return;
    }

    await _completion.markDone(prayer.id, date);
    final result = await _gamification.onPrayerMarkedDone(prayerId: prayer.id, date: date);
    if (!mounted) return;
    setState(() {});
    await _showCelebrations(result);
  }

  /// Level-up first, then any newly unlocked badges, one at a time — each
  /// dialog awaits dismissal before the next appears.
  Future<void> _showCelebrations(GamificationResult result) async {
    if (result.leveledUp) {
      if (!mounted) return;
      await LevelUpDialog.show(context, result.newLevel);
    }
    for (final badge in result.newlyUnlockedBadges) {
      if (!mounted) return;
      await BadgeUnlockDialog.show(context, badge);
    }
  }

  Future<void> _deleteSlot(ActivitySlot slot) async {
    await _storage.deleteSlot(slot.id);
    if (!mounted) return;
    setState(() {});

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${slot.title}" deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            await _storage.addSlot(slot);
            if (mounted) setState(() {});
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final slots = _slotsForSelectedDay;
    final theme = Theme.of(context);
    final selectedDate = dateForDayOfWeek(_selectedDay);
    // Today and any past day (this week) can be checked off; future days
    // stay view-only since you can't complete something before it happens.
    final canToggleDone = !selectedDate.isAfter(normalizeDate(DateTime.now()));

    final prayerActivities = _prayer.getPrayerActivitiesForDate(selectedDate);
    final timeline = <_TimelineEntry>[
      ...slots.map(_ActivityEntry.new),
      ...prayerActivities.map(_PrayerEntry.new),
    ]..sort((a, b) => a.minutesOfDay.compareTo(b.minutesOfDay));

    return Scaffold(
      appBar: AppBar(
        title: const Text('This Week'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          ProgressHeaderCard(
            level: _gamification.currentLevel,
            xpIntoLevel: _gamification.xpIntoLevel,
            xpForNextLevel: _gamification.xpForNextLevel,
            levelProgress: _gamification.levelProgress,
            currentStreak: _gamification.progress.currentStreak,
            prayerStreak: _gamification.progress.prayerCurrentStreak,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: DayTabs(
              selectedDay: _selectedDay,
              todayDayOfWeek: DateTime.now().weekday,
              onDaySelected: (day) => setState(() => _selectedDay = day),
            ),
          ),
          if (prayerActivities.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: _PrayerUnavailableBanner(
                onOpenSettings: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                  if (mounted) setState(() {});
                },
              ),
            ),
          Expanded(
            child: timeline.isEmpty
                ? _EmptyState(onAdd: () => _openAddEditSheet())
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                    itemCount: timeline.length,
                    itemBuilder: (context, index) {
                      final entry = timeline[index];
                      switch (entry) {
                        case _ActivityEntry(:final slot):
                          final isDone = _completion.isDone(slot.id, selectedDate);
                          return ActivitySlotTile(
                            slot: slot,
                            isOngoing: slot.isOngoingAt(_now),
                            isDone: isDone,
                            onTap: () => _openAddEditSheet(existing: slot),
                            onDismissed: () => _deleteSlot(slot),
                            onToggleDone: canToggleDone
                                ? () => _toggleDone(slot, selectedDate, isDone)
                                : null,
                          );
                        case _PrayerEntry(:final prayer):
                          final isDone = _completion.isDone(prayer.id, selectedDate);
                          return PrayerTile(
                            prayer: prayer,
                            isDone: isDone,
                            onToggleDone: canToggleDone
                                ? () => _togglePrayerDone(prayer, selectedDate, isDone)
                                : null,
                          );
                      }
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEditSheet(),
        icon: const Icon(Icons.add),
        label: const Text('Add Activity'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
    );
  }
}

/// Shown in place of the prayer timeline entries whenever nothing is
/// cached for the selected date/zone yet (first launch offline, zone just
/// changed with no connectivity, API unreachable, etc) — never a crash,
/// always a way forward.
class _PrayerUnavailableBanner extends StatelessWidget {
  final VoidCallback onOpenSettings;

  const _PrayerUnavailableBanner({required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: PrayerTile.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PrayerTile.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Text('🕌', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Pilih zon & sambung internet untuk muat waktu solat',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface),
            ),
          ),
          TextButton(
            onPressed: onOpenSettings,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Tetapan'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_available_outlined,
              size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            'No activities for this day',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add an activity'),
          ),
        ],
      ),
    );
  }
}
