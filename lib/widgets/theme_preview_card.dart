import 'package:flutter/material.dart';

import '../models/app_theme.dart';

/// Renders a mini mockup (task card + XP bar) using an [AppTheme]'s own
/// colors directly — not `Theme.of(context)` — so it can preview a theme
/// that isn't necessarily the one currently applied app-wide (a preset
/// swatch, or live edits in the custom theme builder before saving).
class ThemePreviewCard extends StatelessWidget {
  final AppTheme theme;

  const ThemePreviewCard({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    final background = Color(theme.background);
    final card = Color(theme.card);
    final primary = Color(theme.primary);
    final accent = Color(theme.accent);
    final textPrimary = Color(theme.textPrimary);
    final textSecondary = Color(theme.textSecondary);
    final streak = Color(theme.streakColor);
    final radius = BorderRadius.circular(theme.borderRadius);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: background, borderRadius: radius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: card, borderRadius: radius),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 34,
                  decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Sample task',
                        style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '9:00 AM - 10:00 AM',
                        style: TextStyle(color: textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
                  child: const Icon(Icons.check, size: 14, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.local_fire_department, size: 16, color: streak),
              const SizedBox(width: 4),
              Text(
                '5',
                style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const Spacer(),
              Text('Level 3', style: TextStyle(color: textSecondary, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: 0.6,
              minHeight: 8,
              backgroundColor: card,
              valueColor: AlwaysStoppedAnimation(primary),
            ),
          ),
        ],
      ),
    );
  }
}
