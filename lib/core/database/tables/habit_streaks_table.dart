import 'package:drift/drift.dart';

import 'habits_table.dart';

/// Denormalized streak cache — 1:1 with [Habits].
///
/// Recalculated (via trigger or DAO logic) whenever a [HabitLog] is inserted
/// or deleted, so the UI never needs to scan the full log history on render.
///
/// [lastCompletedDate]: ISO-8601 date string, nullable.
class HabitStreaks extends Table {
  /// Primary key doubles as the foreign key to [Habits].
  IntColumn get habitId => integer().references(Habits, #id)();
  IntColumn get currentStreak =>
      integer().withDefault(const Constant(0))();
  IntColumn get longestStreak =>
      integer().withDefault(const Constant(0))();
  TextColumn get lastCompletedDate => text().nullable()();
  IntColumn get totalCompletions =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {habitId};
}
