import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/error/exceptions.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/features/habits/data/datasources/habits_local_data_source.dart';
import 'package:track/features/habits/data/mappers/habit_mapper.dart';
import 'package:track/features/habits/domain/entities/habit_entity.dart';
import 'package:track/features/habits/domain/entities/habit_log_entity.dart';
import 'package:track/features/habits/domain/entities/habit_with_details.dart';
import 'package:track/features/habits/domain/repositories/habits_repository.dart';

@LazySingleton(as: HabitsRepository)
class HabitsRepositoryImpl implements HabitsRepository {
  HabitsRepositoryImpl(this._localDataSource);

  final HabitsLocalDataSource _localDataSource;

  @override
  Future<Either<Failure, List<HabitWithDetails>>> getHabitsWithDetails(
    String userId,
  ) async {
    try {
      final habits = await _localDataSource.getHabits(userId);
      final results = await Future.wait(
        habits.map((h) => _buildHabitWithDetails(h.toEntity())),
      );
      return Right(results);
    } on CacheException catch (e) {
      return Left(Failure.cache(message: e.message));
    }
  }

  @override
  Stream<Either<Failure, List<HabitWithDetails>>> watchHabitsWithDetails(
    String userId,
  ) {
    return _localDataSource.watchHabits(userId).asyncMap((habits) async {
      try {
        final results = await Future.wait(
          habits.map((h) => _buildHabitWithDetails(h.toEntity())),
        );
        return Right<Failure, List<HabitWithDetails>>(results);
      } on CacheException catch (e) {
        return Left<Failure, List<HabitWithDetails>>(
          Failure.cache(message: e.message),
        );
      }
    });
  }

  Future<HabitWithDetails> _buildHabitWithDetails(HabitEntity habit) async {
    final logsRaw = await _localDataSource.getLogsForHabit(habit.id);
    final streakRaw = await _localDataSource.getStreak(habit.id);

    final now = DateTime.now();
    final sevenDaysAgo = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));

    final recentLogs = logsRaw
        .map((l) => l.toEntity())
        .where((l) {
          final date = DateTime.parse(l.loggedDate);
          return !date.isBefore(sevenDaysAgo);
        })
        .toList();

    final streak = streakRaw?.toEntity() ??
        HabitStreakEntity(
          habitId: habit.id,
          currentStreak: 0,
          longestStreak: 0,
          totalCompletions: 0,
          updatedAt: DateTime.now(),
        );

    final score = _calculateScore(habit, recentLogs);

    return HabitWithDetails(
      habit: habit,
      recentLogs: recentLogs,
      streak: streak,
      score: score,
    );
  }

  /// Frequency-aware score: only counts days the habit is scheduled.
  int _calculateScore(HabitEntity habit, List<HabitLogEntity> recentLogs) {
    final today = DateTime.now();
    final logDates = recentLogs.map((l) => l.loggedDate).toSet();

    int scheduledDays = 0;
    int completedDays = 0;

    for (int i = 0; i < 7; i++) {
      final day = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: i));
      if (habit.frequencyDays.contains(day.weekday)) {
        scheduledDays++;
        final iso = _formatIso(day);
        if (logDates.contains(iso)) {
          completedDays++;
        }
      }
    }

    if (scheduledDays == 0) return 100;
    return ((completedDays / scheduledDays) * 100).round();
  }

  @override
  Future<Either<Failure, int>> createHabit(HabitEntity habit) async {
    try {
      final id = await _localDataSource.insertHabit(habit.toCompanion());
      return Right(id);
    } on CacheException catch (e) {
      return Left(Failure.cache(message: e.message));
    }
  }

  String _formatIso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
