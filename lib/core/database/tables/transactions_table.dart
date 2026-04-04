import 'package:drift/drift.dart';

import 'package:track/core/database/tables/accounts_table.dart';
import 'package:track/core/database/tables/categories_table.dart';

/// Income, expense, and transfer records.
///
/// [type]: 'income' | 'expense' | 'transfer'
/// [amount]: stored in **cents**, always positive.
/// [transactionDate]: ISO-8601 date string, e.g. '2026-03-31'.
/// [transferPeerId]: self-referencing FK that links the two sides of a transfer
///   (debit row ↔ credit row). NULL for non-transfer transactions.
///
/// When a transaction is inserted/updated, [Accounts.balance] must be adjusted
/// atomically in the same database transaction.
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  IntColumn get accountId => integer().references(Accounts, #id)();
  IntColumn get categoryId => integer().references(Categories, #id)();
  TextColumn get type => text()();
  IntColumn get amount => integer()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get note => text().nullable()();
  TextColumn get transactionDate => text()();

  /// Links the two rows that form a transfer pair.
  IntColumn get transferPeerId =>
      integer().nullable().references(Transactions, #id)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
