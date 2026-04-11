import 'package:drift/drift.dart';

import 'package:track/core/database/tables/accounts_table.dart';
import 'package:track/core/database/tables/categories_table.dart';

/// Recurring transaction rules that auto-generate real transactions.
///
/// [type]: 'income' | 'expense'
/// [amount]: stored in **cents**, always positive.
/// [scheduleType]: 'daily' | 'weekly' | 'monthlyFixed' | 'monthlyMultiple' | 'once'
/// [startDate]: ISO-8601 date string, e.g. '2026-04-10'.
/// [weekdaysJson]: JSON array of weekday ints, e.g. '[1,3,5]' (1=Mon..7=Sun).
/// [monthDay]: day of month (1-31) for monthlyFixed.
/// [monthDaysJson]: JSON array of day ints for monthlyMultiple.
/// [timesPerMonth]: count of occurrences per month for monthlyMultiple.
/// [lastGeneratedDate]: ISO-8601 date of the most recent generated occurrence.
class RecurringTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  IntColumn get accountId => integer().references(Accounts, #id)();
  IntColumn get categoryId => integer().references(Categories, #id)();
  TextColumn get type => text()();
  IntColumn get amount => integer()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get note => text().nullable()();

  // Schedule
  TextColumn get scheduleType => text()();
  TextColumn get startDate => text()();
  TextColumn get weekdaysJson => text().nullable()();
  IntColumn get monthDay => integer().nullable()();
  TextColumn get monthDaysJson => text().nullable()();
  IntColumn get timesPerMonth => integer().nullable()();

  /// Destination account for transfer-type recurring rules.
  /// Null for income/expense types.
  IntColumn get toAccountId => integer().nullable().references(Accounts, #id)();

  /// The currency the user entered the amount in (ISO 4217 code, e.g. 'USD').
  TextColumn get originalCurrencyCode =>
      text().withDefault(const Constant('USD'))();

  /// The amount in the user's entered currency (cents, always positive).
  IntColumn get originalAmountCents =>
      integer().withDefault(const Constant(0))();

  // Lifecycle
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  TextColumn get lastGeneratedDate => text().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
