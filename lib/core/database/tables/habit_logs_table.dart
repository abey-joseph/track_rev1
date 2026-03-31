import 'package:drift/drift.dart';

import 'habits_table.dart';

/// One row per habit per day a completion is recorded.
///
/// [loggedDate]: ISO-8601 date string, e.g. '2026-03-31'.
/// [value]: how much was completed; 1.0 = fully done.
///   For quantitative habits this can be a partial amount (e.g. 6.0 of 8 glasses).
///
/// UNIQUE constraint on (habitId, loggedDate) — only one log per habit per day.
class HabitLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get habitId => integer().references(Habits, #id)();
  TextColumn get loggedDate => text()();
  RealColumn get value => real().withDefault(const Constant(1.0))();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {habitId, loggedDate},
      ];
}
