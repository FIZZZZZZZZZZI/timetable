import 'package:flutter/material.dart';

import '../data/badges.dart';
import '../models/activity_category.dart';
import '../services/achievement_service.dart';
import '../services/gamification_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _gamification = GamificationService.instance;
  final _achievements = AchievementService.instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _gamification.progress;
    final level = _gamification.currentLevel;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), centerTitle: false),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: CircularProgressIndicator(
                        value: _gamification.levelProgress,
                        strokeWidth: 10,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$level',
                          style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'LEVEL',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                '${progress.totalXp} XP total',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.local_fire_department,
                    iconColor: Colors.deepOrange,
                    label: 'Day streak',
                    value: '${progress.currentStreak}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    emoji: '🕌',
                    label: 'Prayer streak',
                    value: '${progress.prayerCurrentStreak}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text('Badges', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              '${_unlockedCount(_achievements)} / ${kBadgeDefinitions.length} unlocked',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              itemCount: kBadgeDefinitions.length,
              itemBuilder: (context, index) {
                final badge = kBadgeDefinitions[index];
                return _BadgeTile(badge: badge, unlocked: _achievements.isUnlocked(badge.id));
              },
            ),
            const SizedBox(height: 28),
            Text('Stats', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _StatsSummaryCard(
              totalCompletions: _achievements.totalCompletions,
              byCategory: _achievements.completionsByCategory,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  int _unlockedCount(AchievementService achievements) =>
      kBadgeDefinitions.where((b) => achievements.isUnlocked(b.id)).length;
}

class _StatCard extends StatelessWidget {
  final IconData? icon;
  final String? emoji;
  final Color? iconColor;
  final String label;
  final String value;

  const _StatCard({
    this.icon,
    this.emoji,
    this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          if (icon != null)
            Icon(icon, color: iconColor)
          else
            Text(emoji!, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final BadgeDefinition badge;
  final bool unlocked;

  const _BadgeTile({required this.badge, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: unlocked ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (unlocked)
            Text(badge.emoji, style: const TextStyle(fontSize: 30))
          else
            ColorFiltered(
              colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
              child: Opacity(
                opacity: 0.45,
                child: Text(badge.emoji, style: const TextStyle(fontSize: 30)),
              ),
            ),
          const SizedBox(height: 6),
          Text(
            badge.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: unlocked ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (!unlocked) ...[
            const SizedBox(height: 2),
            Text(
              badge.description,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatsSummaryCard extends StatelessWidget {
  final int totalCompletions;
  final Map<ActivityCategory, int> byCategory;

  const _StatsSummaryCard({required this.totalCompletions, required this.byCategory});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total completions',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          Text(
            '$totalCompletions',
            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          for (final category in ActivityCategory.values)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Text(category.emoji, style: const TextStyle(fontSize: 15)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(category.label, style: theme.textTheme.bodyMedium)),
                  Text(
                    '${byCategory[category] ?? 0}',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
