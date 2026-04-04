import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:track/features/habits/domain/entities/habit_entity.dart';

part 'habit_form_event.freezed.dart';

@freezed
sealed class HabitFormEvent with _$HabitFormEvent {
  const factory HabitFormEvent.nameChanged({required String name}) =
      HabitFormNameChanged;

  const factory HabitFormEvent.descriptionChanged({
    required String description,
  }) = HabitFormDescriptionChanged;

  const factory HabitFormEvent.iconChanged({required String iconName}) =
      HabitFormIconChanged;

  const factory HabitFormEvent.colorChanged({required String colorHex}) =
      HabitFormColorChanged;

  const factory HabitFormEvent.frequencyChanged({
    required HabitFrequency frequency,
  }) = HabitFormFrequencyChanged;

  const factory HabitFormEvent.dayToggled({required int weekday}) =
      HabitFormDayToggled;

  const factory HabitFormEvent.targetValueChanged({
    required double targetValue,
  }) = HabitFormTargetValueChanged;

  const factory HabitFormEvent.targetTypeChanged({
    required HabitTargetType targetType,
  }) = HabitFormTargetTypeChanged;

  const factory HabitFormEvent.targetUnitChanged({required String targetUnit}) =
      HabitFormTargetUnitChanged;

  const factory HabitFormEvent.reminderToggled() = HabitFormReminderToggled;

  const factory HabitFormEvent.reminderTimeChanged({
    required String reminderTime,
  }) = HabitFormReminderTimeChanged;

  const factory HabitFormEvent.submitted({required String userId}) =
      HabitFormSubmitted;
}
