import 'package:hive_flutter/hive_flutter.dart';

import '../models/completion_record.dart';
import '../utils/week_dates.dart';

/// Tracks which [ActivitySlot] occurrences have been checked off on which
/// calendar date. Pure service layer: no BuildContext, no widgets.
class CompletionService {
  CompletionService._();
  static final CompletionService instance = CompletionService._();

  static const String _boxName = 'completion_records';

  late Box<CompletionRecord> _box;

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(CompletionRecordAdapter());
    }
    _box = await Hive.openBox<CompletionRecord>(_boxName);
  }

  String _keyFor(String slotId, DateTime date) {
    final d = normalizeDate(date);
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${slotId}_$y-$m-$day';
  }

  Future<void> markDone(String slotId, DateTime date) async {
    final key = _keyFor(slotId, date);
    await _box.put(
      key,
      CompletionRecord(
        id: key,
        slotId: slotId,
        date: normalizeDate(date),
        completedAt: DateTime.now(),
      ),
    );
  }

  Future<void> unmarkDone(String slotId, DateTime date) async {
    await _box.delete(_keyFor(slotId, date));
  }

  bool isDone(String slotId, DateTime date) => _box.containsKey(_keyFor(slotId, date));

  /// All completion records whose date falls within the 7 days starting at
  /// [weekStart] (inclusive of [weekStart], exclusive of [weekStart] + 7d).
  List<CompletionRecord> getCompletionsForWeek(DateTime weekStart) {
    final start = normalizeDate(weekStart);
    final end = start.add(const Duration(days: 7));
    return _box.values
        .where((r) => !r.date.isBefore(start) && r.date.isBefore(end))
        .toList();
  }

  /// Deletes every completion record for [slotId], e.g. when the slot
  /// itself is deleted so it doesn't leave orphaned records behind.
  Future<void> deleteForSlot(String slotId) async {
    final keys = _box.values.where((r) => r.slotId == slotId).map((r) => r.id).toList();
    await _box.deleteAll(keys);
  }
}
