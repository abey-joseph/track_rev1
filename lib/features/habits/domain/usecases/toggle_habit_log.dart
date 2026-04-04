import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/core/usecases/usecase.dart';
import 'package:track/features/habits/domain/repositories/habits_repository.dart';

@lazySingleton
class ToggleHabitLog implements UseCase<Unit, ToggleHabitLogParams> {
  ToggleHabitLog(this._repository);

  final HabitsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(ToggleHabitLogParams params) =>
      _repository.toggleHabitLog(habitId: params.habitId, date: params.date);
}

class ToggleHabitLogParams extends Equatable {
  const ToggleHabitLogParams({required this.habitId, required this.date});

  final int habitId;
  final String date;

  @override
  List<Object?> get props => [habitId, date];
}
