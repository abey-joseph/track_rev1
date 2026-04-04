import 'package:flutter/material.dart';
import 'package:track/core/extensions/context_extensions.dart';
import 'package:track/core/theme/app_colors.dart';

/// Tri-state status for a single day's habit completion.
enum DayStatus { completed, missed, neutral }

/// Radio-button style indicator for a single day's habit completion status.
class DayIndicator extends StatelessWidget {
  const DayIndicator({
    required this.dayLabel,
    required this.dateLabel,
    required this.status,
    required this.habitColor,
    this.onTap,
    super.key,
  });

  /// Short day name, e.g. "Mon".
  final String dayLabel;

  /// Date number, e.g. "28".
  final String dateLabel;

  /// The completion status for this day.
  final DayStatus status;

  /// The habit's accent color (used for neutral outline).
  final Color habitColor;

  /// Tap callback. When null the indicator is not interactive.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    final Color bgColor;
    final Color borderColor;
    final Widget? icon;

    switch (status) {
      case DayStatus.completed:
        bgColor = AppColors.success;
        borderColor = AppColors.success;
        icon = const Icon(Icons.check_rounded, size: 14, color: Colors.white);
      case DayStatus.missed:
        bgColor = AppColors.error;
        borderColor = AppColors.error;
        icon = const Icon(Icons.close_rounded, size: 14, color: Colors.white);
      case DayStatus.neutral:
        bgColor = Colors.transparent;
        borderColor = habitColor.withValues(alpha: 0.3);
        icon = null;
    }

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
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 2),
            ),
            child: icon,
          ),
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
