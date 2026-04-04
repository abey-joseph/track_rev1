import 'package:injectable/injectable.dart';
import 'package:track/core/database/app_database.dart';
import 'package:track/core/error/exceptions.dart';

abstract class HabitsLocalDataSource {
  Future<List<Habit>> getHabits(String userId);
  Stream<List<Habit>> watchHabits(String userId);
  Future<List<HabitLog>> getLogsForHabit(int habitId);
  Future<HabitStreak?> getStreak(int habitId);
  Future<int> insertHabit(HabitsCompanion entry);
  Future<HabitLog?> getLog(int habitId, String date);
  Future<void> upsertLog(HabitLogsCompanion entry);
  Future<void> deleteLog(int habitId, String date);
  Future<int> deleteHabit(int habitId);
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

  @override
  Future<HabitLog?> getLog(int habitId, String date) async {
    try {
      return await _db.habitsDao.getLog(habitId, date);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> upsertLog(HabitLogsCompanion entry) async {
    try {
      await _db.habitsDao.upsertLog(entry);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> deleteLog(int habitId, String date) async {
    try {
      await _db.habitsDao.deleteLog(habitId, date);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<int> deleteHabit(int habitId) async {
    try {
      return await _db.habitsDao.deleteHabit(habitId);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }
}
