import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:track/features/money/domain/entities/transaction_entity.dart';
import 'package:track/features/money/presentation/bloc/all_transactions/all_transactions_state.dart';

part 'all_transactions_event.freezed.dart';

@freezed
sealed class AllTransactionsEvent with _$AllTransactionsEvent {
  const factory AllTransactionsEvent.loadRequested({
    required String userId,
  }) = AllTransactionsLoadRequested;

  const factory AllTransactionsEvent.monthChanged({
    required int year,
    required int month,
  }) = AllTransactionsMonthChanged;

  const factory AllTransactionsEvent.refreshRequested() =
      AllTransactionsRefreshRequested;

  const factory AllTransactionsEvent.filterPanelToggled() =
      AllTransactionsFilterPanelToggled;

  const factory AllTransactionsEvent.typeFilterToggled({
    required TransactionType type,
  }) = AllTransactionsTypeFilterToggled;

  const factory AllTransactionsEvent.categoryFilterToggled({
    required int categoryId,
  }) = AllTransactionsCategoryFilterToggled;

  const factory AllTransactionsEvent.accountFilterToggled({
    required int accountId,
  }) = AllTransactionsAccountFilterToggled;

  const factory AllTransactionsEvent.searchQueryChanged({
    required String query,
  }) = AllTransactionsSearchQueryChanged;

  const factory AllTransactionsEvent.amountRangeChanged({
    int? minCents,
    int? maxCents,
  }) = AllTransactionsAmountRangeChanged;

  const factory AllTransactionsEvent.sortChanged({
    required TransactionSortField sortField,
    required bool ascending,
  }) = AllTransactionsSortChanged;

  const factory AllTransactionsEvent.filtersCleared() =
      AllTransactionsFiltersCleared;
}
