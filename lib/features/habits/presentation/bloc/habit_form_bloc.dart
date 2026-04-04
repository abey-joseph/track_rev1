import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:track/features/habits/domain/entities/habit_entity.dart';
import 'package:track/features/habits/domain/usecases/create_habit.dart';
import 'package:track/features/habits/presentation/bloc/habit_form_event.dart';
import 'package:track/features/habits/presentation/bloc/habit_form_state.dart';

@injectable
class HabitFormBloc extends Bloc<HabitFormEvent, HabitFormState> {
  HabitFormBloc(this._createHabit) : super(const HabitFormState()) {
    on<HabitFormNameChanged>(_onNameChanged);
    on<HabitFormDescriptionChanged>(_onDescriptionChanged);
    on<HabitFormIconChanged>(_onIconChanged);
    on<HabitFormColorChanged>(_onColorChanged);
    on<HabitFormFrequencyChanged>(_onFrequencyChanged);
    on<HabitFormDayToggled>(_onDayToggled);
    on<HabitFormTargetValueChanged>(_onTargetValueChanged);
    on<HabitFormTargetTypeChanged>(_onTargetTypeChanged);
    on<HabitFormTargetUnitChanged>(_onTargetUnitChanged);
    on<HabitFormReminderToggled>(_onReminderToggled);
    on<HabitFormReminderTimeChanged>(_onReminderTimeChanged);
    on<HabitFormSubmitted>(_onSubmitted);
  }

  final CreateHabit _createHabit;

  void _onNameChanged(
    HabitFormNameChanged event,
    Emitter<HabitFormState> emit,
  ) {
    emit(state.copyWith(name: event.name, errorMessage: null));
  }

  void _onDescriptionChanged(
    HabitFormDescriptionChanged event,
    Emitter<HabitFormState> emit,
  ) {
    emit(state.copyWith(description: event.description));
  }

  void _onIconChanged(
    HabitFormIconChanged event,
    Emitter<HabitFormState> emit,
  ) {
    emit(state.copyWith(iconName: event.iconName));
  }

  void _onColorChanged(
    HabitFormColorChanged event,
    Emitter<HabitFormState> emit,
  ) {
    emit(state.copyWith(colorHex: event.colorHex));
  }

  void _onFrequencyChanged(
    HabitFormFrequencyChanged event,
    Emitter<HabitFormState> emit,
  ) {
    final days = switch (event.frequency) {
      HabitFrequency.daily => [1, 2, 3, 4, 5, 6, 7],
      HabitFrequency.weekly => [1, 3, 5], // Mon, Wed, Fri default
      HabitFrequency.custom => [1, 2, 3, 4, 5], // weekdays as default
    };
    emit(state.copyWith(frequencyType: event.frequency, frequencyDays: days));
  }

  void _onDayToggled(
    HabitFormDayToggled event,
    Emitter<HabitFormState> emit,
  ) {
    final days = List<int>.from(state.frequencyDays);
    if (days.contains(event.weekday)) {
      if (days.length > 1) days.remove(event.weekday);
    } else {
      days.add(event.weekday);
      days.sort();
    }
    emit(state.copyWith(frequencyDays: days));
  }

  void _onTargetValueChanged(
    HabitFormTargetValueChanged event,
    Emitter<HabitFormState> emit,
  ) {
    emit(state.copyWith(targetValue: event.targetValue));
  }

  void _onTargetTypeChanged(
    HabitFormTargetTypeChanged event,
    Emitter<HabitFormState> emit,
  ) {
    emit(state.copyWith(targetType: event.targetType));
  }

  void _onTargetUnitChanged(
    HabitFormTargetUnitChanged event,
    Emitter<HabitFormState> emit,
  ) {
    emit(state.copyWith(targetUnit: event.targetUnit));
  }

  void _onReminderToggled(
    HabitFormReminderToggled event,
    Emitter<HabitFormState> emit,
  ) {
    emit(state.copyWith(reminderEnabled: !state.reminderEnabled));
  }

  void _onReminderTimeChanged(
    HabitFormReminderTimeChanged event,
    Emitter<HabitFormState> emit,
  ) {
    emit(state.copyWith(reminderTime: event.reminderTime));
  }

  Future<void> _onSubmitted(
    HabitFormSubmitted event,
    Emitter<HabitFormState> emit,
  ) async {
    if (state.name.trim().isEmpty) {
      emit(state.copyWith(errorMessage: 'Please enter a habit name'));
      return;
    }

    emit(state.copyWith(isSubmitting: true, errorMessage: null));

    final now = DateTime.now();
    final habit = HabitEntity(
      id: 0,
      userId: event.userId,
      name: state.name.trim(),
      description:
          state.description.trim().isEmpty ? null : state.description.trim(),
      iconName: state.iconName,
      colorHex: state.colorHex,
      frequencyType: state.frequencyType,
      frequencyDays: state.frequencyDays,
      targetValue: state.targetValue,
      targetType: state.targetValue > 1.0 ? state.targetType : HabitTargetType.min,
      targetUnit:
          state.targetUnit.trim().isEmpty ? null : state.targetUnit.trim(),
      reminderEnabled: state.reminderEnabled,
      reminderTime: state.reminderEnabled ? state.reminderTime : null,
      isArchived: false,
      sortOrder: 0,
      createdAt: now,
      updatedAt: now,
    );

    final result = await _createHabit(habit);

    result.fold(
      (failure) => emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: 'Failed to create habit. Please try again.',
        ),
      ),
      (_) => emit(state.copyWith(isSubmitting: false, isSuccess: true)),
    );
  }
}
