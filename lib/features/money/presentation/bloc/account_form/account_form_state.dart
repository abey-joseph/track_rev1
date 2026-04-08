import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:track/features/money/domain/entities/account_entity.dart';
import 'package:track/features/money/domain/entities/currency_entity.dart';

part 'account_form_state.freezed.dart';

@freezed
abstract class AccountFormState with _$AccountFormState {
  const factory AccountFormState({
    @Default('') String name,
    @Default('') String description,
    @Default('USD') String currencyCode,
    @Default('account_balance') String iconName,
    @Default('#2196F3') String colorHex,
    @Default([]) List<CurrencyEntity> availableCurrencies,
    @Default(false) bool isEditMode,
    @Default(false) bool isSubmitting,
    @Default(false) bool isSuccess,
    AccountEntity? initialAccount,
    String? errorMessage,
  }) = _AccountFormState;
}
