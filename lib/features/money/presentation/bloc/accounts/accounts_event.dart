import 'package:freezed_annotation/freezed_annotation.dart';

part 'accounts_event.freezed.dart';

@freezed
sealed class AccountsEvent with _$AccountsEvent {
  const factory AccountsEvent.started(String userId) = AccountsStarted;
  const factory AccountsEvent.deleteRequested(int accountId) =
      AccountsDeleteRequested;
  const factory AccountsEvent.defaultSetRequested(int accountId) =
      AccountsDefaultSetRequested;
}
