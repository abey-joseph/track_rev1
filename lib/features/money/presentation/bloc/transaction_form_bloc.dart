import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:track/features/money/domain/entities/category_entity.dart';
import 'package:track/features/money/domain/entities/transaction_entity.dart';
import 'package:track/features/money/domain/usecases/create_transaction.dart';
import 'package:track/features/money/domain/usecases/create_transfer.dart';
import 'package:track/features/money/domain/usecases/get_accounts.dart';
import 'package:track/features/money/domain/usecases/get_categories.dart';
import 'package:track/features/money/domain/usecases/watch_currencies.dart';
import 'package:track/features/money/presentation/bloc/transaction_form_event.dart';
import 'package:track/features/money/presentation/bloc/transaction_form_state.dart';

@injectable
class TransactionFormBloc
    extends Bloc<TransactionFormEvent, TransactionFormState> {
  TransactionFormBloc(
    this._createTransaction,
    this._createTransfer,
    this._getAccounts,
    this._getCategories,
    this._watchCurrencies,
  ) : super(const TransactionFormState()) {
    on<TransactionFormInitialized>(_onInitialized);
    on<TransactionFormTypeChanged>(_onTypeChanged);
    on<TransactionFormAmountChanged>(_onAmountChanged);
    on<TransactionFormTitleChanged>(_onTitleChanged);
    on<TransactionFormCategorySelected>(_onCategorySelected);
    on<TransactionFormAccountSelected>(_onAccountSelected);
    on<TransactionFormToAccountSelected>(_onToAccountSelected);
    on<TransactionFormCurrencySelected>(_onCurrencySelected);
    on<TransactionFormDateChanged>(_onDateChanged);
    on<TransactionFormNoteChanged>(_onNoteChanged);
    on<TransactionFormSubmitted>(_onSubmitted);
  }

  final CreateTransaction _createTransaction;
  final CreateTransfer _createTransfer;
  final GetAccounts _getAccounts;
  final GetCategories _getCategories;
  final WatchCurrencies _watchCurrencies;

  Future<void> _onInitialized(
    TransactionFormInitialized event,
    Emitter<TransactionFormState> emit,
  ) async {
    final params = UserIdParams(userId: event.userId);

    final accountsResult = await _getAccounts(params);
    final categoriesResult = await _getCategories(params);
    final currenciesResult = await _watchCurrencies(params).first;

    final accounts = accountsResult.getOrElse((_) => []);
    final categories = categoriesResult.getOrElse((_) => []);
    final currencies = currenciesResult.getOrElse((_) => []);

    final defaultAccount = accounts.isNotEmpty ? accounts.first : null;
    final defaultCurrencyCode =
        currencies.isNotEmpty
            ? (currencies
                .firstWhere(
                  (c) => c.isDefault,
                  orElse: () => currencies.first,
                )
                .code)
            : 'USD';

    emit(
      state.copyWith(
        availableAccounts: accounts,
        allCategories: categories,
        availableCurrencies: currencies,
        accountId: defaultAccount?.id,
        selectedCurrencyCode: defaultCurrencyCode,
        date: DateTime.now(),
      ),
    );
  }

  void _onTypeChanged(
    TransactionFormTypeChanged event,
    Emitter<TransactionFormState> emit,
  ) {
    emit(
      state.copyWith(
        type: event.type,
        categoryId: null,
        toAccountId: null,
        errorMessage: null,
      ),
    );
  }

  void _onAmountChanged(
    TransactionFormAmountChanged event,
    Emitter<TransactionFormState> emit,
  ) {
    emit(state.copyWith(amount: event.amount, errorMessage: null));
  }

  void _onTitleChanged(
    TransactionFormTitleChanged event,
    Emitter<TransactionFormState> emit,
  ) {
    emit(state.copyWith(title: event.title, errorMessage: null));
  }

  void _onCategorySelected(
    TransactionFormCategorySelected event,
    Emitter<TransactionFormState> emit,
  ) {
    emit(state.copyWith(categoryId: event.categoryId, errorMessage: null));
  }

  void _onAccountSelected(
    TransactionFormAccountSelected event,
    Emitter<TransactionFormState> emit,
  ) {
    // Auto-set currency to the account's default currency when account changes
    final account =
        state.availableAccounts
            .where((a) => a.id == event.accountId)
            .firstOrNull;
    final matchingCurrency =
        account != null
            ? state.availableCurrencies
                .where((c) => c.code == account.currency)
                .firstOrNull
            : null;
    emit(
      state.copyWith(
        accountId: event.accountId,
        selectedCurrencyCode:
            matchingCurrency?.code ?? state.selectedCurrencyCode,
        errorMessage: null,
      ),
    );
  }

  void _onToAccountSelected(
    TransactionFormToAccountSelected event,
    Emitter<TransactionFormState> emit,
  ) {
    emit(state.copyWith(toAccountId: event.accountId, errorMessage: null));
  }

  void _onCurrencySelected(
    TransactionFormCurrencySelected event,
    Emitter<TransactionFormState> emit,
  ) {
    emit(
      state.copyWith(
        selectedCurrencyCode: event.currencyCode,
        errorMessage: null,
      ),
    );
  }

  void _onDateChanged(
    TransactionFormDateChanged event,
    Emitter<TransactionFormState> emit,
  ) {
    emit(state.copyWith(date: event.date));
  }

  void _onNoteChanged(
    TransactionFormNoteChanged event,
    Emitter<TransactionFormState> emit,
  ) {
    emit(state.copyWith(note: event.note));
  }

  Future<void> _onSubmitted(
    TransactionFormSubmitted event,
    Emitter<TransactionFormState> emit,
  ) async {
    // Validate
    final amount = double.tryParse(state.amount);
    if (amount == null || amount <= 0) {
      emit(state.copyWith(errorMessage: 'Please enter a valid amount'));
      return;
    }
    if (state.title.trim().isEmpty) {
      emit(state.copyWith(errorMessage: 'Please enter a title'));
      return;
    }
    if (state.type != TransactionType.transfer && state.categoryId == null) {
      emit(state.copyWith(errorMessage: 'Please select a category'));
      return;
    }
    if (state.accountId == null) {
      emit(state.copyWith(errorMessage: 'Please select an account'));
      return;
    }
    if (state.type == TransactionType.transfer) {
      if (state.toAccountId == null) {
        emit(
          state.copyWith(errorMessage: 'Please select a destination account'),
        );
        return;
      }
      if (state.toAccountId == state.accountId) {
        emit(
          state.copyWith(
            errorMessage: 'Source and destination accounts must differ',
          ),
        );
        return;
      }
    }

    emit(state.copyWith(isSubmitting: true, errorMessage: null));

    final now = DateTime.now();
    final date = state.date ?? now;
    final amountCents = (amount * 100).round();
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    if (state.type == TransactionType.transfer) {
      final fromTransaction = TransactionEntity(
        id: 0,
        userId: event.userId,
        accountId: state.accountId!,
        categoryId: 0, // repository replaces with seeded Transfer category
        type: TransactionType.transfer,
        amountCents: amountCents,
        originalCurrencyCode: state.selectedCurrencyCode,
        originalAmountCents: amountCents,
        title: state.title.trim(),
        note: state.note.trim().isEmpty ? null : state.note.trim(),
        transactionDate: dateStr,
        createdAt: now,
        updatedAt: now,
      );

      final result = await _createTransfer(
        CreateTransferParams(
          fromTransaction: fromTransaction,
          toAccountId: state.toAccountId!,
        ),
      );

      result.fold(
        (failure) => emit(
          state.copyWith(
            isSubmitting: false,
            errorMessage: 'Failed to save transfer. Please try again.',
          ),
        ),
        (_) => emit(state.copyWith(isSubmitting: false, isSuccess: true)),
      );
    } else {
      final transaction = TransactionEntity(
        id: 0,
        userId: event.userId,
        accountId: state.accountId!,
        categoryId: state.categoryId!,
        type: state.type,
        amountCents: amountCents,
        originalCurrencyCode: state.selectedCurrencyCode,
        originalAmountCents: amountCents,
        title: state.title.trim(),
        note: state.note.trim().isEmpty ? null : state.note.trim(),
        transactionDate: dateStr,
        createdAt: now,
        updatedAt: now,
      );

      final result = await _createTransaction(transaction);

      result.fold(
        (failure) => emit(
          state.copyWith(
            isSubmitting: false,
            errorMessage: 'Failed to save transaction. Please try again.',
          ),
        ),
        (_) => emit(state.copyWith(isSubmitting: false, isSuccess: true)),
      );
    }
  }

  /// Returns categories filtered by the current transaction type.
  /// Returns an empty list for transfers (category is hidden).
  static List<CategoryEntity> filteredCategories(TransactionFormState state) {
    if (state.type == TransactionType.transfer) return [];
    final typeStr = state.type == TransactionType.income ? 'income' : 'expense';
    return state.allCategories.where((c) {
      return c.transactionType == CategoryTransactionType.both ||
          c.transactionType.name == typeStr;
    }).toList();
  }
}
