import 'package:flutter/material.dart';

const List<String> kDayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class DayTabs extends StatelessWidget {
  final int selectedDay; // 1-7
  final ValueChanged<int> onDaySelected;
  final int todayDayOfWeek;

  const DayTabs({
    super.key,
    required this.selectedDay,
    required this.onDaySelected,
    required this.todayDayOfWeek,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 56,
      child: Row(
        children: List.generate(7, (index) {
          final day = index + 1;
          final isSelected = day == selectedDay;
          final isToday = day == todayDayOfWeek;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
              child: Material(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onDaySelected(day),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          kDayLabels[index],
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isToday
                                ? (isSelected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.primary)
                                : Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
