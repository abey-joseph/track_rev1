import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:track/features/habits/domain/entities/habit_entity.dart';

part 'habit_form_state.freezed.dart';

@freezed
abstract class HabitFormState with _$HabitFormState {
  const factory HabitFormState({
    @Default('') String name,
    @Default('') String description,
    @Default('check_circle') String iconName,
    @Default('#4CAF50') String colorHex,
    @Default(HabitFrequency.daily) HabitFrequency frequencyType,
    @Default([1, 2, 3, 4, 5, 6, 7]) List<int> frequencyDays,
    @Default(1.0) double targetValue,
    @Default('') String targetUnit,
    @Default(false) bool reminderEnabled,
    @Default('08:00') String reminderTime,
    @Default(false) bool isSubmitting,
    @Default(false) bool isSuccess,
    String? errorMessage,
  }) = _HabitFormState;
}
