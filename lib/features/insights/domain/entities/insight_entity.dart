import 'package:freezed_annotation/freezed_annotation.dart';

part 'insight_entity.freezed.dart';

enum InsightType { correlation, trend, suggestion, warning }

@freezed
abstract class InsightEntity with _$InsightEntity {
  const factory InsightEntity({
    required int id,
    required String userId,
    required String title,
    required String body,
    required InsightType type,

    /// 0.0–1.0 confidence score from the generating model.
    required double confidenceScore,
    required bool isRead,
    required bool isDismissed,

    /// Raw JSON string for extra structured data (charts, related IDs, etc.).
    String? metadata,
    required DateTime generatedAt,

    /// Null = insight never expires.
    DateTime? expiresAt,
    required DateTime createdAt,
  }) = _InsightEntity;
}
