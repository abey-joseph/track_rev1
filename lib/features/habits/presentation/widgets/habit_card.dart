import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:track/core/extensions/context_extensions.dart';
import 'package:track/features/habits/domain/entities/habit_with_details.dart';
import 'package:track/features/habits/presentation/utils/habit_icon_resolver.dart';
import 'package:track/features/habits/presentation/widgets/day_indicator.dart';

class HabitCard extends StatelessWidget {
  const HabitCard({
    required this.habitWithDetails,
    required this.onTap,
    super.key,
  });

  final HabitWithDetails habitWithDetails;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final habit = habitWithDetails.habit;
    final streak = habitWithDetails.streak;
    final score = habitWithDetails.score;

    final habitColor = _parseColor(habit.colorHex);
    final icon = resolveHabitIcon(habit.iconName);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Top row: icon, name/streak, score
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: habitColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.name,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          streak.currentStreak > 0
                              ? '${streak.currentStreak} day streak 🔥'
                              : 'No active streak',
                          style: textTheme.bodySmall?.copyWith(
                            color:
                                colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Circular score indicator
                  _ScoreBadge(score: score, color: habitColor),
                ],
              ),
              const SizedBox(height: 14),
              // Day indicators row (last 7 days)
              _DaysRow(
                habitWithDetails: habitWithDetails,
                habitColor: habitColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    final buffer = StringBuffer();
    final cleaned = hex.startsWith('#') ? hex.substring(1) : hex;
    if (cleaned.length == 6) buffer.write('FF');
    buffer.write(cleaned);
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score, required this.color});

  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;

    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: score / 100,
            strokeWidth: 3,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation(color),
            strokeCap: StrokeCap.round,
          ),
          Text(
            '$score',
            style: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _DaysRow extends StatelessWidget {
  const _DaysRow({required this.habitWithDetails, required this.habitColor});

  final HabitWithDetails habitWithDetails;
  final Color habitColor;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final logDates =
        habitWithDetails.recentLogs.map((l) => l.loggedDate).toSet();
    final dayFormat = DateFormat('E'); // Mon, Tue, etc.

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (i) {
        // Show days from 6 days ago through today (left to right)
        final day = today.subtract(Duration(days: 6 - i));
        final iso =
            '${day.year.toString().padLeft(4, '0')}-'
            '${day.month.toString().padLeft(2, '0')}-'
            '${day.day.toString().padLeft(2, '0')}';
        final isCompleted = logDates.contains(iso);

        return DayIndicator(
          dayLabel: dayFormat.format(day).substring(0, 3),
          dateLabel: '${day.day}',
          isCompleted: isCompleted,
          habitColor: habitColor,
        );
      }),
    );
  }
}
