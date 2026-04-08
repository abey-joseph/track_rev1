import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:track/features/money/domain/entities/currency_entity.dart';
import 'package:track/features/money/domain/usecases/create_currency.dart';
import 'package:track/features/money/domain/usecases/update_currency.dart';
import 'package:track/features/money/presentation/bloc/currency_form/currency_form_event.dart';
import 'package:track/features/money/presentation/bloc/currency_form/currency_form_state.dart';

@injectable
class CurrencyFormBloc extends Bloc<CurrencyFormEvent, CurrencyFormState> {
  CurrencyFormBloc(
    this._createCurrency,
    this._updateCurrency,
  ) : super(const CurrencyFormState()) {
    on<CurrencyFormInitialized>(_onInitialized);
    on<CurrencyFormNameChanged>(_onNameChanged);
    on<CurrencyFormCodeChanged>(_onCodeChanged);
    on<CurrencyFormSymbolChanged>(_onSymbolChanged);
    on<CurrencyFormExchangeRateChanged>(_onExchangeRateChanged);
    on<CurrencyFormSubmitted>(_onSubmitted);
  }

  final CreateCurrency _createCurrency;
  final UpdateCurrency _updateCurrency;
  String? _userId;

  void _onInitialized(
    CurrencyFormInitialized event,
    Emitter<CurrencyFormState> emit,
  ) {
    _userId = event.userId;

    if (event.currency != null) {
      final c = event.currency!;
      emit(
        state.copyWith(
          isEditMode: true,
          initialCurrency: c,
          isDefault: c.isDefault,
          name: c.name,
          code: c.code,
          symbol: c.symbol,
          exchangeRateText:
              c.isDefault ? '1' : c.exchangeRate.toStringAsFixed(4),
          defaultCurrencyCode: event.defaultCurrencyCode,
        ),
      );
    } else {
      emit(
        state.copyWith(defaultCurrencyCode: event.defaultCurrencyCode),
      );
    }
  }

  void _onNameChanged(
    CurrencyFormNameChanged event,
    Emitter<CurrencyFormState> emit,
  ) {
    emit(state.copyWith(name: event.name, errorMessage: null));
  }

  void _onCodeChanged(
    CurrencyFormCodeChanged event,
    Emitter<CurrencyFormState> emit,
  ) {
    emit(
      state.copyWith(
        code: event.code.toUpperCase(),
        errorMessage: null,
      ),
    );
  }

  void _onSymbolChanged(
    CurrencyFormSymbolChanged event,
    Emitter<CurrencyFormState> emit,
  ) {
    emit(state.copyWith(symbol: event.symbol, errorMessage: null));
  }

  void _onExchangeRateChanged(
    CurrencyFormExchangeRateChanged event,
    Emitter<CurrencyFormState> emit,
  ) {
    emit(
      state.copyWith(exchangeRateText: event.exchangeRate, errorMessage: null),
    );
  }

  Future<void> _onSubmitted(
    CurrencyFormSubmitted event,
    Emitter<CurrencyFormState> emit,
  ) async {
    if (state.name.trim().isEmpty) {
      emit(state.copyWith(errorMessage: 'Please enter a currency name'));
      return;
    }
    if (state.code.trim().isEmpty) {
      emit(state.copyWith(errorMessage: 'Please enter a currency code'));
      return;
    }
    if (state.symbol.trim().isEmpty) {
      emit(state.copyWith(errorMessage: 'Please enter a currency symbol'));
      return;
    }

    final rate = double.tryParse(state.exchangeRateText);
    if (!state.isDefault) {
      if (rate == null || rate <= 0) {
        emit(
          state.copyWith(
            errorMessage: 'Please enter a valid exchange rate',
          ),
        );
        return;
      }
    }

    if (_userId == null) return;

    emit(state.copyWith(isSubmitting: true, errorMessage: null));

    final now = DateTime.now();
    final isEdit = state.isEditMode && state.initialCurrency != null;

    final currency = CurrencyEntity(
      id: isEdit ? state.initialCurrency!.id : 0,
      userId: _userId!,
      name: state.name.trim(),
      code: state.code.trim().toUpperCase(),
      symbol: state.symbol.trim(),
      exchangeRate: state.isDefault ? 1.0 : (rate ?? 1.0),
      isDefault: isEdit && state.initialCurrency!.isDefault,
      createdAt: isEdit ? state.initialCurrency!.createdAt : now,
      updatedAt: now,
    );

    final result =
        isEdit
            ? await _updateCurrency(currency)
            : await _createCurrency(currency);

    result.fold(
      (_) => emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: 'Failed to save currency. Please try again.',
        ),
      ),
      (_) => emit(state.copyWith(isSubmitting: false, isSuccess: true)),
    );
  }
}
