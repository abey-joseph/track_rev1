import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:track/features/money/domain/entities/currency_entity.dart';

part 'currency_form_state.freezed.dart';

@freezed
abstract class CurrencyFormState with _$CurrencyFormState {
  const factory CurrencyFormState({
    @Default('') String name,
    @Default('') String code,
    @Default('') String symbol,

    /// Text representation of the exchange rate vs default currency.
    @Default('') String exchangeRateText,

    @Default(false) bool isEditMode,
    @Default(false) bool isDefault,
    @Default(false) bool isSubmitting,
    @Default(false) bool isSuccess,

    /// ISO code of the user's default currency, e.g. 'USD'.
    String? defaultCurrencyCode,

    CurrencyEntity? initialCurrency,
    String? errorMessage,
  }) = _CurrencyFormState;
}
