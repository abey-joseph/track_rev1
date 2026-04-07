import 'package:drift/drift.dart';

/// User-defined currencies with exchange rates relative to the default currency.
///
/// [code]: ISO 4217 currency code, e.g. 'USD'.
/// [symbol]: Currency symbol, e.g. '$'.
/// [exchangeRate]: Rate relative to the default currency.
///   The default currency always has a rate of 1.0.
class Currencies extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get code => text().withLength(min: 1, max: 10)();
  TextColumn get symbol => text().withLength(min: 1, max: 10)();
  RealColumn get exchangeRate => real().withDefault(const Constant(1))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
