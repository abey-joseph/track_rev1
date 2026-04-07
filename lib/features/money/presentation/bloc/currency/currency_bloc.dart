import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/features/money/domain/usecases/delete_currency.dart';
import 'package:track/features/money/domain/usecases/get_accounts.dart';
import 'package:track/features/money/domain/usecases/watch_currencies.dart';
import 'package:track/features/money/presentation/bloc/currency/currency_event.dart';
import 'package:track/features/money/presentation/bloc/currency/currency_state.dart';

@injectable
class CurrencyBloc extends Bloc<CurrencyEvent, CurrencyState> {
  CurrencyBloc(
    this._watchCurrencies,
    this._deleteCurrency,
  ) : super(const CurrencyState.initial()) {
    on<CurrencyStarted>(_onStarted);
    on<CurrencyDeleteRequested>(_onDeleteRequested);
  }

  final WatchCurrencies _watchCurrencies;
  final DeleteCurrency _deleteCurrency;
  String? _currentUserId;

  Future<void> _onStarted(
    CurrencyStarted event,
    Emitter<CurrencyState> emit,
  ) async {
    _currentUserId = event.userId;
    emit(const CurrencyState.loading());

    await emit.forEach(
      _watchCurrencies(UserIdParams(userId: event.userId)),
      onData:
          (result) => result.fold(
            (failure) => CurrencyState.error(failure: failure),
            (currencies) => CurrencyState.loaded(currencies: currencies),
          ),
    );
  }

  Future<void> _onDeleteRequested(
    CurrencyDeleteRequested event,
    Emitter<CurrencyState> emit,
  ) async {
    final current = state;
    if (current is! CurrencyLoaded || _currentUserId == null) return;

    final result = await _deleteCurrency(
      DeleteCurrencyParams(
        currencyId: event.currencyId,
        userId: _currentUserId!,
      ),
    );

    result.fold(
      (failure) {
        final message = switch (failure) {
          CacheFailure(:final message) => message,
          _ => 'Failed to delete currency. Please try again.',
        };
        emit(current.copyWith(deleteError: message));
      },
      (_) {
        if (current.deleteError != null) {
          emit(current.copyWith(deleteError: null));
        }
      },
    );
  }
}
