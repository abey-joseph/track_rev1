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

    /// ISO-8601 date string, e.g. '2026-03-31'.
    required String transactionDate,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(false) bool isBookmarked,
    String? note,

    /// The currency the user entered the amount in (ISO 4217 code, e.g. 'USD').
    @Default('USD') String originalCurrencyCode,

    /// The amount in the user's entered currency (cents, always positive).
    @Default(0) int originalAmountCents,

    /// ID of the paired transaction row for transfers. Null otherwise.
    int? transferPeerId,

    /// FK to the recurring rule that generated this transaction. Null for manual.
    int? sourceRecurringTransactionId,

    /// ISO-8601 date of the occurrence this transaction represents.
    String? sourceOccurrenceDate,
  }) = _TransactionEntity;
}
