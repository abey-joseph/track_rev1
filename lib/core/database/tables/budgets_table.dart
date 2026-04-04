import 'package:drift/drift.dart';
import 'package:track/core/database/app_database.dart' show Transactions;
import 'package:track/core/database/tables/transactions_table.dart'
    show Transactions;

import 'package:track/core/database/tables/categories_table.dart';

/// Per-category (or overall) spending limits.
///
/// [categoryId]: NULL means this budget covers total spending across all categories.
/// [amountLimit]: stored in **cents**.
/// [period]: 'monthly' | 'weekly'
///
/// The "spent" amount for a budget is computed on-the-fly by querying
/// [Transactions] for the current period — it is NOT stored here to avoid
/// stale data.
class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// NULL = overall budget (all categories combined).
  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();
  IntColumn get amountLimit => integer()();
  TextColumn get period => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
