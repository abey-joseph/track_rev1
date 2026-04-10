import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:track/features/money/domain/entities/category_entity.dart';
import 'package:track/features/money/domain/entities/recurring_transaction_entity.dart';
import 'package:track/features/money/domain/entities/transaction_entity.dart';
import 'package:track/features/money/domain/usecases/create_recurring_transaction.dart';
import 'package:track/features/money/domain/usecases/get_accounts.dart';
import 'package:track/features/money/domain/usecases/get_categories.dart';
import 'package:track/features/money/domain/usecases/update_recurring_transaction.dart';
import 'package:track/features/money/presentation/bloc/recurring_transaction_form/recurring_transaction_form_event.dart';
import 'package:track/features/money/presentation/bloc/recurring_transaction_form/recurring_transaction_form_state.dart';

@injectable
class RecurringTransactionFormBloc
    extends Bloc<RecurringTransactionFormEvent, RecurringTransactionFormState> {
  RecurringTransactionFormBloc(
    this._createRecurringTransaction,
    this._updateRecurringTransaction,
    this._getAccounts,
    this._getCategories,
  ) : super(const RecurringTransactionFormState()) {
    on<RecurringTransactionFormInitialized>(_onInitialized);
    on<RecurringTransactionFormTypeChanged>(_onTypeChanged);
    on<RecurringTransactionFormAmountChanged>(_onAmountChanged);
    on<RecurringTransactionFormTitleChanged>(_onTitleChanged);
    on<RecurringTransactionFormCategorySelected>(_onCategorySelected);
    on<RecurringTransactionFormAccountSelected>(_onAccountSelected);
    on<RecurringTransactionFormNoteChanged>(_onNoteChanged);
    on<RecurringTransactionFormScheduleTypeChanged>(
      _onScheduleTypeChanged,
    );
    on<RecurringTransactionFormStartDateChanged>(_onStartDateChanged);
    on<RecurringTransactionFormWeekdaysChanged>(_onWeekdaysChanged);
    on<RecurringTransactionFormMonthDayChanged>(_onMonthDayChanged);
    on<RecurringTransactionFormMonthDaysChanged>(_onMonthDaysChanged);
    on<RecurringTransactionFormTimesPerMonthChanged>(
      _onTimesPerMonthChanged,
    );
    on<RecurringTransactionFormSubmitted>(_onSubmitted);
  }

  final CreateRecurringTransaction _createRecurringTransaction;
  final UpdateRecurringTransaction _updateRecurringTransaction;
  final GetAccounts _getAccounts;
  final GetCategories _getCategories;

  Future<void> _onInitialized(
    RecurringTransactionFormInitialized event,
    Emitter<RecurringTransactionFormState> emit,
  ) async {
    final accountsResult = await _getAccounts(
      UserIdParams(userId: event.userId),
    );
    final categoriesResult = await _getCategories(
      UserIdParams(userId: event.userId),
    );

    final accounts = accountsResult.getOrElse((_) => []);
    final categories = categoriesResult.getOrElse((_) => []);

    if (event.existing != null) {
      final e = event.existing!;
      emit(
        state.copyWith(
          type: e.type,
          amount: (e.amountCents / 100).toStringAsFixed(
            e.amountCents % 100 == 0 ? 0 : 2,
          ),
          title: e.title,
          categoryId: e.categoryId,
          accountId: e.accountId,
          note: e.note ?? '',
          scheduleType: e.scheduleType,
          startDate: DateTime.parse(e.startDate),
          weekdays: e.weekdays,
          monthDay: e.monthDay,
          monthDays: e.monthDays,
          timesPerMonth: e.timesPerMonth,
          allCategories: categories,
          availableAccounts: accounts,
          isEditMode: true,
          existingId: e.id,
          existingIsCompleted: e.isCompleted,
        ),
      );
    } else {
      emit(
        state.copyWith(
          availableAccounts: accounts,
          allCategories: categories,
          accountId: accounts.isNotEmpty ? accounts.first.id : null,
          startDate: DateTime.now(),
        ),
      );
    }
  }

  void _onTypeChanged(
    RecurringTransactionFormTypeChanged event,
    Emitter<RecurringTransactionFormState> emit,
  ) {
    emit(
      state.copyWith(
        type: event.type,
        categoryId: null,
        errorMessage: null,
      ),
    );
  }

  void _onAmountChanged(
    RecurringTransactionFormAmountChanged event,
    Emitter<RecurringTransactionFormState> emit,
  ) {
    emit(state.copyWith(amount: event.amount, errorMessage: null));
  }

  void _onTitleChanged(
    RecurringTransactionFormTitleChanged event,
    Emitter<RecurringTransactionFormState> emit,
  ) {
    emit(state.copyWith(title: event.title, errorMessage: null));
  }

  void _onCategorySelected(
    RecurringTransactionFormCategorySelected event,
    Emitter<RecurringTransactionFormState> emit,
  ) {
    emit(
      state.copyWith(
        categoryId: event.categoryId,
        errorMessage: null,
      ),
    );
  }

  void _onAccountSelected(
    RecurringTransactionFormAccountSelected event,
    Emitter<RecurringTransactionFormState> emit,
  ) {
    emit(
      state.copyWith(
        accountId: event.accountId,
        errorMessage: null,
      ),
    );
  }

  void _onNoteChanged(
    RecurringTransactionFormNoteChanged event,
    Emitter<RecurringTransactionFormState> emit,
  ) {
    emit(state.copyWith(note: event.note));
  }

  void _onScheduleTypeChanged(
    RecurringTransactionFormScheduleTypeChanged event,
    Emitter<RecurringTransactionFormState> emit,
  ) {
    emit(
      state.copyWith(
        scheduleType: event.scheduleType,
        errorMessage: null,
      ),
    );
  }

  void _onStartDateChanged(
    RecurringTransactionFormStartDateChanged event,
    Emitter<RecurringTransactionFormState> emit,
  ) {
    emit(state.copyWith(startDate: event.date));
  }

  void _onWeekdaysChanged(
    RecurringTransactionFormWeekdaysChanged event,
    Emitter<RecurringTransactionFormState> emit,
  ) {
    emit(state.copyWith(weekdays: event.weekdays));
  }

  void _onMonthDayChanged(
    RecurringTransactionFormMonthDayChanged event,
    Emitter<RecurringTransactionFormState> emit,
  ) {
    emit(state.copyWith(monthDay: event.day));
  }

  void _onMonthDaysChanged(
    RecurringTransactionFormMonthDaysChanged event,
    Emitter<RecurringTransactionFormState> emit,
  ) {
    emit(state.copyWith(monthDays: event.days));
  }

  void _onTimesPerMonthChanged(
    RecurringTransactionFormTimesPerMonthChanged event,
    Emitter<RecurringTransactionFormState> emit,
  ) {
    // Reset monthDays when count changes.
    emit(
      state.copyWith(timesPerMonth: event.count, monthDays: const []),
    );
  }

  Future<void> _onSubmitted(
    RecurringTransactionFormSubmitted event,
    Emitter<RecurringTransactionFormState> emit,
  ) async {
    // Validate
    final amount = double.tryParse(state.amount);
    if (amount == null || amount <= 0) {
      emit(
        state.copyWith(errorMessage: 'Please enter a valid amount'),
      );
      return;
    }
    if (state.title.trim().isEmpty) {
      emit(state.copyWith(errorMessage: 'Please enter a title'));
      return;
    }
    if (state.categoryId == null) {
      emit(
        state.copyWith(errorMessage: 'Please select a category'),
      );
      return;
    }
    if (state.accountId == null) {
      emit(
        state.copyWith(errorMessage: 'Please select an account'),
      );
      return;
    }
    if (state.startDate == null) {
      emit(
        state.copyWith(errorMessage: 'Please select a start date'),
      );
      return;
    }

    // Schedule-type-specific validation
    if (state.scheduleType == RecurringScheduleType.weekly &&
        state.weekdays.isEmpty) {
      emit(
        state.copyWith(
          errorMessage: 'Please select at least one weekday',
        ),
      );
      return;
    }
    if (state.scheduleType == RecurringScheduleType.monthlyFixed &&
        state.monthDay == null) {
      emit(
        state.copyWith(
          errorMessage: 'Please select a day of the month',
        ),
      );
      return;
    }
    if (state.scheduleType == RecurringScheduleType.monthlyMultiple) {
      if (state.timesPerMonth == null || state.timesPerMonth! < 1) {
        emit(
          state.copyWith(
            errorMessage: 'Please set times per month',
          ),
        );
        return;
      }
      if (state.monthDays.length != state.timesPerMonth) {
        emit(
          state.copyWith(
            errorMessage: 'Please select exactly ${state.timesPerMonth} days',
          ),
        );
        return;
      }
    }

    emit(state.copyWith(isSubmitting: true, errorMessage: null));

    final now = DateTime.now();
    final startDate = state.startDate!;
    final amountCents = (amount * 100).round();

    final startDateStr =
        '${startDate.year.toString().padLeft(4, '0')}-'
        '${startDate.month.toString().padLeft(2, '0')}-'
        '${startDate.day.toString().padLeft(2, '0')}';

    // For completed once-type being moved to the future, reset status.
    final isFutureOnce =
        state.scheduleType == RecurringScheduleType.once &&
        startDate.isAfter(DateTime(now.year, now.month, now.day));
    final resetCompleted =
        state.isEditMode && state.existingIsCompleted && isFutureOnce;

    final entity = RecurringTransactionEntity(
      id: state.existingId ?? 0,
      userId: event.userId,
      accountId: state.accountId!,
      categoryId: state.categoryId!,
      type: state.type,
      amountCents: amountCents,
      title: state.title.trim(),
      note: state.note.trim().isEmpty ? null : state.note.trim(),
      scheduleType: state.scheduleType,
      startDate: startDateStr,
      weekdays: state.weekdays,
      monthDay: state.monthDay,
      monthDays: state.monthDays,
      timesPerMonth: state.timesPerMonth,
      isActive: resetCompleted || !state.existingIsCompleted,
      isCompleted: !resetCompleted && state.existingIsCompleted,
      createdAt: now,
      updatedAt: now,
    );

    final result =
        state.isEditMode
            ? await _updateRecurringTransaction(entity)
            : await _createRecurringTransaction(entity);

    result.fold(
      (failure) => emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: 'Failed to save. Please try again.',
        ),
      ),
      (_) => emit(
        state.copyWith(isSubmitting: false, isSuccess: true),
      ),
    );
  }

  /// Returns categories filtered by the current transaction type.
  static List<CategoryEntity> filteredCategories(
    RecurringTransactionFormState state,
  ) {
    final typeStr = state.type == TransactionType.income ? 'income' : 'expense';
    return state.allCategories.where((c) {
      return c.transactionType == CategoryTransactionType.both ||
          c.transactionType.name == typeStr;
    }).toList();
  }
}
