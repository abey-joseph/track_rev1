import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:track/features/money/domain/entities/category_entity.dart';
import 'package:track/features/money/domain/entities/transaction_entity.dart';
import 'package:track/features/money/domain/usecases/create_transaction.dart';
import 'package:track/features/money/domain/usecases/get_accounts.dart';
import 'package:track/features/money/domain/usecases/get_categories.dart';
import 'package:track/features/money/presentation/bloc/transaction_form_event.dart';
import 'package:track/features/money/presentation/bloc/transaction_form_state.dart';

@injectable
class TransactionFormBloc
    extends Bloc<TransactionFormEvent, TransactionFormState> {
  TransactionFormBloc(
    this._createTransaction,
    this._getAccounts,
    this._getCategories,
  ) : super(const TransactionFormState()) {
    on<TransactionFormInitialized>(_onInitialized);
    on<TransactionFormTypeChanged>(_onTypeChanged);
    on<TransactionFormAmountChanged>(_onAmountChanged);
    on<TransactionFormTitleChanged>(_onTitleChanged);
    on<TransactionFormCategorySelected>(_onCategorySelected);
    on<TransactionFormAccountSelected>(_onAccountSelected);
    on<TransactionFormDateChanged>(_onDateChanged);
    on<TransactionFormNoteChanged>(_onNoteChanged);
    on<TransactionFormSubmitted>(_onSubmitted);
  }

  final CreateTransaction _createTransaction;
  final GetAccounts _getAccounts;
  final GetCategories _getCategories;

  Future<void> _onInitialized(
    TransactionFormInitialized event,
    Emitter<TransactionFormState> emit,
  ) async {
    final accountsResult =
        await _getAccounts(UserIdParams(userId: event.userId));
    final categoriesResult =
        await _getCategories(UserIdParams(userId: event.userId));

    final accounts = accountsResult.getOrElse((_) => []);
    final categories = categoriesResult.getOrElse((_) => []);

    emit(state.copyWith(
      availableAccounts: accounts,
      allCategories: categories,
      accountId: accounts.isNotEmpty ? accounts.first.id : null,
      date: DateTime.now(),
    ));
  }

  void _onTypeChanged(
    TransactionFormTypeChanged event,
    Emitter<TransactionFormState> emit,
  ) {
    emit(state.copyWith(
      type: event.type,
      categoryId: null,
      errorMessage: null,
    ));
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
    emit(state.copyWith(accountId: event.accountId, errorMessage: null));
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
    if (state.categoryId == null) {
      emit(state.copyWith(errorMessage: 'Please select a category'));
      return;
    }
    if (state.accountId == null) {
      emit(state.copyWith(errorMessage: 'Please select an account'));
      return;
    }

    emit(state.copyWith(isSubmitting: true, errorMessage: null));

    final now = DateTime.now();
    final date = state.date ?? now;
    final amountCents = (amount * 100).round();

    final transaction = TransactionEntity(
      id: 0,
      userId: event.userId,
      accountId: state.accountId!,
      categoryId: state.categoryId!,
      type: state.type,
      amountCents: amountCents,
      title: state.title.trim(),
      note: state.note.trim().isEmpty ? null : state.note.trim(),
      transactionDate:
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      createdAt: now,
      updatedAt: now,
    );

    final result = await _createTransaction(transaction);

    result.fold(
      (failure) => emit(state.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to save transaction. Please try again.',
      )),
      (_) => emit(state.copyWith(isSubmitting: false, isSuccess: true)),
    );
  }

  /// Returns categories filtered by the current transaction type.
  static List<CategoryEntity> filteredCategories(TransactionFormState state) {
    final typeStr = state.type == TransactionType.income ? 'income' : 'expense';
    return state.allCategories.where((c) {
      return c.transactionType == CategoryTransactionType.both ||
          c.transactionType.name == typeStr;
    }).toList();
  }
}
