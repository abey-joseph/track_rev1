import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/core/usecases/usecase.dart';
import 'package:track/features/habits/domain/repositories/habits_repository.dart';

@lazySingleton
class DeleteHabit implements UseCase<Unit, DeleteHabitParams> {
  DeleteHabit(this._repository);

  final HabitsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(DeleteHabitParams params) =>
      _repository.deleteHabit(habitId: params.habitId);
}

class DeleteHabitParams extends Equatable {
  const DeleteHabitParams({required this.habitId});

  final int habitId;

  @override
  List<Object?> get props => [habitId];
}
