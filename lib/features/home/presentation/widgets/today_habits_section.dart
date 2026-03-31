import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:track/core/constants/animation_constants.dart';

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
              milliseconds: AnimationConstants.staggerDelay.inMilliseconds *
                  index,
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
                    _AnimatedCheckbox(
                      isChecked: habit.isCompleted,
                      color: habit.color,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        widget.onToggle();
                      },
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      habit.icon,
                      size: 20,
                      color: habit.isCompleted
                          ? colorScheme.onSurface.withValues(alpha: 0.4)
                          : colorScheme.onSurface,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        habit.name,
                        style: textTheme.bodyMedium?.copyWith(
                          decoration: habit.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: habit.isCompleted
                              ? colorScheme.onSurface.withValues(alpha: 0.4)
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

class _AnimatedCheckbox extends StatelessWidget {
  const _AnimatedCheckbox({
    required this.isChecked,
    required this.color,
    required this.onTap,
  });

  final bool isChecked;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AnimationConstants.defaultDuration,
        curve: AnimationConstants.defaultCurve,
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isChecked ? color : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isChecked ? color : color.withValues(alpha: 0.4),
            width: 2,
          ),
        ),
        child: AnimatedScale(
          scale: isChecked ? 1.0 : 0.0,
          duration: AnimationConstants.fast,
          curve: AnimationConstants.enterCurve,
          child: Icon(
            Icons.check_rounded,
            size: 18,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}

class HabitItem {
  const HabitItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isCompleted = false,
    this.subtitle,
  });

  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final bool isCompleted;
  final String? subtitle;
}
