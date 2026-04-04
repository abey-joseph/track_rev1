import 'package:drift/drift.dart';

import 'package:track/core/database/app_database.dart';
import 'package:track/core/database/tables/insights_table.dart';

part 'insights_dao.g.dart';

@DriftAccessor(tables: [Insights])
class InsightsDao extends DatabaseAccessor<AppDatabase>
    with _$InsightsDaoMixin {
  InsightsDao(super.db);

  /// Active (non-dismissed, non-expired) insights for [userId], newest first.
  Future<List<Insight>> getInsights(String userId) {
    final now = DateTime.now();
    return (select(insights)
          ..where(
            (i) =>
                i.userId.equals(userId) &
                i.isDismissed.equals(false) &
                (i.expiresAt.isNull() | i.expiresAt.isBiggerThanValue(now)),
          )
          ..orderBy([(i) => OrderingTerm.desc(i.generatedAt)]))
        .get();
  }

  /// Watch active insights reactively.
  Stream<List<Insight>> watchInsights(String userId) {
    final now = DateTime.now();
    return (select(insights)
          ..where(
            (i) =>
                i.userId.equals(userId) &
                i.isDismissed.equals(false) &
                (i.expiresAt.isNull() | i.expiresAt.isBiggerThanValue(now)),
          )
          ..orderBy([(i) => OrderingTerm.desc(i.generatedAt)]))
        .watch();
  }

  Future<Insight?> getInsightById(int id) =>
      (select(insights)..where((i) => i.id.equals(id))).getSingleOrNull();

  Future<int> insertInsight(InsightsCompanion entry) =>
      into(insights).insert(entry);

  Future<int> markAsRead(int id) => (update(insights)..where(
    (i) => i.id.equals(id),
  )).write(const InsightsCompanion(isRead: Value(true)));

  Future<int> dismiss(int id) => (update(insights)..where(
    (i) => i.id.equals(id),
  )).write(const InsightsCompanion(isDismissed: Value(true)));

  /// Removes all expired and dismissed insights for [userId] to keep the
  /// database tidy.
  Future<int> purgeStale(String userId) {
    final now = DateTime.now();
    return (delete(insights)..where(
      (i) =>
          i.userId.equals(userId) &
          (i.isDismissed.equals(true) | i.expiresAt.isSmallerThanValue(now)),
    )).go();
  }
}
