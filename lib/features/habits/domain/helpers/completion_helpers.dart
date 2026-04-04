import 'package:track/features/habits/domain/entities/habit_entity.dart';

/// Whether a logged [value] meets the habit's [target] given its [targetType].
bool isHabitCompleted(double value, double target, HabitTargetType targetType) {
  return targetType == HabitTargetType.min ? value >= target : value <= target;
}

/// Progress fraction (0.0–1.0) for a min-type measurable habit.
/// Returns null for max-type habits (they use binary completed/failed).
double? completionProgress(
  double value,
  double target,
  HabitTargetType targetType,
) {
  if (targetType == HabitTargetType.max) return null;
  if (target <= 0) return 1;
  return (value / target).clamp(0.0, 1.0);
}
