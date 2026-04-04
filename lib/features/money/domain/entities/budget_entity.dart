import 'package:freezed_annotation/freezed_annotation.dart';

part 'budget_entity.freezed.dart';

enum BudgetPeriod { monthly, weekly }

@freezed
abstract class BudgetEntity with _$BudgetEntity {
  const factory BudgetEntity({
    required int id,
    required String userId,
    required String name,

    /// Budget limit in **cents**.
    required int amountLimitCents,
    required BudgetPeriod period,
    required bool isActive,
    required DateTime createdAt,
    required DateTime updatedAt,

    /// Null = overall budget across all categories.
    int? categoryId,
  }) = _BudgetEntity;
}
