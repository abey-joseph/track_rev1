import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:track/features/habits/domain/entities/habit_log_entity.dart';
import 'package:track/features/habits/domain/entities/habit_with_details.dart';
import 'package:track/features/habits/domain/usecases/delete_habit.dart';
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
    this._deleteHabit,
  ) : super(const HabitsState.initial()) {
    on<HabitsLoadRequested>(_onLoad);
    on<HabitsRefreshRequested>(_onRefresh);
    on<HabitsToggleLog>(_onToggle);
    on<HabitsLogValue>(_onLogValue);
    on<HabitsDeleteLog>(_onDeleteLog);
    on<HabitsDeleteHabit>(_onDeleteHabit);
  }

  final WatchHabitsWithDetails _watchHabitsWithDetails;
  final GetHabitsWithDetails _getHabitsWithDetails;
  final ToggleHabitLog _toggleHabitLog;
  final LogHabitValue _logHabitValue;
  final DeleteHabitLog _deleteHabitLog;
  final DeleteHabit _deleteHabit;
  String? _currentUserId;

  Future<void> _onLoad(
    HabitsLoadRequested event,
    Emitter<HabitsState> emit,
  ) async {
    _currentUserId = event.userId;
    emit(const HabitsState.loading());

    await emit.forEach(
      _watchHabitsWithDetails(GetHabitsParams(userId: event.userId)),
      onData:
          (result) => result.fold(
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
    // Optimistic update: modify the affected habit's log in-place
    final currentState = state;
    if (currentState is HabitsLoaded) {
      final updatedHabits =
          currentState.habits.map((h) {
            if (h.habit.id != event.habitId) return h;
            return _applyToggle(h, event.date);
          }).toList();
      emit(HabitsState.loaded(habits: updatedHabits));
    }

    // Persist to DB
    final result = await _toggleHabitLog(
      ToggleHabitLogParams(habitId: event.habitId, date: event.date),
    );

    // On failure, rollback by re-fetching from DB
    await result.fold(
      (failure) async => _refreshHabits(emit),
      (_) async => _refreshHabits(emit),
    );
  }

  Future<void> _onLogValue(
    HabitsLogValue event,
    Emitter<HabitsState> emit,
  ) async {
    // Optimistic update: set the value for the affected habit's log
    final currentState = state;
    if (currentState is HabitsLoaded) {
      final updatedHabits =
          currentState.habits.map((h) {
            if (h.habit.id != event.habitId) return h;
            return _applyLogValue(h, event.date, event.value);
          }).toList();
      emit(HabitsState.loaded(habits: updatedHabits));
    }

    // Persist to DB
    final result = await _logHabitValue(
      LogHabitValueParams(
        habitId: event.habitId,
        date: event.date,
        value: event.value,
      ),
    );

    // Re-fetch for streak/score consistency
    await result.fold(
      (failure) async => _refreshHabits(emit),
      (_) async => _refreshHabits(emit),
    );
  }

  Future<void> _onDeleteLog(
    HabitsDeleteLog event,
    Emitter<HabitsState> emit,
  ) async {
    // Optimistic update: remove the log for the affected habit
    final currentState = state;
    if (currentState is HabitsLoaded) {
      final updatedHabits =
          currentState.habits.map((h) {
            if (h.habit.id != event.habitId) return h;
            return _applyDeleteLog(h, event.date);
          }).toList();
      emit(HabitsState.loaded(habits: updatedHabits));
    }

    // Persist to DB
    final result = await _deleteHabitLog(
      DeleteHabitLogParams(habitId: event.habitId, date: event.date),
    );

    // Re-fetch for streak/score consistency
    await result.fold(
      (failure) async => _refreshHabits(emit),
      (_) async => _refreshHabits(emit),
    );
  }

  Future<void> _onDeleteHabit(
    HabitsDeleteHabit event,
    Emitter<HabitsState> emit,
  ) async {
    // Optimistic removal
    final currentState = state;
    if (currentState is HabitsLoaded) {
      final updatedHabits =
          currentState.habits
              .where((h) => h.habit.id != event.habitId)
              .toList();
      emit(HabitsState.loaded(habits: updatedHabits));
    }

    final result = await _deleteHabit(
      DeleteHabitParams(habitId: event.habitId),
    );

    await result.fold(
      (failure) async => _refreshHabits(emit),
      (_) async => _refreshHabits(emit),
    );
  }

  // ---------------------------------------------------------------------------
  // Optimistic state helpers
  // ---------------------------------------------------------------------------

  /// Three-state toggle cycle on a habit's log for [date]:
  ///   no log  → value 1.0 (done)
  ///   value≥1 → value 0.0 (failed)
  ///   value<1 → remove log (neutral)
  HabitWithDetails _applyToggle(HabitWithDetails h, String date) {
    final existingIdx = h.recentLogs.indexWhere((l) => l.loggedDate == date);

    if (existingIdx == -1) {
      // No log → create as done
      final newLog = HabitLogEntity(
        id: -1, // placeholder; will be corrected after re-fetch
        habitId: h.habit.id,
        loggedDate: date,
        value: 1,
        createdAt: DateTime.now(),
      );
      return h.copyWith(recentLogs: [...h.recentLogs, newLog]);
    }

    final existing = h.recentLogs[existingIdx];
    if (existing.value >= 1.0) {
      // Done → mark failed
      final updated = existing.copyWith(value: 0);
      final logs = List<HabitLogEntity>.from(h.recentLogs);
      logs[existingIdx] = updated;
      return h.copyWith(recentLogs: logs);
    }

    // Failed → remove (neutral)
    final logs = List<HabitLogEntity>.from(h.recentLogs);
    logs.removeAt(existingIdx);
    return h.copyWith(recentLogs: logs);
  }

  /// Set or update the log value for [date].
  HabitWithDetails _applyLogValue(
    HabitWithDetails h,
    String date,
    double value,
  ) {
    final existingIdx = h.recentLogs.indexWhere((l) => l.loggedDate == date);

    if (existingIdx == -1) {
      final newLog = HabitLogEntity(
        id: -1,
        habitId: h.habit.id,
        loggedDate: date,
        value: value,
        createdAt: DateTime.now(),
      );
      return h.copyWith(recentLogs: [...h.recentLogs, newLog]);
    }

    final updated = h.recentLogs[existingIdx].copyWith(value: value);
    final logs = List<HabitLogEntity>.from(h.recentLogs);
    logs[existingIdx] = updated;
    return h.copyWith(recentLogs: logs);
  }

  /// Remove the log for [date].
  HabitWithDetails _applyDeleteLog(HabitWithDetails h, String date) {
    final logs = h.recentLogs.where((l) => l.loggedDate != date).toList();
    return h.copyWith(recentLogs: logs);
  }

  // ---------------------------------------------------------------------------
  // Background re-sync for streak/score accuracy
  // ---------------------------------------------------------------------------

  Future<void> _refreshHabits(Emitter<HabitsState> emit) async {
    // The watch stream only observes the habits table, not habit_logs.
    // Manually re-fetch to pick up the log change and recalculate streaks/scores.
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
