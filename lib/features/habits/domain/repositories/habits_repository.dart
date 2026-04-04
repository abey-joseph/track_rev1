import 'package:fpdart/fpdart.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/features/habits/domain/entities/habit_entity.dart';
import 'package:track/features/habits/domain/entities/habit_with_details.dart';

abstract class HabitsRepository {
  Future<Either<Failure, List<HabitWithDetails>>> getHabitsWithDetails(
    String userId,
  );

  Stream<Either<Failure, List<HabitWithDetails>>> watchHabitsWithDetails(
    String userId,
  );

  Future<Either<Failure, int>> createHabit(HabitEntity habit);

  Future<Either<Failure, Unit>> toggleHabitLog({
    required int habitId,
    required String date,
  });

  Future<Either<Failure, Unit>> logHabitValue({
    required int habitId,
    required String date,
    required double value,
  });

  Future<Either<Failure, Unit>> deleteHabitLog({
    required int habitId,
    required String date,
  });
}
