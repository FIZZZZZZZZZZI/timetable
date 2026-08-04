import 'package:hive/hive.dart';

part 'user_progress.g.dart';

/// Singleton record (single key in its own box) tracking XP/level/streak
/// state for the whole app — there's only ever one user.
@HiveType(typeId: 4)
class UserProgress extends HiveObject {
  @HiveField(0)
  int totalXp;

  @HiveField(1)
  int currentStreak;

  @HiveField(2)
  int longestStreak;

  @HiveField(3)
  DateTime? lastCompletedDate;

  /// Calendar dates ('yyyy-MM-dd') that already received the "completed
  /// every slot that day" bonus, so it's never paid out twice for the
  /// same date.
  @HiveField(4, defaultValue: <String>[])
  List<String> bonusDates;

  UserProgress({
    this.totalXp = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastCompletedDate,
    List<String>? bonusDates,
  }) : bonusDates = bonusDates ?? <String>[];
}
