import '../models/activity_category.dart';

/// Snapshot of everything a badge condition might need, computed fresh by
/// `AchievementService` before each check — badges never read live service
/// state directly, so conditions stay simple, pure functions.
class BadgeStats {
  final int level;
  final int activityStreak;
  final int prayerStreak;
  final int totalCompletions;
  final Map<ActivityCategory, int> completionsByCategory;
  final bool hasEarlyBirdCompletion;
  final bool hasNightOwlCompletion;

  const BadgeStats({
    required this.level,
    required this.activityStreak,
    required this.prayerStreak,
    required this.totalCompletions,
    required this.completionsByCategory,
    required this.hasEarlyBirdCompletion,
    required this.hasNightOwlCompletion,
  });

  int forCategory(ActivityCategory category) => completionsByCategory[category] ?? 0;
}

class BadgeDefinition {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final bool Function(BadgeStats stats) isUnlocked;

  const BadgeDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.isUnlocked,
  });
}

const List<BadgeDefinition> kBadgeDefinitions = [
  BadgeDefinition(
    id: 'first_step',
    name: 'First Step',
    description: 'Complete your first activity',
    emoji: '🌱',
    isUnlocked: _firstStep,
  ),
  BadgeDefinition(
    id: 'week_one',
    name: 'Week One',
    description: 'Reach a 7-day activity streak',
    emoji: '📅',
    isUnlocked: _weekOne,
  ),
  BadgeDefinition(
    id: 'on_fire',
    name: 'On Fire',
    description: 'Reach a 14-day activity streak',
    emoji: '🔥',
    isUnlocked: _onFire,
  ),
  BadgeDefinition(
    id: 'gym_warrior',
    name: 'Gym Warrior',
    description: 'Complete 10 gym slots',
    emoji: '💪',
    isUnlocked: _gymWarrior,
  ),
  BadgeDefinition(
    id: 'content_king',
    name: 'Content King',
    description: 'Complete 10 content slots',
    emoji: '🎬',
    isUnlocked: _contentKing,
  ),
  BadgeDefinition(
    id: 'study_mode',
    name: 'Study Mode',
    description: 'Complete 20 study slots',
    emoji: '📚',
    isUnlocked: _studyMode,
  ),
  BadgeDefinition(
    id: 'early_bird',
    name: 'Early Bird',
    description: 'Complete a slot starting before 8 AM',
    emoji: '🌅',
    isUnlocked: _earlyBird,
  ),
  BadgeDefinition(
    id: 'night_owl',
    name: 'Night Owl',
    description: 'Complete a slot starting after 10 PM',
    emoji: '🦉',
    isUnlocked: _nightOwl,
  ),
  BadgeDefinition(
    id: 'mustaqim',
    name: 'Mustaqim',
    description: 'Reach a 7-day prayer streak (all 5 prayers)',
    emoji: '🕌',
    isUnlocked: _mustaqim,
  ),
  BadgeDefinition(
    id: 'istiqamah',
    name: 'Istiqamah',
    description: 'Reach a 30-day prayer streak',
    emoji: '⭐',
    isUnlocked: _istiqamah,
  ),
  BadgeDefinition(
    id: 'level_5',
    name: 'Level 5',
    description: 'Reach level 5',
    emoji: '🏅',
    isUnlocked: _level5,
  ),
  BadgeDefinition(
    id: 'level_10',
    name: 'Level 10',
    description: 'Reach level 10',
    emoji: '🥈',
    isUnlocked: _level10,
  ),
  BadgeDefinition(
    id: 'level_20',
    name: 'Level 20',
    description: 'Reach level 20',
    emoji: '🏆',
    isUnlocked: _level20,
  ),
];

bool _firstStep(BadgeStats s) => s.totalCompletions >= 1;
bool _weekOne(BadgeStats s) => s.activityStreak >= 7;
bool _onFire(BadgeStats s) => s.activityStreak >= 14;
bool _gymWarrior(BadgeStats s) => s.forCategory(ActivityCategory.gym) >= 10;
bool _contentKing(BadgeStats s) => s.forCategory(ActivityCategory.content) >= 10;
bool _studyMode(BadgeStats s) => s.forCategory(ActivityCategory.study) >= 20;
bool _earlyBird(BadgeStats s) => s.hasEarlyBirdCompletion;
bool _nightOwl(BadgeStats s) => s.hasNightOwlCompletion;
bool _mustaqim(BadgeStats s) => s.prayerStreak >= 7;
bool _istiqamah(BadgeStats s) => s.prayerStreak >= 30;
bool _level5(BadgeStats s) => s.level >= 5;
bool _level10(BadgeStats s) => s.level >= 10;
bool _level20(BadgeStats s) => s.level >= 20;
