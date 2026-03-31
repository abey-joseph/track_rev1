import 'package:drift/drift.dart';
import 'package:track/core/database/app_database.dart';
import 'package:track/features/insights/domain/entities/insight_entity.dart';

extension InsightRowToEntity on Insight {
  InsightEntity toEntity() => InsightEntity(
        id: id,
        userId: userId,
        title: title,
        body: body,
        type: _parseInsightType(type),
        confidenceScore: confidenceScore,
        isRead: isRead,
        isDismissed: isDismissed,
        metadata: metadata,
        generatedAt: generatedAt,
        expiresAt: expiresAt,
        createdAt: createdAt,
      );
}

extension InsightEntityToCompanion on InsightEntity {
  InsightsCompanion toCompanion() => InsightsCompanion(
        id: id == 0 ? const Value.absent() : Value(id),
        userId: Value(userId),
        title: Value(title),
        body: Value(body),
        type: Value(_insightTypeName(type)),
        confidenceScore: Value(confidenceScore),
        isRead: Value(isRead),
        isDismissed: Value(isDismissed),
        metadata: Value(metadata),
        generatedAt: Value(generatedAt),
        expiresAt: Value(expiresAt),
        createdAt: Value(createdAt),
      );
}

InsightType _parseInsightType(String raw) => switch (raw) {
      'trend' => InsightType.trend,
      'suggestion' => InsightType.suggestion,
      'warning' => InsightType.warning,
      _ => InsightType.correlation,
    };

String _insightTypeName(InsightType t) => switch (t) {
      InsightType.correlation => 'correlation',
      InsightType.trend => 'trend',
      InsightType.suggestion => 'suggestion',
      InsightType.warning => 'warning',
    };
