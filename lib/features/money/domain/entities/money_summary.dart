import 'package:freezed_annotation/freezed_annotation.dart';

part 'money_summary.freezed.dart';

@freezed
abstract class MoneySummary with _$MoneySummary {
  const factory MoneySummary({
    required int totalIncomeCents,
    required int totalExpenseCents,
    required List<CategorySpending> topCategories,
  }) = _MoneySummary;
}

@freezed
abstract class CategorySpending with _$CategorySpending {
  const factory CategorySpending({
    required int categoryId,
    required String name,
    required String iconName,
    required String colorHex,
    required int amountCents,
  }) = _CategorySpending;
}
