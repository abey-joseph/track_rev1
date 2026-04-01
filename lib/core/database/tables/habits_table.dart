import 'package:drift/drift.dart';

/// Habits table — one row per habit the user creates.
///
/// [frequencyType]: 'daily' | 'weekly' | 'custom'
/// [frequencyDays]: JSON int array of weekdays, e.g. '[1,2,3,4,5,6,7]' (1=Mon, 7=Sun)
/// [targetValue]: 1.0 for a simple boolean check-off; higher values for quantitative
///   habits (e.g. 8.0 for "drink 8 glasses of water").
/// [targetUnit]: human-readable unit string ('min', 'glasses', 'pages'), null = simple check.
class Habits extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  TextColumn get iconName =>
      text().withDefault(const Constant('check_circle'))();
  TextColumn get colorHex =>
      text().withDefault(const Constant('#4CAF50'))();
  TextColumn get frequencyType =>
      text().withDefault(const Constant('daily'))();
  TextColumn get frequencyDays =>
      text().withDefault(const Constant('[1,2,3,4,5,6,7]'))();
  RealColumn get targetValue =>
      real().withDefault(const Constant(1.0))();
  TextColumn get targetUnit => text().nullable()();
  BoolColumn get reminderEnabled =>
      boolean().withDefault(const Constant(false))();
  TextColumn get reminderTime => text().nullable()();
  BoolColumn get isArchived =>
      boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
