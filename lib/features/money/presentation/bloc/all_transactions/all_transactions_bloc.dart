import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:track/features/money/domain/entities/transaction_entity.dart';
import 'package:track/features/money/domain/usecases/delete_transaction.dart';
import 'package:track/features/money/domain/usecases/get_accounts.dart';
import 'package:track/features/money/domain/usecases/get_categories.dart';
import 'package:track/features/money/domain/usecases/get_transactions.dart';
import 'package:track/features/money/domain/usecases/set_transaction_bookmark.dart';
import 'package:track/features/money/presentation/bloc/all_transactions/all_transactions_event.dart';
import 'package:track/features/money/presentation/bloc/all_transactions/all_transactions_state.dart';

@injectable
class AllTransactionsBloc
    extends Bloc<AllTransactionsEvent, AllTransactionsState> {
  AllTransactionsBloc(
    this._getTransactions,
    this._getCategories,
    this._getAccounts,
    this._setBookmark,
    this._deleteTransaction,
  ) : super(const AllTransactionsState()) {
    on<AllTransactionsLoadRequested>(_onLoad);
    on<AllTransactionsMonthChanged>(_onMonthChanged);
    on<AllTransactionsRefreshRequested>(_onRefresh);
    on<AllTransactionsFilterPanelToggled>(_onFilterPanelToggled);
    on<AllTransactionsTypeFilterToggled>(_onTypeFilterToggled);
    on<AllTransactionsCategoryFilterToggled>(_onCategoryFilterToggled);
    on<AllTransactionsAccountFilterToggled>(_onAccountFilterToggled);
    on<AllTransactionsSearchQueryChanged>(_onSearchQueryChanged);
    on<AllTransactionsAmountRangeChanged>(_onAmountRangeChanged);
    on<AllTransactionsSortChanged>(_onSortChanged);
    on<AllTransactionsFiltersCleared>(_onFiltersCleared);
    on<AllTransactionsBookmarkToggled>(_onBookmarkToggled);
    on<AllTransactionsDeleteRequested>(_onDeleteRequested);
  }

  final GetTransactionsWithDetails _getTransactions;
  final GetCategories _getCategories;
  final GetAccounts _getAccounts;
  final SetTransactionBookmark _setBookmark;
  final DeleteTransaction _deleteTransaction;
  String? _userId;

  Future<void> _onLoad(
    AllTransactionsLoadRequested event,
    Emitter<AllTransactionsState> emit,
  ) async {
    _userId = event.userId;
    final now = DateTime.now();
    emit(
      state.copyWith(
        isLoading: true,
        year: now.year,
        month: now.month,
        failure: null,
      ),
    );
    await _fetchMetadata(emit, event.userId);
    await _fetchTransactions(emit, now.year, now.month, event.userId);
  }

  Future<void> _onMonthChanged(
    AllTransactionsMonthChanged event,
    Emitter<AllTransactionsState> emit,
  ) async {
    if (_userId == null) return;
    emit(
      state.copyWith(
        isLoading: true,
        year: event.year,
        month: event.month,
        failure: null,
      ),
    );
    await _fetchTransactions(emit, event.year, event.month, _userId!);
  }

  Future<void> _onRefresh(
    AllTransactionsRefreshRequested event,
    Emitter<AllTransactionsState> emit,
  ) async {
    if (_userId == null) return;
    emit(state.copyWith(isLoading: true, failure: null));
    await _fetchTransactions(emit, state.year, state.month, _userId!);
  }

  Future<void> _fetchMetadata(
    Emitter<AllTransactionsState> emit,
    String userId,
  ) async {
    final catResult = await _getCategories(UserIdParams(userId: userId));
    catResult.fold(
      (_) {},
      (categories) => emit(state.copyWith(categories: categories)),
    );

    final accResult = await _getAccounts(UserIdParams(userId: userId));
    accResult.fold(
      (_) {},
      (accounts) => emit(state.copyWith(accounts: accounts)),
    );
  }

  Future<void> _fetchTransactions(
    Emitter<AllTransactionsState> emit,
    int year,
    int month,
    String userId,
  ) async {
    final fromDate =
        '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-01';
    final lastDay = DateTime(year, month + 1, 0).day;
    final toDate =
        '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';

    final result = await _getTransactions(
      MoneyParams(
        userId: userId,
        fromDate: fromDate,
        toDate: toDate,
      ),
    );

    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, failure: failure)),
      (transactions) =>
          emit(state.copyWith(isLoading: false, allTransactions: transactions)),
    );
  }

  void _onFilterPanelToggled(
    AllTransactionsFilterPanelToggled event,
    Emitter<AllTransactionsState> emit,
  ) {
    emit(state.copyWith(isFilterExpanded: !state.isFilterExpanded));
  }

  void _onTypeFilterToggled(
    AllTransactionsTypeFilterToggled event,
    Emitter<AllTransactionsState> emit,
  ) {
    final types = List<TransactionType>.from(state.selectedTypes);
    if (types.contains(event.type)) {
      types.remove(event.type);
    } else {
      types.add(event.type);
    }
    emit(state.copyWith(selectedTypes: types));
  }

  void _onCategoryFilterToggled(
    AllTransactionsCategoryFilterToggled event,
    Emitter<AllTransactionsState> emit,
  ) {
    final ids = List<int>.from(state.selectedCategoryIds);
    if (ids.contains(event.categoryId)) {
      ids.remove(event.categoryId);
    } else {
      ids.add(event.categoryId);
    }
    emit(state.copyWith(selectedCategoryIds: ids));
  }

  void _onAccountFilterToggled(
    AllTransactionsAccountFilterToggled event,
    Emitter<AllTransactionsState> emit,
  ) {
    final ids = List<int>.from(state.selectedAccountIds);
    if (ids.contains(event.accountId)) {
      ids.remove(event.accountId);
    } else {
      ids.add(event.accountId);
    }
    emit(state.copyWith(selectedAccountIds: ids));
  }

  void _onSearchQueryChanged(
    AllTransactionsSearchQueryChanged event,
    Emitter<AllTransactionsState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  void _onAmountRangeChanged(
    AllTransactionsAmountRangeChanged event,
    Emitter<AllTransactionsState> emit,
  ) {
    emit(
      state.copyWith(
        minAmountCents: event.minCents,
        maxAmountCents: event.maxCents,
      ),
    );
  }

  void _onSortChanged(
    AllTransactionsSortChanged event,
    Emitter<AllTransactionsState> emit,
  ) {
    emit(
      state.copyWith(
        sortField: event.sortField,
        sortAscending: event.ascending,
      ),
    );
  }

  void _onFiltersCleared(
    AllTransactionsFiltersCleared event,
    Emitter<AllTransactionsState> emit,
  ) {
    emit(
      state.copyWith(
        selectedTypes: [],
        selectedCategoryIds: [],
        selectedAccountIds: [],
        searchQuery: '',
        minAmountCents: null,
        maxAmountCents: null,
      ),
    );
  }

  Future<void> _onDeleteRequested(
    AllTransactionsDeleteRequested event,
    Emitter<AllTransactionsState> emit,
  ) async {
    final result = await _deleteTransaction(event.transaction);
    result.fold(
      (_) {},
      (_) {
        final updated =
            state.allTransactions
                .where((t) => t.transaction.id != event.transaction.id)
                .toList();
        emit(state.copyWith(allTransactions: updated));
      },
    );
  }

  Future<void> _onBookmarkToggled(
    AllTransactionsBookmarkToggled event,
    Emitter<AllTransactionsState> emit,
  ) async {
    final result = await _setBookmark(
      BookmarkParams(
        transactionId: event.transactionId,
        isBookmarked: event.isBookmarked,
      ),
    );
    result.fold(
      (_) {},
      (_) {
        final updated =
            state.allTransactions.map((t) {
              if (t.transaction.id == event.transactionId) {
                return t.copyWith(
                  transaction: t.transaction.copyWith(
                    isBookmarked: event.isBookmarked,
                  ),
                );
              }
              return t;
            }).toList();
        emit(state.copyWith(allTransactions: updated));
      },
    );
  }
}
