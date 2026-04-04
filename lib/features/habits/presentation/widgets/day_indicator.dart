import 'dart:math';

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
    this.progress,
    this.onTap,
    super.key,
  });

  /// Short day name, e.g. "Mon", or week label, e.g. "W14".
  final String dayLabel;

  /// Date number, e.g. "28".
  final String dateLabel;

  /// The completion status for this day.
  final DayStatus status;

  /// The habit's accent color (used for neutral outline and progress arc).
  final Color habitColor;

  /// Progress fraction (0.0–1.0) for partial completion on measurable habits.
  /// When non-null and > 0, a circular progress arc is drawn instead of the
  /// empty neutral circle.
  final double? progress;

  /// Tap callback. When null the indicator is not interactive.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    // If onTap is null, this day is disabled (not scheduled for custom frequency)
    final isDisabled = onTap == null;

    final Color bgColor;
    final Color borderColor;
    final Widget? icon;
    final showProgress =
        status == DayStatus.neutral && progress != null && progress! > 0;

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
        // Reduce opacity for disabled days
        borderColor = habitColor.withValues(alpha: isDisabled ? 0.1 : 0.3);
        icon = null;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dayLabel,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurface.withValues(
                alpha: isDisabled ? 0.25 : 0.5,
              ),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          if (showProgress)
            CustomPaint(
              painter: _ProgressArcPainter(
                progress: progress!,
                color: habitColor,
                trackColor: habitColor.withValues(alpha: 0.2),
              ),
              child: const SizedBox(width: 24, height: 24),
            )
          else
            AnimatedContainer(
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
          const SizedBox(height: 2),
          Text(
            dateLabel,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurface.withValues(
                alpha: isDisabled ? 0.2 : 0.4,
              ),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressArcPainter extends CustomPainter {
  _ProgressArcPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 4) / 2; // 2px stroke on each side
    const strokeWidth = 2.5;

    // Track (background arc)
    final trackPaint =
        Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final progressPaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;
    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ProgressArcPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor;
}
