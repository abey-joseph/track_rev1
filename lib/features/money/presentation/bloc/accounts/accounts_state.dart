import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/features/money/domain/entities/account_entity.dart';

part 'accounts_state.freezed.dart';

@freezed
sealed class AccountsState with _$AccountsState {
  const factory AccountsState.initial() = AccountsInitial;
  const factory AccountsState.loading() = AccountsLoading;
  const factory AccountsState.loaded({
    required List<AccountEntity> accounts,
    String? deleteError,
  }) = AccountsLoaded;
  const factory AccountsState.error({required Failure failure}) = AccountsError;
}
