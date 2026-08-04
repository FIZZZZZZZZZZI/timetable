import 'package:hive_flutter/hive_flutter.dart';

import '../data/badges.dart';
import '../models/achievement.dart';
import '../models/activity_category.dart';
import '../models/activity_slot.dart';
import 'completion_service.dart';
import 'storage_service.dart';

/// Checks badge conditions and persists unlocks. Also the home for the
/// completion stats (total completions, per-category breakdown) those
/// conditions — and the Profile screen — need, since both read the same
/// completion/slot data. Pure service layer: no BuildContext, no widgets.
///
/// Badges are permanent once unlocked: earning one is never re-evaluated
/// or revoked later (e.g. if a streak that earned a badge later breaks),
/// matching how achievement systems conventionally behave.
class AchievementService {
  AchievementService._();
  static final AchievementService instance = AchievementService._();

  static const String _boxName = 'achievements';
  static const int _earlyBirdCutoffMinutes = 8 * 60;
  static const int _nightOwlCutoffMinutes = 22 * 60;

  final StorageService _storage = StorageService.instance;
  final CompletionService _completion = CompletionService.instance;

  late Box<Achievement> _box;

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(AchievementAdapter());
    }
    _box = await Hive.openBox<Achievement>(_boxName);
  }

  bool isUnlocked(String badgeId) => _box.containsKey(badgeId);

  Achievement? unlockedRecord(String badgeId) => _box.get(badgeId);

  /// Checks every not-yet-unlocked badge against current stats plus the
  /// level/streak values [level]/[activityStreak]/[prayerStreak] (owned by
  /// `GamificationService`, passed in rather than read directly to avoid a
  /// dependency cycle), persisting and returning any newly earned ones.
  Future<List<BadgeDefinition>> checkAndUnlock({
    required int level,
    required int activityStreak,
    required int prayerStreak,
  }) async {
    final stats = BadgeStats(
      level: level,
      activityStreak: activityStreak,
      prayerStreak: prayerStreak,
      totalCompletions: totalCompletions,
      completionsByCategory: completionsByCategory,
      hasEarlyBirdCompletion: hasEarlyBirdCompletion,
      hasNightOwlCompletion: hasNightOwlCompletion,
    );

    final newlyUnlocked = <BadgeDefinition>[];
    for (final badge in kBadgeDefinitions) {
      if (isUnlocked(badge.id)) continue;
      if (badge.isUnlocked(stats)) {
        await _box.put(badge.id, Achievement(id: badge.id, unlockedAt: DateTime.now()));
        newlyUnlocked.add(badge);
      }
    }
    return newlyUnlocked;
  }

  // ---------------------------------------------------------------------
  // Stats (badge conditions + Profile screen)
  // ---------------------------------------------------------------------

  /// Every completed activity slot occurrence (prayer completions
  /// excluded — those aren't categorized), resolved from raw completion
  /// records back to their still-existing [ActivitySlot]. A slot that's
  /// since been deleted cascades away its completion records too (see
  /// `StorageService.deleteSlot`), so every record here always resolves.
  List<ActivitySlot> get _completedActivitySlots {
    final slotsById = {for (final s in _storage.getAll()) s.id: s};
    final result = <ActivitySlot>[];
    for (final record in _completion.getAll()) {
      if (record.slotId.startsWith('prayer_')) continue;
      final slot = slotsById[record.slotId];
      if (slot != null) result.add(slot);
    }
    return result;
  }

  int get totalCompletions => _completedActivitySlots.length;

  Map<ActivityCategory, int> get completionsByCategory {
    final map = <ActivityCategory, int>{};
    for (final slot in _completedActivitySlots) {
      map[slot.category] = (map[slot.category] ?? 0) + 1;
    }
    return map;
  }

  bool get hasEarlyBirdCompletion =>
      _completedActivitySlots.any((s) => s.startMinutes < _earlyBirdCutoffMinutes);

  bool get hasNightOwlCompletion =>
      _completedActivitySlots.any((s) => s.startMinutes >= _nightOwlCutoffMinutes);
}
