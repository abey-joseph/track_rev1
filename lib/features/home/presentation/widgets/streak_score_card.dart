import 'package:flutter/material.dart';
import 'package:track/core/constants/animation_constants.dart';

class StreakScoreCard extends StatelessWidget {
  const StreakScoreCard({
    required this.currentStreak,
    required this.habitsCompleted,
    required this.habitsTotal,
    super.key,
  });

  final int currentStreak;
  final int habitsCompleted;
  final int habitsTotal;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final progress =
        habitsTotal > 0 ? habitsCompleted / habitsTotal : 0.0;

    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Streak counter
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_fire_department_rounded,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                  Text(
                    '$currentStreak',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Progress section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$habitsCompleted of $habitsTotal habits done',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: AnimationConstants.slow,
                    curve: AnimationConstants.enterCurve,
                    builder: (context, value, _) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: value,
                          minHeight: 8,
                          backgroundColor:
                              colorScheme.primary.withValues(alpha: 0.15),
                          color: colorScheme.primary,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _motivationalText,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onPrimaryContainer.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _motivationalText {
    if (habitsCompleted == habitsTotal && habitsTotal > 0) {
      return 'All done! Amazing consistency.';
    }
    if (habitsCompleted == 0) {
      return 'Start your day strong!';
    }
    if (habitsCompleted >= habitsTotal / 2) {
      return 'Great progress! Keep going.';
    }
    return "You've got this!";
  }
}
