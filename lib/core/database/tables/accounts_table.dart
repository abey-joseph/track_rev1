import 'package:drift/drift.dart';
import 'package:track/core/database/app_database.dart' show Transaction;

/// Financial accounts the user tracks money in.
///
/// [type]: 'checking' | 'savings' | 'cash' | 'credit_card' | 'investment'
/// [balance]: stored in **cents** (integer) to avoid floating-point errors.
///   Updated atomically together with each [Transaction] insert/update.
/// [currency]: ISO 4217 code, e.g. 'USD'.
class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get type => text()();
  IntColumn get balance => integer().withDefault(const Constant(0))();
  TextColumn get currency => text().withDefault(const Constant('USD'))();
  TextColumn get description => text().nullable()();
  TextColumn get iconName =>
      text().withDefault(const Constant('account_balance'))();
  TextColumn get colorHex => text().withDefault(const Constant('#2196F3'))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
