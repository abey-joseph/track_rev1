import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:track/features/money/domain/entities/account_entity.dart';
import 'package:track/features/money/domain/entities/currency_entity.dart';
import 'package:track/features/money/domain/usecases/create_account.dart';
import 'package:track/features/money/domain/usecases/get_accounts.dart';
import 'package:track/features/money/domain/usecases/update_account.dart';
import 'package:track/features/money/domain/usecases/watch_currencies.dart';
import 'package:track/features/money/presentation/bloc/account_form/account_form_event.dart';
import 'package:track/features/money/presentation/bloc/account_form/account_form_state.dart';

@injectable
class AccountFormBloc extends Bloc<AccountFormEvent, AccountFormState> {
  AccountFormBloc(
    this._createAccount,
    this._updateAccount,
    this._watchCurrencies,
  ) : super(const AccountFormState()) {
    on<AccountFormInitialized>(_onInitialized);
    on<AccountFormNameChanged>(_onNameChanged);
    on<AccountFormDescriptionChanged>(_onDescriptionChanged);
    on<AccountFormCurrencyChanged>(_onCurrencyChanged);
    on<AccountFormIconChanged>(_onIconChanged);
    on<AccountFormColorChanged>(_onColorChanged);
    on<AccountFormSubmitted>(_onSubmitted);
  }

  final CreateAccount _createAccount;
  final UpdateAccount _updateAccount;
  final WatchCurrencies _watchCurrencies;
  String? _userId;

  Future<void> _onInitialized(
    AccountFormInitialized event,
    Emitter<AccountFormState> emit,
  ) async {
    _userId = event.userId;

    final currencyStream = _watchCurrencies(
      UserIdParams(userId: event.userId),
    );
    final currenciesResult = await currencyStream.first;
    final currencyList = currenciesResult.getOrElse((_) => []);

    if (event.account != null) {
      final a = event.account!;
      emit(
        state.copyWith(
          isEditMode: true,
          initialAccount: a,
          name: a.name,
          description: a.description ?? '',
          currencyCode: a.currency,
          iconName: a.iconName,
          colorHex: a.colorHex,
          availableCurrencies: currencyList,
        ),
      );
    } else {
      final defaultCode =
          currencyList
              .firstWhere(
                (c) => c.isDefault,
                orElse:
                    () =>
                        currencyList.isNotEmpty
                            ? currencyList.first
                            : _usdPlaceholder,
              )
              .code;

      emit(
        state.copyWith(
          availableCurrencies: currencyList,
          currencyCode: defaultCode,
        ),
      );
    }
  }

  void _onNameChanged(
    AccountFormNameChanged event,
    Emitter<AccountFormState> emit,
  ) {
    emit(state.copyWith(name: event.name, errorMessage: null));
  }

  void _onDescriptionChanged(
    AccountFormDescriptionChanged event,
    Emitter<AccountFormState> emit,
  ) {
    emit(state.copyWith(description: event.description));
  }

  void _onCurrencyChanged(
    AccountFormCurrencyChanged event,
    Emitter<AccountFormState> emit,
  ) {
    emit(state.copyWith(currencyCode: event.currencyCode));
  }

  void _onIconChanged(
    AccountFormIconChanged event,
    Emitter<AccountFormState> emit,
  ) {
    emit(state.copyWith(iconName: event.iconName));
  }

  void _onColorChanged(
    AccountFormColorChanged event,
    Emitter<AccountFormState> emit,
  ) {
    emit(state.copyWith(colorHex: event.colorHex));
  }

  Future<void> _onSubmitted(
    AccountFormSubmitted event,
    Emitter<AccountFormState> emit,
  ) async {
    if (state.name.trim().isEmpty) {
      emit(state.copyWith(errorMessage: 'Please enter an account name'));
      return;
    }
    if (_userId == null) return;

    emit(state.copyWith(isSubmitting: true, errorMessage: null));

    final now = DateTime.now();
    final isEdit = state.isEditMode && state.initialAccount != null;

    final account = AccountEntity(
      id: isEdit ? state.initialAccount!.id : 0,
      userId: _userId!,
      name: state.name.trim(),
      type: isEdit ? state.initialAccount!.type : AccountType.checking,
      balanceCents: isEdit ? state.initialAccount!.balanceCents : 0,
      currency: state.currencyCode,
      iconName: state.iconName,
      colorHex: state.colorHex,
      isDefault: isEdit ? state.initialAccount!.isDefault : false,
      isArchived: false,
      sortOrder: isEdit ? state.initialAccount!.sortOrder : 0,
      createdAt: isEdit ? state.initialAccount!.createdAt : now,
      updatedAt: now,
      description:
          state.description.trim().isEmpty ? null : state.description.trim(),
    );

    final result =
        isEdit ? await _updateAccount(account) : await _createAccount(account);

    result.fold(
      (_) => emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: 'Failed to save account. Please try again.',
        ),
      ),
      (_) => emit(state.copyWith(isSubmitting: false, isSuccess: true)),
    );
  }
}

// Placeholder used only when no currencies are loaded yet.
final _usdPlaceholder = CurrencyEntity(
  id: 0,
  userId: '',
  name: 'US Dollar',
  code: 'USD',
  symbol: r'$',
  exchangeRate: 1,
  isDefault: true,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);
