import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:track/core/error/failures.dart';
import 'package:track/features/money/domain/entities/recurring_transaction_entity.dart';

part 'recurring_transactions_state.freezed.dart';

@freezed
sealed class RecurringTransactionsState with _$RecurringTransactionsState {
  const factory RecurringTransactionsState.initial() =
      RecurringTransactionsInitial;

  const factory RecurringTransactionsState.loading() =
      RecurringTransactionsLoading;

  const factory RecurringTransactionsState.loaded({
    required List<RecurringTransactionEntity> recurringTransactions,
    String? deleteError,
  }) = RecurringTransactionsLoaded;

  const factory RecurringTransactionsState.error({
    required Failure failure,
  }) = RecurringTransactionsError;
}
