import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/core/usecases/usecase.dart';
import 'package:track/features/habits/domain/entities/habit_with_details.dart';
import 'package:track/features/habits/domain/repositories/habits_repository.dart';
import 'package:track/features/habits/domain/usecases/get_habits_with_details.dart';

@lazySingleton
class WatchHabitsWithDetails
    implements StreamUseCase<List<HabitWithDetails>, GetHabitsParams> {
  WatchHabitsWithDetails(this._repository);

  final HabitsRepository _repository;

  @override
  Stream<Either<Failure, List<HabitWithDetails>>> call(
    GetHabitsParams params,
  ) =>
      _repository.watchHabitsWithDetails(params.userId);
}
