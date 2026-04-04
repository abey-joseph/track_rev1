import 'package:drift/drift.dart';

import 'package:track/core/database/app_database.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [UserSettings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  Future<UserSetting?> getSettings(String userId) =>
      (select(userSettings)
        ..where((s) => s.userId.equals(userId))).getSingleOrNull();

  Stream<UserSetting?> watchSettings(String userId) =>
      (select(userSettings)
        ..where((s) => s.userId.equals(userId))).watchSingleOrNull();

  /// Creates or fully replaces the settings row for [userId].
  Future<void> upsertSettings(UserSettingsCompanion entry) =>
      into(userSettings).insertOnConflictUpdate(entry);

  /// Partially updates settings for [userId].
  Future<int> updateSettings(String userId, UserSettingsCompanion entry) =>
      (update(userSettings)
        ..where((s) => s.userId.equals(userId))).write(entry);

  Future<int> deleteSettings(String userId) =>
      (delete(userSettings)..where((s) => s.userId.equals(userId))).go();
}
