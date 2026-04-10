import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:track/core/extensions/context_extensions.dart';
import 'package:track/features/habits/domain/entities/habit_entity.dart';
import 'package:track/features/habits/domain/entities/habit_with_details.dart';
import 'package:track/features/habits/domain/helpers/completion_helpers.dart';
import 'package:track/features/habits/presentation/bloc/habits_bloc.dart';
import 'package:track/features/habits/presentation/bloc/habits_event.dart';
import 'package:track/features/habits/presentation/utils/habit_icon_resolver.dart';
import 'package:track/features/habits/presentation/widgets/day_indicator.dart';
import 'package:track/features/habits/presentation/widgets/measurable_log_sheet.dart';

class HabitCard extends StatelessWidget {
  const HabitCard({
    required this.habitWithDetails,
    required this.onTap,
    this.onDelete,
    super.key,
  });

  final HabitWithDetails habitWithDetails;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final habit = habitWithDetails.habit;
    final streak = habitWithDetails.streak;
    final score = habitWithDetails.score;

    final habitColor = _parseColor(habit.colorHex);
    final icon = resolveHabitIcon(habit.iconName);

    return GestureDetector(
      onLongPress:
          onDelete == null
              ? null
              : () async {
                await HapticFeedback.mediumImpact();
                if (!context.mounted) return;
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder:
                      (ctx) => AlertDialog(
                        title: const Text('Delete habit?'),
                        content: Text(
                          'Are you sure you want to delete "${habit.name}"? This will remove all its logs and cannot be undone.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: Text(
                              'Delete',
                              style: TextStyle(color: colorScheme.error),
                            ),
                          ),
                        ],
                      ),
                );
                if (confirmed == true) onDelete!();
              },
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: colorScheme.surfaceContainerLow,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Top row: tappable area that navigates to detail
              InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: Row(
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
                                ? '${streak.currentStreak} ${habit.frequencyType == HabitFrequency.weekly ? 'week' : 'day'} streak \u{1F525}'
                                : 'No active streak',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Circular score indicator
                    _ScoreBadge(score: score, color: habitColor),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Day/Week indicators row — outside InkWell so each is tappable
              if (habit.frequencyType == HabitFrequency.weekly)
                _WeeksRow(
                  habitWithDetails: habitWithDetails,
                  habitColor: habitColor,
                )
              else
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
    final dayFormat = DateFormat('E'); // Mon, Tue, etc.

    final habit = habitWithDetails.habit;
    final scheduledDays = habit.frequencyDays.toSet();

    // Build a map of date -> log value for quick lookup
    final logMap = <String, double>{};
    for (final log in habitWithDetails.recentLogs) {
      logMap[log.loggedDate] = log.value;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (i) {
        // Show days from 6 days ago through today (left to right)
        final day = today.subtract(Duration(days: 6 - i));
        final iso =
            '${day.year.toString().padLeft(4, '0')}-'
            '${day.month.toString().padLeft(2, '0')}-'
            '${day.day.toString().padLeft(2, '0')}';
        final isToday = day == today;
        final isScheduled = scheduledDays.contains(day.weekday);
        final logValue = logMap[iso]; // null = no log

        final DayStatus status;
        double? progress;
        final threshold = habit.targetValue;
        final targetType = habit.targetType;
        final isMeasurable = threshold > 1.0;

        if (logValue != null &&
            isHabitCompleted(logValue, threshold, targetType)) {
          // Meets target → done (green)
          status = DayStatus.completed;
        } else if (logValue != null &&
            logValue > 0 &&
            isMeasurable &&
            targetType == HabitTargetType.min) {
          // Partial progress on min-type measurable → show circle progress
          progress = completionProgress(logValue, threshold, targetType);
          status = DayStatus.neutral;
        } else if (logValue != null && logValue < 1.0) {
          // Explicitly logged as 0 → not done (red)
          status = DayStatus.missed;
        } else if (logValue != null &&
            isMeasurable &&
            targetType == HabitTargetType.max) {
          // Max-type measurable with value > target → failed (red)
          status = DayStatus.missed;
        } else if (!isToday && isScheduled) {
          // Past scheduled day with no log → not done (red)
          status = DayStatus.missed;
        } else if (isToday && isScheduled) {
          // Today with no log → neutral (blank)
          status = DayStatus.neutral;
        } else {
          // Not a scheduled day → neutral
          status = DayStatus.neutral;
        }

        return DayIndicator(
          dayLabel: dayFormat.format(day).substring(0, 3),
          dateLabel: '${day.day}',
          status: status,
          habitColor: habitColor,
          progress: progress,
          onTap:
              isScheduled
                  ? () async {
                    await HapticFeedback.lightImpact();
                    if (habit.targetValue > 1.0) {
                      // Measurable habit: show bottom sheet
                      if (!context.mounted) return;
                      final result =
                          await showModalBottomSheet<MeasurableLogResult>(
                            context: context,
                            isScrollControlled: true,
                            builder:
                                (_) => MeasurableLogSheet(
                                  habitName: habit.name,
                                  targetValue: habit.targetValue,
                                  targetUnit: habit.targetUnit,
                                  targetType: habit.targetType,
                                  currentValue: logValue,
                                ),
                          );
                      if (result == null || !context.mounted) return;
                      if (result.delete) {
                        context.read<HabitsBloc>().add(
                          HabitsEvent.deleteLog(habitId: habit.id, date: iso),
                        );
                      } else if (result.value != null) {
                        context.read<HabitsBloc>().add(
                          HabitsEvent.logValue(
                            habitId: habit.id,
                            date: iso,
                            value: result.value!,
                          ),
                        );
                      }
                    } else {
                      if (!context.mounted) return;
                      // Yes/No habit: toggle
                      // Yes/No habit
                      if (isToday) {
                        // Today: use 3-state toggle (done → failed → neutral)
                        context.read<HabitsBloc>().add(
                          HabitsEvent.toggleLog(habitId: habit.id, date: iso),
                        );
                      } else {
                        // Past days: use 2-state toggle (done ↔ failed)
                        // This avoids the invisible "no log = red" state that
                        // makes it look like nothing changed on the first tap.
                        final isDone = logValue != null && logValue >= 1.0;
                        context.read<HabitsBloc>().add(
                          HabitsEvent.logValue(
                            habitId: habit.id,
                            date: iso,
                            value: isDone ? 0.0 : 1.0,
                          ),
                        );
                      }
                    }
                  }
                  : null,
        );
      }),
    );
  }
}

