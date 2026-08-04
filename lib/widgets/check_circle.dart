import 'package:flutter/material.dart';

/// Shared circular check-in control used by [ActivitySlotTile] and
/// [PrayerTile]. Always placed as a SIBLING of any other tappable region in
/// the tile (never nested inside it) — nesting two tap-gesture recognizers
/// in the same hit-test region lets the outer one win the gesture arena,
/// silently swallowing taps meant for this circle.
class CheckCircle extends StatelessWidget {
  final Color color;
  final bool isDone;
  final VoidCallback? onTap;

  const CheckCircle({
    super.key,
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
