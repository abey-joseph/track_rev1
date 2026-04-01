import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/features/habits/domain/entities/habit_with_details.dart';

part 'habits_state.freezed.dart';

@freezed
sealed class HabitsState with _$HabitsState {
  const factory HabitsState.initial() = HabitsInitial;
  const factory HabitsState.loading() = HabitsLoading;
  const factory HabitsState.loaded({
    required List<HabitWithDetails> habits,
  }) = HabitsLoaded;
  const factory HabitsState.error({required Failure failure}) = HabitsError;
}
