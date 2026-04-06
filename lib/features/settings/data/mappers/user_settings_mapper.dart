import 'package:drift/drift.dart';
import 'package:track/core/database/app_database.dart';
import 'package:track/features/settings/domain/entities/user_settings_entity.dart'
    as domain;

extension UserSettingRowToEntity on UserSetting {
  domain.UserSettingsEntity toEntity() => domain.UserSettingsEntity(
    userId: userId,
    displayName: displayName,
    avatarUrl: avatarUrl,
    currency: currency,
    themeMode: _parseThemeMode(themeMode),
    notificationsEnabled: notificationsEnabled,
    dailyReminderEnabled: dailyReminderEnabled,
    dailyReminderTime: dailyReminderTime,
    firstDayOfWeek: firstDayOfWeek,
    onboardingCompleted: onboardingCompleted,
    updatedAt: updatedAt,
  );
}

extension UserSettingsEntityToCompanion on domain.UserSettingsEntity {
  UserSettingsCompanion toCompanion() => UserSettingsCompanion(
    userId: Value(userId),
    displayName: Value(displayName),
    avatarUrl: Value(avatarUrl),
    currency: Value(currency),
    themeMode: Value(_appThemeModeName(themeMode)),
    notificationsEnabled: Value(notificationsEnabled),
    dailyReminderEnabled: Value(dailyReminderEnabled),
    dailyReminderTime: Value(dailyReminderTime),
    firstDayOfWeek: Value(firstDayOfWeek),
    onboardingCompleted: Value(onboardingCompleted),
    updatedAt: Value(updatedAt),
  );
}

domain.AppThemeMode _parseThemeMode(String raw) => switch (raw) {
  'light' => domain.AppThemeMode.light,
  'dark' => domain.AppThemeMode.dark,
  _ => domain.AppThemeMode.system,
};

String _appThemeModeName(domain.AppThemeMode m) => switch (m) {
  domain.AppThemeMode.light => 'light',
  domain.AppThemeMode.dark => 'dark',
  domain.AppThemeMode.system => 'system',
};
