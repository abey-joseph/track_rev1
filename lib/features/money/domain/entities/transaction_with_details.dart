import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:track/features/money/domain/entities/transaction_entity.dart';

part 'transaction_with_details.freezed.dart';

@freezed
abstract class TransactionWithDetails with _$TransactionWithDetails {
  const factory TransactionWithDetails({
    required TransactionEntity transaction,
    required String categoryName,
    required String categoryIconName,
    required String categoryColorHex,
    required String accountName,

    /// ISO 4217 code of the original entry currency (e.g. 'USD').
    @Default('USD') String currencyCode,

    /// Symbol of the original entry currency (e.g. '$').
    @Default(r'$') String currencySymbol,

    /// Name of the destination account for transfers. Null otherwise.
    String? toAccountName,
  }) = _TransactionWithDetails;
}
