import 'package:drift/drift.dart';

import 'package:track/core/database/app_database.dart';
import 'package:track/core/database/tables/habit_logs_table.dart';
import 'package:track/core/database/tables/habit_streaks_table.dart';
import 'package:track/core/database/tables/habits_table.dart';

part 'habits_dao.g.dart';

@DriftAccessor(tables: [Habits, HabitLogs, HabitStreaks])
class HabitsDao extends DatabaseAccessor<AppDatabase> with _$HabitsDaoMixin {
  HabitsDao(super.db);

  // ── Habits ──────────────────────────────────────────────────────────────

  /// All non-archived habits for [userId], ordered by [sortOrder].
  Future<List<Habit>> getHabits(String userId) =>
      (select(habits)
            ..where((h) => h.userId.equals(userId) & h.isArchived.equals(false))
            ..orderBy([(h) => OrderingTerm.asc(h.sortOrder)]))
          .get();

  /// Watch all non-archived habits for reactive UI updates.
  Stream<List<Habit>> watchHabits(String userId) =>
      (select(habits)
            ..where((h) => h.userId.equals(userId) & h.isArchived.equals(false))
            ..orderBy([(h) => OrderingTerm.asc(h.sortOrder)]))
          .watch();

  Future<Habit?> getHabitById(int id) =>
      (select(habits)..where((h) => h.id.equals(id))).getSingleOrNull();

  Future<int> insertHabit(HabitsCompanion entry) => into(habits).insert(entry);

  Future<bool> updateHabit(HabitsCompanion entry) =>
      update(habits).replace(entry);

  Future<int> archiveHabit(int id) => (update(habits)..where(
    (h) => h.id.equals(id),
  )).write(const HabitsCompanion(isArchived: Value(true)));

  Future<int> deleteHabit(int id) =>
      (delete(habits)..where((h) => h.id.equals(id))).go();

  // ── Habit Logs ───────────────────────────────────────────────────────────

  /// Returns the log for a specific habit on [date] (ISO-8601), if any.
  Future<HabitLog?> getLog(int habitId, String date) =>
      (select(habitLogs)..where(
        (l) => l.habitId.equals(habitId) & l.loggedDate.equals(date),
      )).getSingleOrNull();

  /// All logs for [habitId] in descending date order.
  Future<List<HabitLog>> getLogsForHabit(int habitId) =>
      (select(habitLogs)
            ..where((l) => l.habitId.equals(habitId))
            ..orderBy([(l) => OrderingTerm.desc(l.loggedDate)]))
          .get();

  /// All logs across all habits for a given [date] (ISO-8601).
  Future<List<HabitLog>> getLogsForDate(String date) =>
      (select(habitLogs)..where((l) => l.loggedDate.equals(date))).get();

  /// Upsert a log entry. Recalculates streak afterward.
  Future<void> upsertLog(HabitLogsCompanion entry) async {
    await into(habitLogs).insertOnConflictUpdate(entry);
    final habitId = entry.habitId.value;
    await _recalculateStreak(habitId);
  }

  /// Delete the log for [habitId] on [date] and recalculate streak.
  Future<void> deleteLog(int habitId, String date) async {
    await (delete(habitLogs)..where(
      (l) => l.habitId.equals(habitId) & l.loggedDate.equals(date),
    )).go();
    await _recalculateStreak(habitId);
  }

  // ── Habit Streaks ────────────────────────────────────────────────────────

  Future<HabitStreak?> getStreak(int habitId) =>
      (select(habitStreaks)
        ..where((s) => s.habitId.equals(habitId))).getSingleOrNull();

  Stream<HabitStreak?> watchStreak(int habitId) =>
      (select(habitStreaks)
        ..where((s) => s.habitId.equals(habitId))).watchSingleOrNull();

  /// Recalculates [currentStreak], [longestStreak], and [totalCompletions]
  /// for [habitId] by scanning its log history.
  ///
  /// This runs inside a transaction so reads and the subsequent write are
  /// consistent.
  Future<void> _recalculateStreak(int habitId) async {
    await transaction(() async {
      // Only count logs with value >= 1.0 as completions for streaks.
      final allLogs =
          await (select(habitLogs)
                ..where((l) => l.habitId.equals(habitId))
                ..orderBy([(l) => OrderingTerm.desc(l.loggedDate)]))
              .get();
      final logs = allLogs.where((l) => l.value >= 1.0).toList();

      if (logs.isEmpty) {
        await into(habitStreaks).insertOnConflictUpdate(
          HabitStreaksCompanion(
            habitId: Value(habitId),
            currentStreak: const Value(0),
            longestStreak: const Value(0),
            lastCompletedDate: const Value(null),
            totalCompletions: const Value(0),
            updatedAt: Value(DateTime.now()),
          ),
        );
        return;
      }

      final sortedDates = logs.map((l) => l.loggedDate).toList();
      final today = _todayIso();
      final yesterday = _offsetDayIso(-1);

      var current = 0;
      // Streak starts from today or yesterday (allow for today not yet logged).
      var cursor =
          sortedDates.first == today || sortedDates.first == yesterday
              ? sortedDates.first
              : null;

      if (cursor != null) {
        for (final date in sortedDates) {
          if (date == cursor) {
            current++;
            cursor = _previousDayIso(cursor!);
          } else {
            break;
          }
        }
      }

      // Longest streak — scan all logs.
      var longest = 0;
      var run = 0;
      String? prev;
      for (final date in sortedDates.reversed) {
        if (prev == null || date == _nextDayIso(prev)) {
          run++;
          if (run > longest) longest = run;
        } else {
          run = 1;
        }
        prev = date;
      }

      final existing = await getStreak(habitId);
      final prevLongest = existing?.longestStreak ?? 0;

      await into(habitStreaks).insertOnConflictUpdate(
        HabitStreaksCompanion(
          habitId: Value(habitId),
          currentStreak: Value(current),
          longestStreak: Value(longest > prevLongest ? longest : prevLongest),
          lastCompletedDate: Value(sortedDates.first),
          totalCompletions: Value(logs.length),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  // ── Date helpers ─────────────────────────────────────────────────────────

  String _todayIso() {
    final now = DateTime.now();
    return _formatIso(now);
  }

  String _offsetDayIso(int days) {
    final d = DateTime.now().add(Duration(days: days));
    return _formatIso(d);
  }

  String _previousDayIso(String isoDate) {
    final d = DateTime.parse(isoDate).subtract(const Duration(days: 1));
    return _formatIso(d);
  }

  String _nextDayIso(String isoDate) {
    final d = DateTime.parse(isoDate).add(const Duration(days: 1));
    return _formatIso(d);
  }

  String _formatIso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
