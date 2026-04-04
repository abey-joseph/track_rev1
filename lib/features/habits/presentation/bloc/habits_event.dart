import 'package:freezed_annotation/freezed_annotation.dart';

part 'habits_event.freezed.dart';

@freezed
sealed class HabitsEvent with _$HabitsEvent {
  const factory HabitsEvent.loadRequested({required String userId}) =
      HabitsLoadRequested;

  const factory HabitsEvent.refreshRequested() = HabitsRefreshRequested;

  const factory HabitsEvent.toggleLog({
    required int habitId,
    required String date,
  }) = HabitsToggleLog;

  const factory HabitsEvent.logValue({
    required int habitId,
    required String date,
    required double value,
  }) = HabitsLogValue;

  const factory HabitsEvent.deleteLog({
    required int habitId,
    required String date,
  }) = HabitsDeleteLog;
}
