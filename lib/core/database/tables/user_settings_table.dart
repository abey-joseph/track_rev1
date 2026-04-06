import 'package:drift/drift.dart';

/// Per-user preferences. One row per Firebase UID, upserted on first sign-in.
///
/// [themeMode]: 'light' | 'dark' | 'system'
/// [firstDayOfWeek]: 1 = Monday … 7 = Sunday (ISO 8601 convention).
/// [dailyReminderTime]: 'HH:mm' format, e.g. '09:00'.
class UserSettings extends Table {
  /// Firebase UID — primary key (no autoincrement needed).
  TextColumn get userId => text()();
  TextColumn get displayName => text().nullable()();
  TextColumn get avatarUrl => text().nullable()();
  TextColumn get currency => text().withDefault(const Constant('USD'))();
  TextColumn get themeMode => text().withDefault(const Constant('system'))();
  BoolColumn get notificationsEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get dailyReminderEnabled =>
      boolean().withDefault(const Constant(false))();
  TextColumn get dailyReminderTime =>
      text().withDefault(const Constant('09:00'))();
  IntColumn get firstDayOfWeek => integer().withDefault(const Constant(1))();
  BoolColumn get onboardingCompleted =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {userId};
}
