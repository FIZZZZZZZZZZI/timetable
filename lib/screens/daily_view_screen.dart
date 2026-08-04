import 'dart:async';

import 'package:flutter/material.dart';

import '../models/activity_slot.dart';
import '../services/completion_service.dart';
import '../services/storage_service.dart';
import '../utils/week_dates.dart';
import '../widgets/activity_slot_tile.dart';
import '../widgets/add_edit_slot_sheet.dart';
import '../widgets/day_tabs.dart';

class DailyViewScreen extends StatefulWidget {
  const DailyViewScreen({super.key});

  @override
  State<DailyViewScreen> createState() => _DailyViewScreenState();
}

class _DailyViewScreenState extends State<DailyViewScreen> {
  final _storage = StorageService.instance;
  final _completion = CompletionService.instance;
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
    if (currentlyDone) {
      await _completion.unmarkDone(slot.id, date);
    } else {
      await _completion.markDone(slot.id, date);
    }
    if (mounted) setState(() {});
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
    final canToggleDone = _selectedDay == DateTime.now().weekday;

    return Scaffold(
      appBar: AppBar(
        title: const Text('This Week'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: DayTabs(
              selectedDay: _selectedDay,
              todayDayOfWeek: DateTime.now().weekday,
              onDaySelected: (day) => setState(() => _selectedDay = day),
            ),
          ),
          Expanded(
            child: slots.isEmpty
                ? _EmptyState(onAdd: () => _openAddEditSheet())
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                    itemCount: slots.length,
                    itemBuilder: (context, index) {
                      final slot = slots[index];
                      final isOngoing = slot.isOngoingAt(_now);
                      final isDone = _completion.isDone(slot.id, selectedDate);
                      return ActivitySlotTile(
                        slot: slot,
                        isOngoing: isOngoing,
                        isDone: isDone,
                        onTap: () => _openAddEditSheet(existing: slot),
                        onDismissed: () => _deleteSlot(slot),
                        onToggleDone: canToggleDone
                            ? () => _toggleDone(slot, selectedDate, isDone)
                            : null,
                      );
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
