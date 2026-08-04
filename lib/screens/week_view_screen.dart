import 'package:flutter/material.dart';

import '../models/activity_category.dart';
import '../models/activity_slot.dart';
import '../services/completion_service.dart';
import '../services/prayer_service.dart';
import '../services/storage_service.dart';
import '../utils/slot_layout.dart';
import '../utils/week_dates.dart';
import '../widgets/add_edit_slot_sheet.dart';
import '../widgets/day_tabs.dart';
import '../widgets/prayer_tile.dart';

const int _startHour = 7;
const int _endHour = 23; // 11 PM
const double _hourHeight = 64;
const double _gutterWidth = 40;

class WeekViewScreen extends StatefulWidget {
  const WeekViewScreen({super.key});

  @override
  State<WeekViewScreen> createState() => _WeekViewScreenState();
}

class _WeekViewScreenState extends State<WeekViewScreen> {
  final _storage = StorageService.instance;
  final _completion = CompletionService.instance;
  final _prayer = PrayerService.instance;

  Future<void> _openEditSheet(ActivitySlot slot) async {
    final result = await showModalBottomSheet<ActivitySlot>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => AddEditSlotSheet(
        existing: slot,
        initialDay: slot.dayOfWeek,
      ),
    );

    if (result == null) return;
    await _storage.updateSlot(result);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().weekday;
    final totalHeight = (_endHour - _startHour) * _hourHeight;

    final layoutsByDay = <int, List<SlotLayout>>{
      for (var day = 1; day <= 7; day++) day: computeOverlapLayout(_storage.getForDay(day)),
    };

    final doneSlotIdsByDay = <int, Set<String>>{
      for (var day = 1; day <= 7; day++)
        day: layoutsByDay[day]!
            .map((l) => l.slot)
            .where((slot) => _completion.isDone(slot.id, dateForDayOfWeek(day)))
            .map((slot) => slot.id)
            .toSet(),
    };

    final prayersByDay = <int, List<PrayerActivity>>{
      for (var day = 1; day <= 7; day++)
        day: _prayer.getPrayerActivitiesForDate(dateForDayOfWeek(day)),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Week'), centerTitle: false),
      body: Column(
        children: [
          _WeekHeader(todayDayOfWeek: today),
          Expanded(
            child: SingleChildScrollView(
              child: SizedBox(
                height: totalHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _HourGutter(),
                    Expanded(
                      child: Row(
                        children: List.generate(7, (i) {
                          final day = i + 1;
                          return Expanded(
                            child: _DayColumn(
                              isToday: day == today,
                              layouts: layoutsByDay[day]!,
                              doneSlotIds: doneSlotIdsByDay[day]!,
                              prayers: prayersByDay[day]!,
                              onTapSlot: _openEditSheet,
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekHeader extends StatelessWidget {
  final int todayDayOfWeek;

  const _WeekHeader({required this.todayDayOfWeek});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          const SizedBox(width: _gutterWidth),
          ...List.generate(7, (i) {
            final day = i + 1;
            final isToday = day == todayDayOfWeek;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isToday
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  kDayLabels[i],
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isToday
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _HourGutter extends StatelessWidget {
  const _HourGutter();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hourCount = _endHour - _startHour;
    return SizedBox(
      width: _gutterWidth,
      height: hourCount * _hourHeight,
      child: Stack(
        children: List.generate(hourCount, (i) {
          final hour = _startHour + i;
          return Positioned(
            top: i * _hourHeight - 7,
            left: 0,
            right: 4,
            child: Text(
              TimeOfDay(hour: hour, minute: 0).format(context),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _DayColumn extends StatelessWidget {
  final bool isToday;
  final List<SlotLayout> layouts;
  final Set<String> doneSlotIds;
  final List<PrayerActivity> prayers;
  final ValueChanged<ActivitySlot> onTapSlot;

  const _DayColumn({
    required this.isToday,
    required this.layouts,
    required this.doneSlotIds,
    required this.prayers,
    required this.onTapSlot,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hourCount = _endHour - _startHour;
    final totalHeight = hourCount * _hourHeight;

    return Container(
      height: totalHeight,
      decoration: BoxDecoration(
        color: isToday ? theme.colorScheme.primary.withValues(alpha: 0.05) : null,
        border: Border(
          left: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columnWidth = constraints.maxWidth;
          return Stack(
            children: [
              ...List.generate(hourCount + 1, (i) {
                return Positioned(
                  top: i * _hourHeight,
                  left: 0,
                  right: 0,
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
                  ),
                );
              }),
              for (final prayer in prayers) _buildPrayerMarker(prayer),
              for (final layout in layouts) _buildSlotBlock(context, layout, columnWidth),
            ],
          );
        },
      ),
    );
  }

  /// Thin horizontal line marking a prayer time, rendered behind slot
  /// blocks. Prayers outside the grid's visible hour range (e.g. Subuh,
  /// usually before the 7 AM start) are simply skipped rather than clamped
  /// to the edge, which would misrepresent their actual time.
  Widget _buildPrayerMarker(PrayerActivity prayer) {
    final minutesOfDay = prayer.time.hour * 60 + prayer.time.minute;
    final rangeStart = _startHour * 60;
    final rangeEnd = _endHour * 60;
    if (minutesOfDay < rangeStart || minutesOfDay >= rangeEnd) {
      return const SizedBox.shrink();
    }

    final top = (minutesOfDay - rangeStart) / 60 * _hourHeight;
    return Positioned(
      top: top - 0.75,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Container(height: 1.5, color: PrayerTile.accent.withValues(alpha: 0.55)),
      ),
    );
  }

  Widget _buildSlotBlock(BuildContext context, SlotLayout layout, double columnWidth) {
    final slot = layout.slot;
    final top = (slot.startMinutes - _startHour * 60) / 60 * _hourHeight;
    final rawHeight = (slot.endMinutes - slot.startMinutes) / 60 * _hourHeight;
    final height = rawHeight < 22 ? 22.0 : rawHeight;

    final fracWidth = 1 / layout.columnCount;
    final leftPx = columnWidth * fracWidth * layout.columnIndex;
    final widthPx = columnWidth * fracWidth;
    final blockWidth = widthPx - 2 < 0 ? 0.0 : widthPx - 2;

    return Positioned(
      top: top,
      height: height,
      left: leftPx + 1,
      width: blockWidth,
      child: _SlotBlockContent(
        slot: slot,
        isDone: doneSlotIds.contains(slot.id),
        onTap: () => onTapSlot(slot),
      ),
    );
  }
}

class _SlotBlockContent extends StatelessWidget {
  final ActivitySlot slot;
  final bool isDone;
  final VoidCallback onTap;

  const _SlotBlockContent({required this.slot, required this.isDone, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = slot.category.color;

    return Material(
      color: color.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final showTime = constraints.maxHeight >= 34;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        slot.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                      ),
                      if (showTime)
                        Text(
                          '${slot.startTime.format(context)} - ${slot.endTime.format(context)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            height: 1.1,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            if (isDone)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Icon(Icons.check, size: 10, color: color),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
