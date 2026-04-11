import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:track/features/money/domain/entities/transaction_entity.dart';

part 'recurring_transaction_entity.freezed.dart';

enum RecurringScheduleType {
  daily,
  weekly,
  monthlyFixed,
  monthlyMultiple,
  once,
}

enum RecurringStatus { active, completed }

@freezed
abstract class RecurringTransactionEntity with _$RecurringTransactionEntity {
  const factory RecurringTransactionEntity({
    required int id,
    required String userId,
    required int accountId,
    required int categoryId,
    required TransactionType type,

    /// Amount in **cents** (always positive).
    required int amountCents,
    required String title,

    // Schedule
    required RecurringScheduleType scheduleType,

    /// ISO-8601 date string, e.g. '2026-04-10'.
    required String startDate,

    // Lifecycle
    required DateTime createdAt,
    required DateTime updatedAt,

    /// Destination account for transfer-type rules. Null for income/expense.
    int? toAccountId,

    /// The currency the user entered the amount in (ISO 4217 code, e.g. 'USD').
    @Default('USD') String originalCurrencyCode,

    /// The amount in the user's entered currency (cents, always positive).
    @Default(0) int originalAmountCents,

    String? note,

    /// Weekday ints (1=Mon..7=Sun) for weekly schedules.
    @Default([]) List<int> weekdays,

    /// Day of month (1-31) for monthlyFixed.
    int? monthDay,

    /// Days of month for monthlyMultiple.
    @Default([]) List<int> monthDays,

    /// Number of occurrences per month for monthlyMultiple.
    int? timesPerMonth,

    @Default(true) bool isActive,
    @Default(false) bool isCompleted,

    /// ISO-8601 date of the most recent generated occurrence.
    String? lastGeneratedDate,
    DateTime? completedAt,
  }) = _RecurringTransactionEntity;
}
