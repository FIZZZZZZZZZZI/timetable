import 'dart:math';

import 'package:hive_flutter/hive_flutter.dart';

import '../data/badges.dart';
import '../models/activity_slot.dart';
import '../models/user_progress.dart';
import '../utils/week_dates.dart';
import 'achievement_service.dart';
import 'completion_service.dart';
import 'prayer_service.dart';

/// Outcome of a single XP-earning action, so the UI knows whether to pop a
/// level-up celebration and/or any badge-unlock celebrations.
class GamificationResult {
  final bool leveledUp;
  final int newLevel;
  final List<BadgeDefinition> newlyUnlockedBadges;

  const GamificationResult({
    required this.leveledUp,
    required this.newLevel,
    this.newlyUnlockedBadges = const [],
  });
}

/// Tracks XP, level and streak state. Pure service layer: no BuildContext,
/// no widgets — the UI reacts to [GamificationResult] instead.
class GamificationService {
  GamificationService._();
  static final GamificationService instance = GamificationService._();

  static const String _boxName = 'user_progress';
  static const String _key = 'progress';

  static const int xpPerSlot = 10;
  static const int dailyBonusXp = 20;

  static const int xpPerPrayer = 5;
  static const int allPrayersBonusXp = 25;

  final CompletionService _completion = CompletionService.instance;
  final AchievementService _achievements = AchievementService.instance;

