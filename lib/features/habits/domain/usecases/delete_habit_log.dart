import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/core/usecases/usecase.dart';
import 'package:track/features/habits/domain/repositories/habits_repository.dart';

@lazySingleton
class DeleteHabitLog implements UseCase<Unit, DeleteHabitLogParams> {
  DeleteHabitLog(this._repository);

  final HabitsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(DeleteHabitLogParams params) =>
      _repository.deleteHabitLog(
        habitId: params.habitId,
        date: params.date,
      );
}

class DeleteHabitLogParams extends Equatable {
  const DeleteHabitLogParams({
    required this.habitId,
    required this.date,
  });

  final int habitId;
  final String date;

  @override
  List<Object?> get props => [habitId, date];
}
