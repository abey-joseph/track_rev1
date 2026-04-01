import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/core/usecases/usecase.dart';
import 'package:track/features/habits/domain/entities/habit_entity.dart';
import 'package:track/features/habits/domain/repositories/habits_repository.dart';

@lazySingleton
class CreateHabit implements UseCase<int, HabitEntity> {
  CreateHabit(this._repository);

  final HabitsRepository _repository;

  @override
  Future<Either<Failure, int>> call(HabitEntity params) =>
      _repository.createHabit(params);
}
