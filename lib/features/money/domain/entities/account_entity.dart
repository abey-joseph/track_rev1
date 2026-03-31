import 'package:freezed_annotation/freezed_annotation.dart';

part 'account_entity.freezed.dart';

enum AccountType { checking, savings, cash, creditCard, investment }

@freezed
abstract class AccountEntity with _$AccountEntity {
  const factory AccountEntity({
    required int id,
    required String userId,
    required String name,
    required AccountType type,

    /// Balance in **cents** (integer) to avoid floating-point errors.
    required int balanceCents,

    /// ISO 4217 currency code, e.g. 'USD'.
    required String currency,
    required String iconName,
    required String colorHex,
    required bool isDefault,
    required bool isArchived,
    required int sortOrder,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _AccountEntity;
}
