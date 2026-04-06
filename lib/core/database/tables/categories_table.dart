import 'package:drift/drift.dart';

/// Transaction categories.
///
/// [userId]: NULL means this is a system-default category seeded on first launch
///   and shared across all users. A Firebase UID means a user-created category.
/// [transactionType]: 'income' | 'expense' | 'both'
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// NULL = system default (visible to all users).
  TextColumn get userId => text().nullable()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get transactionType => text()();
  TextColumn get iconName => text()();
  TextColumn get colorHex => text()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
}
