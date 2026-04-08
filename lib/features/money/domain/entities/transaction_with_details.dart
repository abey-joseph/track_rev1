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
  }) = _TransactionWithDetails;
}