class _WeeksRow extends StatelessWidget {
  const _WeeksRow({required this.habitWithDetails, required this.habitColor});

  final HabitWithDetails habitWithDetails;
  final Color habitColor;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentMonday = _mondayOfWeek(today);

    final habit = habitWithDetails.habit;

    // Build a map of date -> log value for quick lookup
    final logMap = <String, double>{};
    for (final log in habitWithDetails.recentLogs) {
      logMap[log.loggedDate] = log.value;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (i) {
        // Show weeks from 6 weeks ago through current week (left to right)
        final weekMonday = currentMonday.subtract(Duration(days: (6 - i) * 7));
        final isCurrentWeek = weekMonday == currentMonday;
        final weekNumber = _isoWeekNumber(weekMonday);

        // Sum all log values in this week (one-log-per-week model).
        var weekSum = 0.0;
        var hasAnyLog = false;
        String? existingLogDate;
        double? existingLogValue;

        for (var d = 0; d < 7; d++) {
          final day = weekMonday.add(Duration(days: d));
          final iso = _formatIso(day);
          final value = logMap[iso];
          if (value != null) {
            weekSum += value;
            hasAnyLog = true;
            existingLogDate ??= iso;
            existingLogValue ??= value;
          }
        }

        final isMaxType = habit.targetType == HabitTargetType.max;

        final DayStatus status;
        double? progress;

        if (hasAnyLog) {
          if (!isMaxType && weekSum >= habit.targetValue) {
            status = DayStatus.completed;
          } else if (isMaxType && weekSum <= habit.targetValue) {
            status = DayStatus.completed;
          } else if (isMaxType) {
            // Exceeded the maximum → missed for past weeks, neutral for current
            status = isCurrentWeek ? DayStatus.neutral : DayStatus.missed;
          } else {
            // Partial progress toward min target
            status = DayStatus.neutral;
            progress = (weekSum / habit.targetValue).clamp(0.0, 1.0);
          }
        } else if (!isCurrentWeek) {
          status = DayStatus.missed;
        } else {
          status = DayStatus.neutral;
        }

        // All 7 weeks are tappable (last 7 entries rule).
        // Current week logs for today; past weeks use the existing log date
        // if present, otherwise Monday of that week.
        final tapDate =
            isCurrentWeek
                ? _formatIso(today)
                : existingLogDate ?? _formatIso(weekMonday);
        final tapCurrentValue =
            isCurrentWeek ? logMap[tapDate] : existingLogValue;

        return DayIndicator(
          dayLabel: 'W$weekNumber',
          dateLabel: '${weekMonday.day}/${weekMonday.month}',
          status: status,
          habitColor: habitColor,
          progress: progress,
          onTap: () async {
            await HapticFeedback.lightImpact();
            if (habit.targetValue > 1.0) {
              if (!context.mounted) return;
              final result = await showModalBottomSheet<MeasurableLogResult>(
                context: context,
                isScrollControlled: true,
                builder:
                    (_) => MeasurableLogSheet(
                      habitName: habit.name,
                      targetValue: habit.targetValue,
                      targetUnit: habit.targetUnit,
                      targetType: habit.targetType,
                      currentValue: tapCurrentValue,
                    ),
              );
              if (result == null || !context.mounted) return;
              if (result.delete) {
                context.read<HabitsBloc>().add(
                  HabitsEvent.deleteLog(habitId: habit.id, date: tapDate),
                );
              } else if (result.value != null) {
                context.read<HabitsBloc>().add(
                  HabitsEvent.logValue(
                    habitId: habit.id,
                    date: tapDate,
                    value: result.value!,
                  ),
                );
              }
            } else {
              if (!context.mounted) return;
              context.read<HabitsBloc>().add(
                HabitsEvent.toggleLog(habitId: habit.id, date: tapDate),
              );
            }
          },
        );
      }),
    );
  }

  static DateTime _mondayOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  static int _isoWeekNumber(DateTime date) {
    // ISO 8601 week number
    final thursday = date.add(Duration(days: DateTime.thursday - date.weekday));
    final jan1 = DateTime(thursday.year);
    return ((thursday.difference(jan1).inDays) / 7).ceil() + 1;
  }

  String _formatIso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
