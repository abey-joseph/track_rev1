import 'package:flutter/material.dart';
import 'package:track/core/extensions/context_extensions.dart';

/// Radio-button style indicator for a single day's habit completion status.
class DayIndicator extends StatelessWidget {
  const DayIndicator({
    required this.dayLabel,
    required this.dateLabel,
    required this.isCompleted,
    required this.habitColor,
    super.key,
  });

  /// Short day name, e.g. "Mon".
  final String dayLabel;

  /// Date number, e.g. "28".
  final String dateLabel;

  /// Whether the habit was completed on this day.
  final bool isCompleted;

  /// The habit's accent color.
  final Color habitColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          dayLabel,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.5),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isCompleted ? habitColor : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: isCompleted
                  ? habitColor
                  : habitColor.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: isCompleted
              ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 2),
        Text(
          dateLabel,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.4),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
