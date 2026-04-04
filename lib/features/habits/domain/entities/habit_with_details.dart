import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:track/features/habits/domain/entities/habit_entity.dart';
import 'package:track/features/habits/domain/entities/habit_log_entity.dart';

part 'habit_with_details.freezed.dart';

/// Bundles a habit with its recent logs, streak, and computed score
/// for display on the habits list page.
@freezed
abstract class HabitWithDetails with _$HabitWithDetails {
  const factory HabitWithDetails({
    required HabitEntity habit,

    /// Last 7 days of log entries (most recent first).
    required List<HabitLogEntity> recentLogs,

    /// Streak statistics for this habit.
    required HabitStreakEntity streak,

    /// Completion score 0–100, frequency-aware over the last 7 days.
    required int score,
  }) = _HabitWithDetails;
}
