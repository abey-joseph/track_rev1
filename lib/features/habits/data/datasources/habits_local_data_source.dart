import 'package:injectable/injectable.dart';
import 'package:track/core/database/app_database.dart';
import 'package:track/core/error/exceptions.dart';

abstract class HabitsLocalDataSource {
  Future<List<Habit>> getHabits(String userId);
  Stream<List<Habit>> watchHabits(String userId);
  Future<List<HabitLog>> getLogsForHabit(int habitId);
  Future<HabitStreak?> getStreak(int habitId);
  Future<int> insertHabit(HabitsCompanion entry);
}

@LazySingleton(as: HabitsLocalDataSource)
class HabitsLocalDataSourceImpl implements HabitsLocalDataSource {
  HabitsLocalDataSourceImpl(this._db);

  final AppDatabase _db;

  @override
  Future<List<Habit>> getHabits(String userId) async {
    try {
      return await _db.habitsDao.getHabits(userId);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Stream<List<Habit>> watchHabits(String userId) {
    try {
      return _db.habitsDao.watchHabits(userId);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<List<HabitLog>> getLogsForHabit(int habitId) async {
    try {
      return await _db.habitsDao.getLogsForHabit(habitId);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<HabitStreak?> getStreak(int habitId) async {
    try {
      return await _db.habitsDao.getStreak(habitId);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<int> insertHabit(HabitsCompanion entry) async {
    try {
      return await _db.habitsDao.insertHabit(entry);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }
}
