import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:track/features/money/domain/usecases/delete_recurring_transaction.dart';
import 'package:track/features/money/domain/usecases/get_accounts.dart';
import 'package:track/features/money/domain/usecases/process_due_recurring_transactions.dart';
import 'package:track/features/money/domain/usecases/watch_recurring_transactions.dart';
import 'package:track/features/money/presentation/bloc/recurring_transactions/recurring_transactions_event.dart';
import 'package:track/features/money/presentation/bloc/recurring_transactions/recurring_transactions_state.dart';

@injectable
class RecurringTransactionsBloc
    extends Bloc<RecurringTransactionsEvent, RecurringTransactionsState> {
  RecurringTransactionsBloc(
    this._watchRecurringTransactions,
    this._deleteRecurringTransaction,
    this._processDueRecurringTransactions,
  ) : super(const RecurringTransactionsState.initial()) {
    on<RecurringTransactionsStarted>(_onStarted);
    on<RecurringTransactionsDeleteRequested>(_onDeleteRequested);
  }

  final WatchRecurringTransactions _watchRecurringTransactions;
  final DeleteRecurringTransaction _deleteRecurringTransaction;
  final ProcessDueRecurringTransactions _processDueRecurringTransactions;
  Future<void> _onStarted(
    RecurringTransactionsStarted event,
    Emitter<RecurringTransactionsState> emit,
  ) async {
    emit(const RecurringTransactionsState.loading());

    // Process due recurring transactions before watching.
    await _processDueRecurringTransactions(
      ProcessDueParams(userId: event.userId, now: DateTime.now()),
    );

    await emit.forEach(
      _watchRecurringTransactions(
        UserIdParams(userId: event.userId),
      ),
      onData:
          (result) => result.fold(
            (failure) => RecurringTransactionsState.error(failure: failure),
            (items) => RecurringTransactionsState.loaded(
              recurringTransactions: items,
            ),
          ),
    );
  }

  Future<void> _onDeleteRequested(
    RecurringTransactionsDeleteRequested event,
    Emitter<RecurringTransactionsState> emit,
  ) async {
    final current = state;
    if (current is! RecurringTransactionsLoaded) return;

    final result = await _deleteRecurringTransaction(
      DeleteRecurringTransactionParams(id: event.id),
    );

    result.fold(
      (failure) => emit(
        current.copyWith(
          deleteError: 'Failed to delete. Please try again.',
        ),
      ),
      (_) {
        if (current.deleteError != null) {
          emit(current.copyWith(deleteError: null));
        }
      },
    );
  }
}
