import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:track/features/money/domain/entities/currency_entity.dart';

part 'currency_form_event.freezed.dart';

@freezed
sealed class CurrencyFormEvent with _$CurrencyFormEvent {
  const factory CurrencyFormEvent.initialized({
    required String userId,
    CurrencyEntity? currency,
    String? defaultCurrencyCode,
  }) = CurrencyFormInitialized;

  const factory CurrencyFormEvent.nameChanged(String name) =
      CurrencyFormNameChanged;
  const factory CurrencyFormEvent.codeChanged(String code) =
      CurrencyFormCodeChanged;
  const factory CurrencyFormEvent.symbolChanged(String symbol) =
      CurrencyFormSymbolChanged;
  const factory CurrencyFormEvent.exchangeRateChanged(String exchangeRate) =
      CurrencyFormExchangeRateChanged;
  const factory CurrencyFormEvent.submitted() = CurrencyFormSubmitted;
}
