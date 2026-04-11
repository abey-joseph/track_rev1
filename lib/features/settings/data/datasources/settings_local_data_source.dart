import 'package:injectable/injectable.dart';
import 'package:track/core/database/app_database.dart';
import 'package:track/core/error/exceptions.dart';

abstract class SettingsLocalDataSource {
  Future<UserSetting?> getSettings(String userId);

  Stream<UserSetting?> watchSettings(String userId);

  Future<void> upsertSettings(UserSettingsCompanion entry);

  Future<void> updateSettings(String userId, UserSettingsCompanion entry);
}

@LazySingleton(as: SettingsLocalDataSource)
class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  SettingsLocalDataSourceImpl(this._db);

  final AppDatabase _db;

  @override
  Future<UserSetting?> getSettings(String userId) async {
    try {
      return await _db.settingsDao.getSettings(userId);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Stream<UserSetting?> watchSettings(String userId) {
    try {
      return _db.settingsDao.watchSettings(userId);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> upsertSettings(UserSettingsCompanion entry) async {
    try {
      await _db.settingsDao.upsertSettings(entry);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> updateSettings(
    String userId,
    UserSettingsCompanion entry,
  ) async {
    try {
      await _db.settingsDao.updateSettings(userId, entry);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }
}
