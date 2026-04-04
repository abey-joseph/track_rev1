import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/core/usecases/usecase.dart';
import 'package:track/features/habits/domain/repositories/habits_repository.dart';

@lazySingleton
class LogHabitValue implements UseCase<Unit, LogHabitValueParams> {
  LogHabitValue(this._repository);

  final HabitsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(LogHabitValueParams params) =>
      _repository.logHabitValue(
        habitId: params.habitId,
        date: params.date,
        value: params.value,
      );
}

class LogHabitValueParams extends Equatable {
  const LogHabitValueParams({
    required this.habitId,
    required this.date,
    required this.value,
  });

  final int habitId;
  final String date;
  final double value;

  @override
  List<Object?> get props => [habitId, date, value];
}
