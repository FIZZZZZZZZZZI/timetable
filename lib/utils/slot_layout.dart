import '../models/activity_slot.dart';

/// Column assignment for one slot within a cluster of time-overlapping
/// slots on the same day, so overlapping blocks can split column width
/// instead of stacking on top of each other.
class SlotLayout {
  final ActivitySlot slot;
  final int columnIndex;
  final int columnCount;

  const SlotLayout({
    required this.slot,
    required this.columnIndex,
    required this.columnCount,
  });
}

/// Groups [slots] into clusters of mutually-overlapping slots (by time
/// range) and greedily packs each cluster into the fewest side-by-side
/// columns, à la calendar-app week views.
List<SlotLayout> computeOverlapLayout(List<ActivitySlot> slots) {
  final sorted = [...slots]..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
  final result = <SlotLayout>[];

  int i = 0;
  while (i < sorted.length) {
    var clusterEnd = sorted[i].endMinutes;
    var j = i + 1;
    while (j < sorted.length && sorted[j].startMinutes < clusterEnd) {
      if (sorted[j].endMinutes > clusterEnd) clusterEnd = sorted[j].endMinutes;
      j++;
    }

    final cluster = sorted.sublist(i, j);
    final columnEndTimes = <int>[];
    final columnOf = <ActivitySlot, int>{};

    for (final s in cluster) {
      var col = -1;
      for (var c = 0; c < columnEndTimes.length; c++) {
        if (columnEndTimes[c] <= s.startMinutes) {
          col = c;
          break;
        }
      }
      if (col == -1) {
        col = columnEndTimes.length;
        columnEndTimes.add(s.endMinutes);
      } else {
        columnEndTimes[col] = s.endMinutes;
      }
      columnOf[s] = col;
    }

    final columnCount = columnEndTimes.length;
    for (final s in cluster) {
      result.add(SlotLayout(slot: s, columnIndex: columnOf[s]!, columnCount: columnCount));
    }

    i = j;
  }

  return result;
}
