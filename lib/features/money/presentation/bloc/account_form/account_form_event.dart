import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:track/features/money/domain/entities/account_entity.dart';

part 'account_form_event.freezed.dart';

@freezed
sealed class AccountFormEvent with _$AccountFormEvent {
  const factory AccountFormEvent.initialized({
    required String userId,
    AccountEntity? account,
  }) = AccountFormInitialized;

  const factory AccountFormEvent.nameChanged(String name) =
      AccountFormNameChanged;
  const factory AccountFormEvent.descriptionChanged(String description) =
      AccountFormDescriptionChanged;
  const factory AccountFormEvent.currencyChanged(String currencyCode) =
      AccountFormCurrencyChanged;
  const factory AccountFormEvent.iconChanged(String iconName) =
      AccountFormIconChanged;
  const factory AccountFormEvent.colorChanged(String colorHex) =
      AccountFormColorChanged;
  const factory AccountFormEvent.submitted() = AccountFormSubmitted;
}
