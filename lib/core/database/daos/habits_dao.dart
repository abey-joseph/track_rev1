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
        // Weekly streak: count consecutive completed weeks.
        // A week is complete when the sum of all log values in that week
        // meets the target: sum >= threshold (min-type) or sum <= threshold
        // (max-type, at least one log required).
        final todayDate = DateTime.parse(_todayIso());
        final currentMonday = _mondayOfWeek(todayDate);

        bool isWeekCompleted(DateTime monday) {
          final weekEnd = monday.add(const Duration(days: 7));
          final weekLogs =
              allLogs.where((l) {
                final d = DateTime.parse(l.loggedDate);
                return !d.isBefore(monday) && d.isBefore(weekEnd);
              }).toList();
          if (weekLogs.isEmpty) return false;
          final weekSum = weekLogs.fold<double>(0, (s, l) => s + l.value);
          return isMaxType ? weekSum <= threshold : weekSum >= threshold;
        }

        // Current streak (from current or previous week backwards)
        current = 0;
        var weekCursor = currentMonday;
        if (!isWeekCompleted(weekCursor)) {
          weekCursor = weekCursor.subtract(const Duration(days: 7));
        }
        while (isWeekCompleted(weekCursor)) {
          current++;
          weekCursor = weekCursor.subtract(const Duration(days: 7));
        }

        // Longest streak: scan all weeks from first to last log
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
        // Daily / custom streak: walk backwards through scheduled days only,
        // so unscheduled days (e.g. Wednesday skipped in a custom habit) do
        // not break the streak.
        final frequencyDays = _parseDays(
          habit?.frequencyDays ?? '[1,2,3,4,5,6,7]',
        );
        final sortedDates = completedLogs.map((l) => l.loggedDate).toList();

        // Start cursor from the most recent scheduled day (today or earlier).
        final mostRecentScheduled = _todayOrPreviousScheduledIso(frequencyDays);
        final oneBeforeThat = _previousScheduledDayIso(
          mostRecentScheduled,
          frequencyDays,
        );

        current = 0;
        var cursor =
            sortedDates.first == mostRecentScheduled ||
                    sortedDates.first == oneBeforeThat
                ? sortedDates.first
                : null;

        if (cursor != null) {
          for (final date in sortedDates) {
            if (date == cursor) {
              current++;
              cursor = _previousScheduledDayIso(cursor!, frequencyDays);
            } else {
              break;
            }
          }
        }

        longest = 0;
        var run = 0;
        String? prev;
        for (final date in sortedDates.reversed) {
          if (prev == null ||
              date == _nextScheduledDayIso(prev, frequencyDays)) {
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

  /// Returns today if today is a scheduled day, otherwise walks backwards
  /// to find the most recent scheduled day (max 7 steps).
  String _todayOrPreviousScheduledIso(List<int> scheduledDays) {
    var d = DateTime.now();
    d = DateTime(d.year, d.month, d.day);
    for (var i = 0; i < 7; i++) {
      if (scheduledDays.contains(d.weekday)) return _formatIso(d);
      d = d.subtract(const Duration(days: 1));
    }
    return _formatIso(d);
  }

  /// Walks backwards from [isoDate] (exclusive) to find the previous
  /// scheduled day (max 7 steps).
  String _previousScheduledDayIso(String isoDate, List<int> scheduledDays) {
    var d = DateTime.parse(isoDate).subtract(const Duration(days: 1));
    for (var i = 0; i < 7; i++) {
      if (scheduledDays.contains(d.weekday)) return _formatIso(d);
      d = d.subtract(const Duration(days: 1));
    }
    return _formatIso(d);
  }

  /// Walks forwards from [isoDate] (exclusive) to find the next
  /// scheduled day (max 7 steps).
  String _nextScheduledDayIso(String isoDate, List<int> scheduledDays) {
    var d = DateTime.parse(isoDate).add(const Duration(days: 1));
    for (var i = 0; i < 7; i++) {
      if (scheduledDays.contains(d.weekday)) return _formatIso(d);
      d = d.add(const Duration(days: 1));
    }
    return _formatIso(d);
  }

  String _formatIso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
