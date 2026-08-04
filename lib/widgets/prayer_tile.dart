import 'package:flutter/material.dart';

import '../services/prayer_service.dart';
import 'check_circle.dart';

/// Compact, auto-generated timeline entry for a single daily prayer.
/// Distinct from [ActivitySlotTile]: no edit/delete (prayers aren't user
/// data), just a mosque icon, name, time, and the same check-in circle.
class PrayerTile extends StatelessWidget {
  /// The prayer section's accent — the current theme's own accent color,
  /// so it stays in harmony with whatever theme (Ninja, Sunset, a custom
  /// one, ...) the user has picked, rather than a fixed emerald/teal.
  static Color accentOf(BuildContext context) => Theme.of(context).colorScheme.secondary;

  final PrayerActivity prayer;
  final bool isDone;
  final VoidCallback? onToggleDone;

  const PrayerTile({
    super.key,
    required this.prayer,
    required this.isDone,
    required this.onToggleDone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = accentOf(context);

    return Opacity(
      opacity: isDone ? 0.6 : 1.0,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            const Text('🕌', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    prayer.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: accent,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    prayer.time.format(context),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            CheckCircle(color: accent, isDone: isDone, onTap: onToggleDone),
          ],
        ),
      ),
    );
  }
}
