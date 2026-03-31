import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:track/core/database/app_database.dart';
import 'package:track/features/habits/domain/entities/habit_entity.dart';
import 'package:track/features/habits/domain/entities/habit_log_entity.dart';

// ── Habit ────────────────────────────────────────────────────────────────────

extension HabitRowToEntity on Habit {
  HabitEntity toEntity() => HabitEntity(
        id: id,
        userId: userId,
        name: name,
        description: description,
        iconName: iconName,
        colorHex: colorHex,
        frequencyType: _parseFrequency(frequencyType),
        frequencyDays: _parseDays(frequencyDays),
        targetValue: targetValue,
        targetUnit: targetUnit,
        reminderEnabled: reminderEnabled,
        reminderTime: reminderTime,
        isArchived: isArchived,
        sortOrder: sortOrder,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

extension HabitEntityToCompanion on HabitEntity {
  HabitsCompanion toCompanion() => HabitsCompanion(
        id: id == 0 ? const Value.absent() : Value(id),
        userId: Value(userId),
        name: Value(name),
        description: Value(description),
        iconName: Value(iconName),
        colorHex: Value(colorHex),
        frequencyType: Value(frequencyType.name),
        frequencyDays: Value(jsonEncode(frequencyDays)),
        targetValue: Value(targetValue),
        targetUnit: Value(targetUnit),
        reminderEnabled: Value(reminderEnabled),
        reminderTime: Value(reminderTime),
        isArchived: Value(isArchived),
        sortOrder: Value(sortOrder),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt),
      );
}

// ── HabitLog ─────────────────────────────────────────────────────────────────

extension HabitLogRowToEntity on HabitLog {
  HabitLogEntity toEntity() => HabitLogEntity(
        id: id,
        habitId: habitId,
        loggedDate: loggedDate,
        value: value,
        note: note,
        createdAt: createdAt,
      );
}

extension HabitLogEntityToCompanion on HabitLogEntity {
  HabitLogsCompanion toCompanion() => HabitLogsCompanion(
        id: id == 0 ? const Value.absent() : Value(id),
        habitId: Value(habitId),
        loggedDate: Value(loggedDate),
        value: Value(value),
        note: Value(note),
        createdAt: Value(createdAt),
      );
}

// ── HabitStreak ──────────────────────────────────────────────────────────────

extension HabitStreakRowToEntity on HabitStreak {
  HabitStreakEntity toEntity() => HabitStreakEntity(
        habitId: habitId,
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        lastCompletedDate: lastCompletedDate,
        totalCompletions: totalCompletions,
        updatedAt: updatedAt,
      );
}

// ── Private helpers ───────────────────────────────────────────────────────────

HabitFrequency _parseFrequency(String raw) => switch (raw) {
      'weekly' => HabitFrequency.weekly,
      'custom' => HabitFrequency.custom,
      _ => HabitFrequency.daily,
    };

List<int> _parseDays(String raw) {
  try {
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.cast<int>();
  } catch (_) {
    return [1, 2, 3, 4, 5, 6, 7];
  }
}