  late Box<UserProgress> _box;

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(UserProgressAdapter());
    }
    _box = await Hive.openBox<UserProgress>(_boxName);
    if (!_box.containsKey(_key)) {
      await _box.put(_key, UserProgress());
    }
    // Recompute on every app start too, so a streak correctly shows as
    // broken after the app was closed over a skipped day, not just after
    // the next mark/unmark action.
    await _recomputeStreak();
    await _recomputePrayerStreak();
  }

  UserProgress get progress => _box.get(_key)!;

  int levelForXp(int xp) => sqrt(xp / 50).floor() + 1;

  /// Minimum total XP required to be at [level].
  int xpForLevel(int level) => 50 * (level - 1) * (level - 1);

  int get currentLevel => levelForXp(progress.totalXp);

  int get xpIntoLevel => progress.totalXp - xpForLevel(currentLevel);

  int get xpForNextLevel => xpForLevel(currentLevel + 1) - xpForLevel(currentLevel);

  double get levelProgress =>
      xpForNextLevel == 0 ? 1.0 : (xpIntoLevel / xpForNextLevel).clamp(0.0, 1.0);

  /// Call after [CompletionService.markDone] succeeds. [allSlotsForDate]
  /// should be every slot scheduled on [date]'s day of week, used to check
  /// whether the daily-completion bonus is now earned.
  Future<GamificationResult> onSlotMarkedDone({
    required String slotId,
    required DateTime date,
    required List<ActivitySlot> allSlotsForDate,
  }) async {
    final p = progress;
    final levelBefore = levelForXp(p.totalXp);

    p.totalXp += xpPerSlot;

    final dateKey = _dateKey(date);
    final allDone =
        allSlotsForDate.isNotEmpty && allSlotsForDate.every((s) => _completion.isDone(s.id, date));
    if (allDone && !p.bonusDates.contains(dateKey)) {
      p.totalXp += dailyBonusXp;
      p.bonusDates = [...p.bonusDates, dateKey];
    }

    final normalized = normalizeDate(date);
    if (p.lastCompletedDate == null || normalized.isAfter(p.lastCompletedDate!)) {
      p.lastCompletedDate = normalized;
    }

    await p.save();
    await _recomputeStreak();

    final levelAfter = levelForXp(p.totalXp);
    final newBadges = await _achievements.checkAndUnlock(
      level: levelAfter,
      activityStreak: p.currentStreak,
      prayerStreak: p.prayerCurrentStreak,
    );
    return GamificationResult(
      leveledUp: levelAfter > levelBefore,
      newLevel: levelAfter,
      newlyUnlockedBadges: newBadges,
    );
  }

  /// Call after [CompletionService.unmarkDone] succeeds, mirroring
  /// [onSlotMarkedDone]: removes the slot's XP and claws back the daily
  /// bonus if the day no longer qualifies.
  Future<void> onSlotUnmarkedDone({
    required String slotId,
    required DateTime date,
    required List<ActivitySlot> allSlotsForDate,
  }) async {
    final p = progress;

    p.totalXp -= xpPerSlot;
    if (p.totalXp < 0) p.totalXp = 0;

    final dateKey = _dateKey(date);
    final stillAllDone =
        allSlotsForDate.isNotEmpty && allSlotsForDate.every((s) => _completion.isDone(s.id, date));
    if (!stillAllDone && p.bonusDates.contains(dateKey)) {
      p.totalXp -= dailyBonusXp;
      if (p.totalXp < 0) p.totalXp = 0;
      p.bonusDates = p.bonusDates.where((d) => d != dateKey).toList();
    }

    await p.save();
    await _recomputeStreak();
  }

  /// Recomputes the current streak from actual completion data (rather
  /// than patching a running counter), so retroactive past-day check-ins,
  /// un-marks, and app-reopen-after-a-gap all resolve to the correct value.
  Future<void> _recomputeStreak() async {
    final p = progress;
    final today = normalizeDate(DateTime.now());

    var streak = 0;
    var cursor = today;
    while (_completion.hasAnyCompletionOn(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    p.currentStreak = streak;
    if (streak > p.longestStreak) {
      p.longestStreak = streak;
    }

    final mostRecent = _completion.mostRecentCompletionDate();
    if (mostRecent != null) {
      p.lastCompletedDate = mostRecent;
    }

    await p.save();
  }

  /// Call after [CompletionService.markDone] for a prayer id
  /// (`PrayerService.prayerIds`) succeeds. Mirrors [onSlotMarkedDone] but
  /// with its own XP amounts, bonus tracking and streak, since prayers are
  /// a separate concern from regular activity slots.
  Future<GamificationResult> onPrayerMarkedDone({
    required String prayerId,
    required DateTime date,
  }) async {
    final p = progress;
    final levelBefore = levelForXp(p.totalXp);

    p.totalXp += xpPerPrayer;

    final dateKey = _dateKey(date);
    final allDone = PrayerService.prayerIds.every((id) => _completion.isDone(id, date));
    if (allDone && !p.prayerBonusDates.contains(dateKey)) {
      p.totalXp += allPrayersBonusXp;
      p.prayerBonusDates = [...p.prayerBonusDates, dateKey];
    }

    final normalized = normalizeDate(date);
    if (p.lastPrayerCompletedDate == null || normalized.isAfter(p.lastPrayerCompletedDate!)) {
      p.lastPrayerCompletedDate = normalized;
    }

    await p.save();
    await _recomputePrayerStreak();

    final levelAfter = levelForXp(p.totalXp);
    final newBadges = await _achievements.checkAndUnlock(
      level: levelAfter,
      activityStreak: p.currentStreak,
      prayerStreak: p.prayerCurrentStreak,
    );
    return GamificationResult(
      leveledUp: levelAfter > levelBefore,
      newLevel: levelAfter,
      newlyUnlockedBadges: newBadges,
    );
  }

  /// Call after [CompletionService.unmarkDone] for a prayer id succeeds.
  Future<void> onPrayerUnmarkedDone({
    required String prayerId,
    required DateTime date,
  }) async {
    final p = progress;

    p.totalXp -= xpPerPrayer;
    if (p.totalXp < 0) p.totalXp = 0;

    final dateKey = _dateKey(date);
    final stillAllDone = PrayerService.prayerIds.every((id) => _completion.isDone(id, date));
    if (!stillAllDone && p.prayerBonusDates.contains(dateKey)) {
      p.totalXp -= allPrayersBonusXp;
      if (p.totalXp < 0) p.totalXp = 0;
      p.prayerBonusDates = p.prayerBonusDates.where((d) => d != dateKey).toList();
    }

    await p.save();
    await _recomputePrayerStreak();
  }

  /// Consecutive days (ending today) where all 5 prayers were completed.
  Future<void> _recomputePrayerStreak() async {
    final p = progress;
    final today = normalizeDate(DateTime.now());

    var streak = 0;
    var cursor = today;
    while (PrayerService.prayerIds.every((id) => _completion.isDone(id, cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    p.prayerCurrentStreak = streak;
    if (streak > p.prayerLongestStreak) {
      p.prayerLongestStreak = streak;
    }

    await p.save();
  }

  String _dateKey(DateTime date) {
    final d = normalizeDate(date);
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
