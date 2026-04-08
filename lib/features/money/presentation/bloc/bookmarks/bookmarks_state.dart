import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/features/money/domain/entities/transaction_with_details.dart';
import 'package:track/features/money/presentation/bloc/bookmarks/bookmarks_event.dart';

part 'bookmarks_state.freezed.dart';

@freezed
abstract class BookmarksState with _$BookmarksState {
  const factory BookmarksState({
    @Default(false) bool isLoading,
    @Default([]) List<TransactionWithDetails> transactions,
    @Default(BookmarkSortField.date) BookmarkSortField sortField,
    @Default(false) bool sortAscending,
    Failure? failure,
  }) = _BookmarksState;

  const BookmarksState._();

  /// Returns transactions sorted by the selected field.
  /// Month-group keys are year-month strings e.g. "2026-04".
  Map<String, List<TransactionWithDetails>> get transactionsByMonth {
    // Group by year-month key
    final groups = <String, List<TransactionWithDetails>>{};
    for (final t in transactions) {
      final date = t.transaction.transactionDate;
      final yearMonth = date.length >= 7 ? date.substring(0, 7) : date;
      groups.putIfAbsent(yearMonth, () => []).add(t);
    }

    // Sort within each group
    for (final group in groups.values) {
      group.sort((a, b) {
        final cmp = switch (sortField) {
          BookmarkSortField.date => a.transaction.transactionDate.compareTo(
            b.transaction.transactionDate,
          ),
          BookmarkSortField.amount => a.transaction.amountCents.compareTo(
            b.transaction.amountCents,
          ),
        };
        return sortAscending ? cmp : -cmp;
      });
    }

    // Sort month keys newest-first
    final sortedKeys = groups.keys.toList()..sort((a, b) => b.compareTo(a));
    return {for (final k in sortedKeys) k: groups[k]!};
  }
}
