import 'package:freezed_annotation/freezed_annotation.dart';

part 'currency_event.freezed.dart';

@freezed
sealed class CurrencyEvent with _$CurrencyEvent {
  const factory CurrencyEvent.started(String userId) = CurrencyStarted;
  const factory CurrencyEvent.deleteRequested(int currencyId) =
      CurrencyDeleteRequested;
}
