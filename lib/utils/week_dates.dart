// Shared date math for mapping the app's Mon(1)-Sun(7) dayOfWeek slots onto
// actual calendar dates within the current real-world week, so check-ins
// and completion badges can be tied to a specific date.

DateTime normalizeDate(DateTime date) => DateTime(date.year, date.month, date.day);

/// Midnight of the Monday that starts the current calendar week.
DateTime currentWeekStart() {
  final today = normalizeDate(DateTime.now());
  return today.subtract(Duration(days: today.weekday - 1));
}

/// The calendar date for [dayOfWeek] (1 = Monday ... 7 = Sunday) within the
/// week starting at [weekStart], defaulting to the current week.
DateTime dateForDayOfWeek(int dayOfWeek, {DateTime? weekStart}) {
  final start = weekStart ?? currentWeekStart();
  return start.add(Duration(days: dayOfWeek - 1));
}
