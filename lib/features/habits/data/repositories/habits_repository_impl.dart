import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/database/app_database.dart';
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
    final sevenDaysAgo = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));

    final recentLogs =
        logsRaw.map((l) => l.toEntity()).where((l) {
          final date = DateTime.parse(l.loggedDate);
          return !date.isBefore(sevenDaysAgo);
        }).toList();

    final streak =
        streakRaw?.toEntity() ??
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
  /// Only logs with value >= 1.0 count as completed.
  int _calculateScore(HabitEntity habit, List<HabitLogEntity> recentLogs) {
    final today = DateTime.now();
    // Map date → value so we can check completion threshold
    final logMap = <String, double>{};
    for (final l in recentLogs) {
      logMap[l.loggedDate] = l.value;
    }

    var scheduledDays = 0;
    var completedDays = 0;

    for (var i = 0; i < 7; i++) {
      final day = DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(Duration(days: i));
      if (habit.frequencyDays.contains(day.weekday)) {
        scheduledDays++;
        final iso = _formatIso(day);
        final value = logMap[iso];
        if (value != null && value >= 1.0) {
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

  /// Three-state toggle cycle:
  ///   no log  → create log (value=1.0, done/green)
  ///   value≥1 → update log (value=0.0, not-done/red)
  ///   value<1 → delete log  (neutral for today, auto-red for past)
  @override
  Future<Either<Failure, Unit>> toggleHabitLog({
    required int habitId,
    required String date,
  }) async {
    try {
      final existing = await _localDataSource.getLog(habitId, date);
      if (existing == null) {
        // No log → mark done (green)
        await _localDataSource.upsertLog(
          HabitLogsCompanion(
            habitId: Value(habitId),
            loggedDate: Value(date),
            value: const Value(1),
            createdAt: Value(DateTime.now()),
          ),
        );
      } else if (existing.value >= 1.0) {
        // Done → mark not-done (red)
        await _localDataSource.upsertLog(
          HabitLogsCompanion(
            id: Value(existing.id),
            habitId: Value(habitId),
            loggedDate: Value(date),
            value: const Value(0),
            createdAt: Value(existing.createdAt),
          ),
        );
      } else {
        // Not-done → remove entry (neutral)
        await _localDataSource.deleteLog(habitId, date);
      }
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(Failure.cache(message: e.message));
    }
  }

  String _formatIso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
