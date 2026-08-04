import 'package:flutter/material.dart';

import '../models/activity_category.dart';
import '../models/activity_slot.dart';

class ActivitySlotTile extends StatelessWidget {
  final ActivitySlot slot;
  final bool isOngoing;
  final bool isDone;
  final VoidCallback onTap;
  final VoidCallback onDismissed;
  final VoidCallback? onToggleDone;

  const ActivitySlotTile({
    super.key,
    required this.slot,
    required this.isOngoing,
    required this.isDone,
    required this.onTap,
    required this.onDismissed,
    required this.onToggleDone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = slot.category.color;

    return Dismissible(
      key: ValueKey(slot.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline, color: theme.colorScheme.onErrorContainer),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isOngoing
              ? color.withValues(alpha: 0.14)
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: isOngoing ? Border.all(color: color, width: 1.5) : null,
        ),
        // The check circle is a SIBLING of the edit InkWell below, not a
        // descendant of it. Nesting it inside the edit InkWell put two
        // tap-gesture recognizers in the same hit-test region, and the
        // outer one was winning the gesture arena — so taps on the check
        // circle never reached its own onTap. Keeping them side-by-side in
        // this Row removes the overlap entirely.
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Opacity(
                opacity: isDone ? 0.6 : 1.0,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 4,
                            height: 52,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        slot.title,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          decoration: isDone
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isOngoing)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Text(
                                          'NOW',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${slot.startTime.format(context)} - ${slot.endTime.format(context)}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                if (slot.location != null &&
                                    slot.location!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(Icons.place_outlined,
                                          size: 14,
                                          color: theme.colorScheme.onSurfaceVariant),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          slot.location!,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (slot.notes != null && slot.notes!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    slot.notes!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(slot.category.icon, size: 16, color: color),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _CheckCircle(
                color: color,
                isDone: isDone,
                onTap: onToggleDone,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckCircle extends StatelessWidget {
  final Color color;
  final bool isDone;
  final VoidCallback? onTap;

  const _CheckCircle({
    required this.color,
    required this.isDone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDone ? color : Colors.transparent,
      shape: CircleBorder(side: BorderSide(color: color, width: 2)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          // At least 44x44 so the tap target meets the platform minimum
          // touch-size guidance instead of the visual 28px circle alone.
          width: 44,
          height: 44,
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 20, color: Colors.white)
                : null,
          ),
        ),
      ),
    );
  }
}
