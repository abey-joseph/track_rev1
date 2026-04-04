import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:track/features/habits/domain/usecases/delete_habit_log.dart';
import 'package:track/features/habits/domain/usecases/get_habits_with_details.dart';
import 'package:track/features/habits/domain/usecases/log_habit_value.dart';
import 'package:track/features/habits/domain/usecases/toggle_habit_log.dart';
import 'package:track/features/habits/domain/usecases/watch_habits_with_details.dart';
import 'package:track/features/habits/presentation/bloc/habits_event.dart';
import 'package:track/features/habits/presentation/bloc/habits_state.dart';

@injectable
class HabitsBloc extends Bloc<HabitsEvent, HabitsState> {
  HabitsBloc(
    this._watchHabitsWithDetails,
    this._getHabitsWithDetails,
    this._toggleHabitLog,
    this._logHabitValue,
    this._deleteHabitLog,
  ) : super(const HabitsState.initial()) {
    on<HabitsLoadRequested>(_onLoad);
    on<HabitsRefreshRequested>(_onRefresh);
    on<HabitsToggleLog>(_onToggle);
    on<HabitsLogValue>(_onLogValue);
    on<HabitsDeleteLog>(_onDeleteLog);
  }

  final WatchHabitsWithDetails _watchHabitsWithDetails;
  final GetHabitsWithDetails _getHabitsWithDetails;
  final ToggleHabitLog _toggleHabitLog;
  final LogHabitValue _logHabitValue;
  final DeleteHabitLog _deleteHabitLog;
  String? _currentUserId;

  Future<void> _onLoad(
    HabitsLoadRequested event,
    Emitter<HabitsState> emit,
  ) async {
    _currentUserId = event.userId;
    emit(const HabitsState.loading());

    await emit.forEach(
      _watchHabitsWithDetails(GetHabitsParams(userId: event.userId)),
      onData: (result) => result.fold(
        (failure) => HabitsState.error(failure: failure),
        (habits) => HabitsState.loaded(habits: habits),
      ),
    );
  }

  Future<void> _onRefresh(
    HabitsRefreshRequested event,
    Emitter<HabitsState> emit,
  ) async {
    if (_currentUserId != null) {
      add(HabitsLoadRequested(userId: _currentUserId!));
    }
  }

  Future<void> _onToggle(
    HabitsToggleLog event,
    Emitter<HabitsState> emit,
  ) async {
    final result = await _toggleHabitLog(
      ToggleHabitLogParams(habitId: event.habitId, date: event.date),
    );

    await result.fold(
      (failure) async => emit(HabitsState.error(failure: failure)),
      (_) async => _refreshHabits(emit),
    );
  }

  Future<void> _onLogValue(
    HabitsLogValue event,
    Emitter<HabitsState> emit,
  ) async {
    final result = await _logHabitValue(
      LogHabitValueParams(
        habitId: event.habitId,
        date: event.date,
        value: event.value,
      ),
    );

    await result.fold(
      (failure) async => emit(HabitsState.error(failure: failure)),
      (_) async => _refreshHabits(emit),
    );
  }

  Future<void> _onDeleteLog(
    HabitsDeleteLog event,
    Emitter<HabitsState> emit,
  ) async {
    final result = await _deleteHabitLog(
      DeleteHabitLogParams(habitId: event.habitId, date: event.date),
    );

    await result.fold(
      (failure) async => emit(HabitsState.error(failure: failure)),
      (_) async => _refreshHabits(emit),
    );
  }

  Future<void> _refreshHabits(Emitter<HabitsState> emit) async {
    // The watch stream only observes the habits table, not habit_logs.
    // Manually re-fetch to pick up the log change.
    if (_currentUserId == null) return;
    final refreshResult = await _getHabitsWithDetails(
      GetHabitsParams(userId: _currentUserId!),
    );
    refreshResult.fold(
      (failure) => emit(HabitsState.error(failure: failure)),
      (habits) => emit(HabitsState.loaded(habits: habits)),
    );
  }
}
