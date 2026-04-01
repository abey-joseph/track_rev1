import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:track/features/habits/domain/usecases/get_habits_with_details.dart';
import 'package:track/features/habits/domain/usecases/watch_habits_with_details.dart';
import 'package:track/features/habits/presentation/bloc/habits_event.dart';
import 'package:track/features/habits/presentation/bloc/habits_state.dart';

@injectable
class HabitsBloc extends Bloc<HabitsEvent, HabitsState> {
  HabitsBloc(this._watchHabitsWithDetails)
      : super(const HabitsState.initial()) {
    on<HabitsLoadRequested>(_onLoad);
    on<HabitsRefreshRequested>(_onRefresh);
  }

  final WatchHabitsWithDetails _watchHabitsWithDetails;
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
}
