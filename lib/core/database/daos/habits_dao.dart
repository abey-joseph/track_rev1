import 'package:drift/drift.dart';

import 'package:track/core/database/app_database.dart';

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

  Future<int> deleteHabit(int id) async {
    return transaction(() async {
      // Delete all logs for this habit
      await (delete(habitLogs)..where((l) => l.habitId.equals(id))).go();
      // Delete streak for this habit
      await (delete(habitStreaks)..where((s) => s.habitId.equals(id))).go();
      // Finally delete the habit itself
      return (delete(habits)..where((h) => h.id.equals(id))).go();
    });
  }

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
      final habit = await getHabitById(habitId);
      final threshold = habit?.targetValue ?? 1.0;
      final isMaxType = habit?.targetType == 'max';
      final isWeekly = habit?.frequencyType == 'weekly';
      final allLogs =
          await (select(habitLogs)
                ..where((l) => l.habitId.equals(habitId))
                ..orderBy([(l) => OrderingTerm.desc(l.loggedDate)]))
              .get();

      bool isCompleted(double value) {
        return isMaxType ? value <= threshold : value >= threshold;
      }

      final completedLogs = allLogs.where((l) => isCompleted(l.value)).toList();

      if (completedLogs.isEmpty) {
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

      int current;
      int longest;
      final totalCompletions = completedLogs.length;
      final lastCompletedDate = completedLogs.first.loggedDate;

      if (isWeekly) {
        // Weekly streak: count consecutive completed weeks
        final frequencyDays = _parseDays(
          habit?.frequencyDays ?? '[1,2,3,4,5,6,7]',
        );
        final completedDates = completedLogs.map((l) => l.loggedDate).toSet();

        final todayDate = DateTime.parse(_todayIso());
        final currentMonday = _mondayOfWeek(todayDate);

        // Check if a given week is fully completed
        bool isWeekCompleted(DateTime monday) {
          var scheduled = 0;
          var completed = 0;
          for (var d = 0; d < 7; d++) {
            final day = monday.add(Duration(days: d));
            if (frequencyDays.contains(day.weekday)) {
              scheduled++;
              if (completedDates.contains(_formatIso(day))) {
                completed++;
              }
            }
          }
          return scheduled > 0 && completed >= scheduled;
        }

        // Current streak (from current or previous week backwards)
        current = 0;
        var weekCursor = currentMonday;
        // Allow current week to not count if not yet completed
        if (!isWeekCompleted(weekCursor)) {
          weekCursor = weekCursor.subtract(const Duration(days: 7));
        }
        while (isWeekCompleted(weekCursor)) {
          current++;
          weekCursor = weekCursor.subtract(const Duration(days: 7));
        }

        // Longest streak: scan all weeks that have any logs
        final allDates =
            allLogs.map((l) => DateTime.parse(l.loggedDate)).toList();
        if (allDates.isEmpty) {
          longest = 0;
        } else {
          allDates.sort();
          final firstMonday = _mondayOfWeek(allDates.first);
          final lastMonday = _mondayOfWeek(allDates.last);
          longest = 0;
          var run = 0;
          var w = firstMonday;
          while (!w.isAfter(lastMonday)) {
            if (isWeekCompleted(w)) {
              run++;
              if (run > longest) longest = run;
            } else {
              run = 0;
            }
            w = w.add(const Duration(days: 7));
          }
        }
      } else {
        // Daily streak calculation (unchanged logic)
        final sortedDates = completedLogs.map((l) => l.loggedDate).toList();
        final today = _todayIso();
        final yesterday = _offsetDayIso(-1);

        current = 0;
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

        longest = 0;
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
      }

      final existing = await getStreak(habitId);
      final prevLongest = existing?.longestStreak ?? 0;

      await into(habitStreaks).insertOnConflictUpdate(
        HabitStreaksCompanion(
          habitId: Value(habitId),
          currentStreak: Value(current),
          longestStreak: Value(longest > prevLongest ? longest : prevLongest),
          lastCompletedDate: Value(lastCompletedDate),
          totalCompletions: Value(totalCompletions),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  static DateTime _mondayOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  static List<int> _parseDays(String raw) {
    try {
      final decoded =
          (raw.startsWith('['))
              ? raw
                  .substring(1, raw.length - 1)
                  .split(',')
                  .map((s) => int.parse(s.trim()))
                  .toList()
              : [1, 2, 3, 4, 5, 6, 7];
      return decoded;
    } catch (_) {
      return [1, 2, 3, 4, 5, 6, 7];
    }
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
