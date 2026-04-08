import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/features/money/domain/entities/account_entity.dart';
import 'package:track/features/money/domain/entities/category_entity.dart';
import 'package:track/features/money/domain/entities/transaction_entity.dart';
import 'package:track/features/money/domain/entities/transaction_with_details.dart';

part 'all_transactions_state.freezed.dart';

enum TransactionSortField { date, amount, title }

@freezed
abstract class AllTransactionsState with _$AllTransactionsState {
  const factory AllTransactionsState({
    @Default(false) bool isLoading,
    @Default([]) List<TransactionWithDetails> allTransactions,
    @Default([]) List<CategoryEntity> categories,
    @Default([]) List<AccountEntity> accounts,
    @Default(0) int year,
    @Default(0) int month,
    @Default(false) bool isFilterExpanded,
    @Default([]) List<TransactionType> selectedTypes,
    @Default([]) List<int> selectedCategoryIds,
    @Default([]) List<int> selectedAccountIds,
    @Default('') String searchQuery,
    int? minAmountCents,
    int? maxAmountCents,
    @Default(TransactionSortField.date) TransactionSortField sortField,
    @Default(false) bool sortAscending,
    Failure? failure,
  }) = _AllTransactionsState;

  const AllTransactionsState._();

  bool get hasActiveFilters =>
      selectedTypes.isNotEmpty ||
      selectedCategoryIds.isNotEmpty ||
      selectedAccountIds.isNotEmpty ||
      searchQuery.isNotEmpty ||
      minAmountCents != null ||
      maxAmountCents != null;

  int get activeFilterCount {
    var count = 0;
    if (selectedTypes.isNotEmpty) count++;
    if (selectedCategoryIds.isNotEmpty) count++;
    if (selectedAccountIds.isNotEmpty) count++;
    if (searchQuery.isNotEmpty) count++;
    if (minAmountCents != null || maxAmountCents != null) count++;
    return count;
  }

  List<TransactionWithDetails> get filteredAndSortedTransactions {
    var result = allTransactions.toList();

    if (selectedTypes.isNotEmpty) {
      result =
          result
              .where((t) => selectedTypes.contains(t.transaction.type))
              .toList();
    }

    if (selectedCategoryIds.isNotEmpty) {
      result =
          result
              .where(
                (t) => selectedCategoryIds.contains(t.transaction.categoryId),
              )
              .toList();
    }

    if (selectedAccountIds.isNotEmpty) {
      result =
          result
              .where(
                (t) => selectedAccountIds.contains(t.transaction.accountId),
              )
              .toList();
    }

    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result =
          result
              .where(
                (t) =>
                    t.transaction.title.toLowerCase().contains(query) ||
                    t.categoryName.toLowerCase().contains(query) ||
                    t.accountName.toLowerCase().contains(query) ||
                    (t.transaction.note?.toLowerCase().contains(query) ??
                        false),
              )
              .toList();
    }

    if (minAmountCents != null) {
      result =
          result
              .where((t) => t.transaction.amountCents >= minAmountCents!)
              .toList();
    }
    if (maxAmountCents != null) {
      result =
          result
              .where((t) => t.transaction.amountCents <= maxAmountCents!)
              .toList();
    }

    result.sort((a, b) {
      final int comparison;
      switch (sortField) {
        case TransactionSortField.date:
          comparison = a.transaction.transactionDate.compareTo(
            b.transaction.transactionDate,
          );
        case TransactionSortField.amount:
          comparison = a.transaction.amountCents.compareTo(
            b.transaction.amountCents,
          );
        case TransactionSortField.title:
          comparison = a.transaction.title.toLowerCase().compareTo(
            b.transaction.title.toLowerCase(),
          );
      }
      return sortAscending ? comparison : -comparison;
    });

    return result;
  }

  String get monthLabel {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month < 1 || month > 12) return '';
    return '${months[month]} $year';
  }
}
