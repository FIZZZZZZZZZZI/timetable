import 'package:flutter/material.dart';

/// Compact header card for the daily view: current level, XP progress
/// toward the next level, and the day-streak counter.
class ProgressHeaderCard extends StatelessWidget {
  final int level;
  final int xpIntoLevel;
  final int xpForNextLevel;
  final double levelProgress;
  final int currentStreak;
  final int prayerStreak;

  const ProgressHeaderCard({
    super.key,
    required this.level,
    required this.xpIntoLevel,
    required this.xpForNextLevel,
    required this.levelProgress,
    required this.currentStreak,
    required this.prayerStreak,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              '$level',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Level $level',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$xpIntoLevel / $xpForNextLevel XP',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: levelProgress,
                    minHeight: 6,
                    backgroundColor: theme.colorScheme.surface,
                    valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_fire_department,
                color: currentStreak > 0
                    ? Colors.deepOrange
                    : theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.4),
              ),
              Text(
                '$currentStreak',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: prayerStreak > 0 ? 1.0 : 0.4,
                child: const Text('🕌', style: TextStyle(fontSize: 20)),
              ),
              Text(
                '$prayerStreak',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
