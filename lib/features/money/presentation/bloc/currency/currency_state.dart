import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/features/money/domain/entities/currency_entity.dart';

part 'currency_state.freezed.dart';

@freezed
sealed class CurrencyState with _$CurrencyState {
  const factory CurrencyState.initial() = CurrencyInitial;
  const factory CurrencyState.loading() = CurrencyLoading;
  const factory CurrencyState.loaded({
    required List<CurrencyEntity> currencies,
    String? deleteError,
  }) = CurrencyLoaded;
  const factory CurrencyState.error({required Failure failure}) = CurrencyError;
}
