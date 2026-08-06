import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/badges.dart';
import '../data/theme_presets.dart';
import '../models/activity_category.dart';
import '../models/app_theme.dart';
import '../services/achievement_service.dart';
import '../services/auth_service.dart';
import '../services/gamification_service.dart';
import '../services/theme_service.dart';
import '../utils/app_theme_data.dart';
import 'theme_editor_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _gamification = GamificationService.instance;
  final _achievements = AchievementService.instance;
  final _themes = ThemeService.instance;
  final _auth = AuthService.instance;

  Future<void> _confirmSignOut() async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You can sign back in anytime with the same Google account. '
          'Your local data stays on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Sign out', style: TextStyle(color: theme.colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      // AuthGate's authStateChanges stream swaps to the login screen once
      // this completes — no manual navigation needed here.
      await _auth.signOut();
    }
  }

  Future<void> _selectTheme(String id) async {
    await _themes.selectTheme(id);
    if (mounted) setState(() {});
  }

  Future<void> _openEditor({AppTheme? existing}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => ThemeEditorScreen(existing: existing)),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _gamification.progress;
    final level = _gamification.currentLevel;
    final streakColor =
        theme.extension<AppColorsExtension>()?.streakColor ?? Colors.deepOrange;
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), centerTitle: false),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (user != null) ...[
              _UserHeaderCard(user: user, onSignOut: _confirmSignOut),
              const SizedBox(height: 20),
            ],
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
                    iconColor: streakColor,
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
            const SizedBox(height: 28),
            Text('Themes', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            for (final preset in _themes.presets)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ThemeCard(
                  appTheme: preset,
                  isActive: preset.id == _themes.selectedThemeId,
                  requiredLevel: kPresetUnlockLevels[preset.id] ?? 1,
                  currentLevel: level,
                  onSelect: () => _selectTheme(preset.id),
                ),
              ),
            for (final custom in _themes.customThemes)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ThemeCard(
                  appTheme: custom,
                  isActive: custom.id == _themes.selectedThemeId,
                  requiredLevel: kCustomThemeUnlockLevel,
                  currentLevel: level,
                  onSelect: () => _selectTheme(custom.id),
                  onEdit: () => _openEditor(existing: custom),
                ),
              ),
            _CreateThemeCard(
              unlocked: level >= kCustomThemeUnlockLevel,
              requiredLevel: kCustomThemeUnlockLevel,
              onTap: () => _openEditor(),
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

class _UserHeaderCard extends StatelessWidget {
  final User user;
  final VoidCallback onSignOut;

  const _UserHeaderCard({required this.user, required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photoUrl = user.photoURL;
    final email = user.email;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: theme.colorScheme.primaryContainer,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null
                ? Icon(Icons.person, color: theme.colorScheme.onPrimaryContainer)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName ?? 'Signed in',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (email != null)
                  Text(
                    email,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: onSignOut,
          ),
        ],
      ),
    );
  }
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

class _ThemeCard extends StatelessWidget {
  final AppTheme appTheme;
  final bool isActive;
  final int requiredLevel;
  final int currentLevel;
  final VoidCallback onSelect;
  final VoidCallback? onEdit;

  const _ThemeCard({
    required this.appTheme,
    required this.isActive,
    required this.requiredLevel,
    required this.currentLevel,
    required this.onSelect,
    this.onEdit,
  });

  bool get _isLocked => currentLevel < requiredLevel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locked = _isLocked;

    return Opacity(
      opacity: locked ? 0.55 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? theme.colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: locked ? null : onSelect,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        appTheme.name,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (locked)
                      Icon(Icons.lock_outline, size: 18, color: theme.colorScheme.onSurfaceVariant)
                    else ...[
                      if (isActive)
                        Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 20),
                      if (onEdit != null)
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Edit theme',
                          onPressed: onEdit,
                        ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 26,
                    child: Row(
                      children: [
                        appTheme.background,
                        appTheme.card,
                        appTheme.primary,
                        appTheme.accent,
                        appTheme.streakColor,
                      ].map((argb) => Expanded(child: Container(color: Color(argb)))).toList(),
                    ),
                  ),
                ),
                if (locked) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Unlocks at Level $requiredLevel',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateThemeCard extends StatelessWidget {
  final bool unlocked;
  final int requiredLevel;
  final VoidCallback onTap;

  const _CreateThemeCard({
    required this.unlocked,
    required this.requiredLevel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: unlocked ? 1.0 : 0.55,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: unlocked ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  unlocked ? Icons.add_circle_outline : Icons.lock_outline,
                  color: unlocked ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create custom theme',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (!unlocked)
                        Text(
                          'Unlocks at Level $requiredLevel',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
