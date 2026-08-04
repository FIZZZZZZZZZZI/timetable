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

  @HiveField(5, defaultValue: 0)
  int prayerCurrentStreak;

  @HiveField(6, defaultValue: 0)
  int prayerLongestStreak;

  @HiveField(7)
  DateTime? lastPrayerCompletedDate;

  /// Calendar dates ('yyyy-MM-dd') that already received the "completed
  /// all 5 prayers that day" bonus.
  @HiveField(8, defaultValue: <String>[])
  List<String> prayerBonusDates;

  UserProgress({
    this.totalXp = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastCompletedDate,
    List<String>? bonusDates,
    this.prayerCurrentStreak = 0,
    this.prayerLongestStreak = 0,
    this.lastPrayerCompletedDate,
    List<String>? prayerBonusDates,
  })  : bonusDates = bonusDates ?? <String>[],
        prayerBonusDates = prayerBonusDates ?? <String>[];
}
