import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/core/usecases/usecase.dart';
import 'package:track/features/habits/domain/entities/habit_with_details.dart';
import 'package:track/features/habits/domain/repositories/habits_repository.dart';

@lazySingleton
class GetHabitsWithDetails
    implements UseCase<List<HabitWithDetails>, GetHabitsParams> {
  GetHabitsWithDetails(this._repository);

  final HabitsRepository _repository;

  @override
  Future<Either<Failure, List<HabitWithDetails>>> call(
    GetHabitsParams params,
  ) => _repository.getHabitsWithDetails(params.userId);
}

class GetHabitsParams extends Equatable {
  const GetHabitsParams({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}
