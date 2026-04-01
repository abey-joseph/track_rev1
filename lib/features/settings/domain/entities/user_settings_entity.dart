import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_settings_entity.freezed.dart';

/// App-level theme preference. Named [AppThemeMode] to avoid shadowing
/// Flutter's [ThemeMode] in files that import both.
enum AppThemeMode { light, dark, system }

@freezed
abstract class UserSettingsEntity with _$UserSettingsEntity {
  const factory UserSettingsEntity({
    required String userId,
    String? displayName,
    String? avatarUrl,

    /// ISO 4217 currency code, e.g. 'USD'.
    required String currency,
    required AppThemeMode themeMode,
    required bool notificationsEnabled,
    required bool dailyReminderEnabled,

    /// 'HH:mm' format, e.g. '09:00'.
    required String dailyReminderTime,

    /// 1=Monday … 7=Sunday (ISO 8601 convention).
    required int firstDayOfWeek,
    required bool onboardingCompleted,
    required DateTime updatedAt,
  }) = _UserSettingsEntity;
}
