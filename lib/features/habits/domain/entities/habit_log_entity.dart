import 'package:freezed_annotation/freezed_annotation.dart';

part 'habit_log_entity.freezed.dart';

/// Represents a single completion record for a habit on a given date.
@freezed
abstract class HabitLogEntity with _$HabitLogEntity {
  const factory HabitLogEntity({
    required int id,
    required int habitId,

    /// ISO-8601 date string, e.g. '2026-03-31'.
    required String loggedDate,

    /// Amount completed; 1.0 = fully done.
    required double value,
    required DateTime createdAt,
    String? note,
  }) = _HabitLogEntity;
}

/// Snapshot of a habit's streak statistics.
@freezed
abstract class HabitStreakEntity with _$HabitStreakEntity {
  const factory HabitStreakEntity({
    required int habitId,
    required int currentStreak,
    required int longestStreak,

    required int totalCompletions,
    required DateTime updatedAt,

    /// ISO-8601 date string of the most recent completion, or null.
    String? lastCompletedDate,
  }) = _HabitStreakEntity;
}
