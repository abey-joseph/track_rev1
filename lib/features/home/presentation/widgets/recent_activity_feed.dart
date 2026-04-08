import 'package:flutter/material.dart';
import 'package:track/core/constants/animation_constants.dart';

class RecentActivityFeed extends StatelessWidget {
  const RecentActivityFeed({
    required this.activities,
    super.key,
  });

  final List<ActivityItem> activities;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Recent Activity',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(activities.length, (index) {
          return _ActivityRow(
            activity: activities[index],
            isLast: index == activities.length - 1,
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

class _ActivityRow extends StatefulWidget {
  const _ActivityRow({
    required this.activity,
    required this.isLast,
    required this.delay,
  });

  final ActivityItem activity;
  final bool isLast;
  final Duration delay;

  @override
  State<_ActivityRow> createState() => _ActivityRowState();
}

class _ActivityRowState extends State<_ActivityRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AnimationConstants.defaultDuration,
    );
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final activity = widget.activity;

    final iconColor = switch (activity.type) {
      ActivityType.habitCompletion => colorScheme.primary,
      ActivityType.expense => colorScheme.error,
      ActivityType.income => colorScheme.tertiary,
    };

    final icon = switch (activity.type) {
      ActivityType.habitCompletion => Icons.check_circle_rounded,
      ActivityType.expense => Icons.remove_circle_outline,
      ActivityType.income => Icons.add_circle_outline,
    };

    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _controller,
        curve: AnimationConstants.enterCurve,
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: AnimationConstants.enterCurve,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              // Time
              SizedBox(
                width: 52,
                child: Text(
                  activity.time,
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
              // Icon
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 10),
              // Title
              Expanded(
                child: Text(
                  activity.title,
                  style: textTheme.bodyMedium,
                ),
              ),
              // Subtitle (amount for transactions)
              if (activity.subtitle != null)
                Text(
                  activity.subtitle!,
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: iconColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

enum ActivityType { habitCompletion, expense, income }

class ActivityItem {
  const ActivityItem({
    required this.time,
    required this.title,
    required this.type,
    this.subtitle,
  });

  final String time;
  final String title;
  final ActivityType type;
  final String? subtitle;
}
