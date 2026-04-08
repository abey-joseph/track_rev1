import 'package:freezed_annotation/freezed_annotation.dart';

part 'currency_entity.freezed.dart';

@freezed
abstract class CurrencyEntity with _$CurrencyEntity {
  const factory CurrencyEntity({
    required int id,
    required String userId,

    /// Human-readable name, e.g. 'US Dollar'.
    required String name,

    /// ISO 4217 code, e.g. 'USD'.
    required String code,

    /// Symbol, e.g. '$'.
    required String symbol,

    /// Exchange rate relative to the default currency.
    /// The default currency always has a rate of 1.0.
    required double exchangeRate,

    required bool isDefault,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _CurrencyEntity;
}
