import 'package:freezed_annotation/freezed_annotation.dart';

part 'category_entity.freezed.dart';

enum CategoryTransactionType { income, expense, both }

@freezed
abstract class CategoryEntity with _$CategoryEntity {
  const factory CategoryEntity({
    required int id,

    required String name,
    required CategoryTransactionType transactionType,
    required String iconName,
    required String colorHex,
    required bool isDefault,
    required int sortOrder,
    required DateTime createdAt,

    /// Null = system default (visible to all users).
    String? userId,
  }) = _CategoryEntity;
}
