import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:track/features/money/domain/usecases/delete_account.dart';
import 'package:track/features/money/domain/usecases/get_accounts.dart';
import 'package:track/features/money/domain/usecases/set_default_account.dart';
import 'package:track/features/money/domain/usecases/watch_accounts.dart';
import 'package:track/features/money/presentation/bloc/accounts/accounts_event.dart';
import 'package:track/features/money/presentation/bloc/accounts/accounts_state.dart';

@injectable
class AccountsBloc extends Bloc<AccountsEvent, AccountsState> {
  AccountsBloc(
    this._watchAccounts,
    this._deleteAccount,
    this._setDefaultAccount,
  ) : super(const AccountsState.initial()) {
    on<AccountsStarted>(_onStarted);
    on<AccountsDeleteRequested>(_onDeleteRequested);
    on<AccountsDefaultSetRequested>(_onDefaultSetRequested);
  }

  final WatchAccounts _watchAccounts;
  final DeleteAccount _deleteAccount;
  final SetDefaultAccount _setDefaultAccount;
  String? _currentUserId;

  Future<void> _onStarted(
    AccountsStarted event,
    Emitter<AccountsState> emit,
  ) async {
    _currentUserId = event.userId;
    emit(const AccountsState.loading());

    await emit.forEach(
      _watchAccounts(UserIdParams(userId: event.userId)),
      onData:
          (result) => result.fold(
            (failure) => AccountsState.error(failure: failure),
            (accounts) => AccountsState.loaded(accounts: accounts),
          ),
    );
  }

  Future<void> _onDeleteRequested(
    AccountsDeleteRequested event,
    Emitter<AccountsState> emit,
  ) async {
    final current = state;
    if (current is! AccountsLoaded || _currentUserId == null) return;

    final result = await _deleteAccount(
      DeleteAccountParams(
        accountId: event.accountId,
        userId: _currentUserId!,
      ),
    );

    result.fold(
      (failure) => emit(
        current.copyWith(
          deleteError: 'Failed to delete account. Please try again.',
        ),
      ),
      (_) {
        // Stream updates will refresh the list automatically.
        // Clear any previous error.
        if (current.deleteError != null) {
          emit(current.copyWith(deleteError: null));
        }
      },
    );
  }

  Future<void> _onDefaultSetRequested(
    AccountsDefaultSetRequested event,
    Emitter<AccountsState> emit,
  ) async {
    if (_currentUserId == null) return;

    await _setDefaultAccount(
      SetDefaultAccountParams(
        accountId: event.accountId,
        userId: _currentUserId!,
      ),
    );
    // Stream refreshes list automatically.
  }
}
