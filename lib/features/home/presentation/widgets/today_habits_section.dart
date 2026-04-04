import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:track/core/constants/animation_constants.dart';
import 'package:track/core/theme/app_colors.dart';
import 'package:track/features/habits/presentation/widgets/day_indicator.dart';

class TodayHabitsSection extends StatelessWidget {
  const TodayHabitsSection({
    required this.habits,
    required this.onToggle,
    required this.onSeeAll,
    super.key,
  });

  final List<HabitItem> habits;
  final void Function(String id) onToggle;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Habits",
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: onSeeAll,
                child: Text(
                  'See All',
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        ...List.generate(habits.length, (index) {
          return _HabitRow(
            habit: habits[index],
            onToggle: () => onToggle(habits[index].id),
            delay: Duration(
              milliseconds:
                  AnimationConstants.staggerDelay.inMilliseconds * index,
            ),
          );
        }),
      ],
    );
  }
}

class _HabitRow extends StatefulWidget {
  const _HabitRow({
    required this.habit,
    required this.onToggle,
    required this.delay,
  });

  final HabitItem habit;
  final VoidCallback onToggle;
  final Duration delay;

  @override
  State<_HabitRow> createState() => _HabitRowState();
}

class _HabitRowState extends State<_HabitRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: AnimationConstants.defaultDuration,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: AnimationConstants.enterCurve,
      ),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _slideController,
      curve: AnimationConstants.enterCurve,
    );

    Future.delayed(widget.delay, () {
      if (mounted) _slideController.forward();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final habit = widget.habit;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: widget.onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    _StatusIndicator(
                      status: habit.status,
                      color: habit.color,
                      progress: habit.progress,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        widget.onToggle();
                      },
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      habit.icon,
                      size: 20,
                      color:
                          habit.status == DayStatus.completed
                              ? colorScheme.onSurface.withValues(alpha: 0.4)
                              : colorScheme.onSurface,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        habit.name,
                        style: textTheme.bodyMedium?.copyWith(
                          decoration:
                              habit.status == DayStatus.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                          color:
                              habit.status == DayStatus.completed
                                  ? colorScheme.onSurface.withValues(alpha: 0.4)
                                  : habit.status == DayStatus.missed
                                  ? colorScheme.onSurface.withValues(alpha: 0.6)
                                  : colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (habit.subtitle != null)
                      Text(
                        habit.subtitle!,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tri-state indicator matching the DayIndicator visual style:
///   completed → green bg + white check
///   missed    → red bg + white X
///   neutral + progress → circular progress arc
///   neutral   → transparent bg + faint border (blank)
class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({
    required this.status,
    required this.color,
    required this.onTap,
    this.progress,
  });

  final DayStatus status;
  final Color color;
  final VoidCallback onTap;

  /// Progress fraction (0.0–1.0) for partial completion on measurable habits.
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final showProgress =
        status == DayStatus.neutral && progress != null && progress! > 0;

    final Color bgColor;
    final Color borderColor;
    final Widget? icon;

    switch (status) {
      case DayStatus.completed:
        bgColor = AppColors.success;
        borderColor = AppColors.success;
        icon = const Icon(Icons.check_rounded, size: 16, color: Colors.white);
      case DayStatus.missed:
        bgColor = AppColors.error;
        borderColor = AppColors.error;
        icon = const Icon(Icons.close_rounded, size: 16, color: Colors.white);
      case DayStatus.neutral:
        bgColor = Colors.transparent;
        borderColor = color.withValues(alpha: 0.3);
        icon = null;
    }

    return GestureDetector(
      onTap: onTap,
      child:
          showProgress
              ? CustomPaint(
                painter: _ProgressArcPainter(
                  progress: progress!,
                  color: color,
                  trackColor: color.withValues(alpha: 0.2),
                ),
                child: const SizedBox(width: 28, height: 28),
              )
              : AnimatedContainer(
                duration: AnimationConstants.defaultDuration,
                curve: AnimationConstants.defaultCurve,
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 2),
                ),
                child:
                    icon != null
                        ? AnimatedScale(
                          scale: 1,
                          duration: AnimationConstants.fast,
                          curve: AnimationConstants.enterCurve,
                          child: icon,
                        )
                        : null,
              ),
    );
  }
}

/// Paints a circular progress arc for partial completion.
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

class HabitItem {
  const HabitItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.status = DayStatus.neutral,
    this.progress,
    this.subtitle,
  });

  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final DayStatus status;

  /// Progress fraction (0.0–1.0) for partial completion on min-type measurable
  /// habits. When non-null and > 0, a circular progress arc is shown instead of
  /// the blank neutral circle.
  final double? progress;
  final String? subtitle;
}
