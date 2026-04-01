import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_entity.freezed.dart';

enum TransactionType { income, expense, transfer }

@freezed
abstract class TransactionEntity with _$TransactionEntity {
  const factory TransactionEntity({
    required int id,
    required String userId,
    required int accountId,
    required int categoryId,
    required TransactionType type,

    /// Amount in **cents** (always positive).
    required int amountCents,
    required String title,
    String? note,

    /// ISO-8601 date string, e.g. '2026-03-31'.
    required String transactionDate,

    /// ID of the paired transaction row for transfers. Null otherwise.
    int? transferPeerId,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _TransactionEntity;
}
