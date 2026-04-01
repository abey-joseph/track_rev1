import 'package:drift/drift.dart';

/// AI-generated insights cached locally.
///
/// [type]: 'correlation' | 'trend' | 'suggestion' | 'warning'
/// [confidenceScore]: 0.0–1.0 — higher means more reliable insight.
/// [metadata]: JSON blob for extra structured data (related habit/transaction IDs,
///   chart data points, etc.) consumed by the insights UI.
/// [generatedAt]: when the insight was produced (may differ from [createdAt]
///   if it was buffered before being saved locally).
/// [expiresAt]: optional expiry; stale insights are hidden from the UI without
///   being deleted.
class Insights extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get body => text()();
  TextColumn get type => text()();
  RealColumn get confidenceScore =>
      real().withDefault(const Constant(0.0))();
  BoolColumn get isRead =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isDismissed =>
      boolean().withDefault(const Constant(false))();

  /// JSON blob — nullable; may be absent for simple text-only insights.
  TextColumn get metadata => text().nullable()();
  DateTimeColumn get generatedAt => dateTime()();

  /// NULL = insight never expires.
  DateTimeColumn get expiresAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}
