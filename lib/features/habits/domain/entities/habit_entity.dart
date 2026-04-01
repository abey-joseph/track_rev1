import 'package:freezed_annotation/freezed_annotation.dart';

part 'habit_entity.freezed.dart';

/// Frequency with which a habit repeats.
enum HabitFrequency { daily, weekly, custom }

@freezed
abstract class HabitEntity with _$HabitEntity {
  const factory HabitEntity({
    required int id,
    required String userId,
    required String name,
    String? description,
    required String iconName,
    required String colorHex,
    required HabitFrequency frequencyType,

    /// Weekday numbers on which the habit is active (1=Mon … 7=Sun).
    required List<int> frequencyDays,

    /// 1.0 for a simple boolean check-off; higher for quantitative habits.
    required double targetValue,

    /// Human-readable unit (e.g. 'min', 'glasses'). Null = simple check.
    String? targetUnit,
    required bool reminderEnabled,

    /// 'HH:mm' string, e.g. '08:00'. Only meaningful when [reminderEnabled].
    String? reminderTime,
    required bool isArchived,
    required int sortOrder,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _HabitEntity;
}
