import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:track/features/money/domain/entities/category_entity.dart';

part 'category_form_state.freezed.dart';

@freezed
abstract class CategoryFormState with _$CategoryFormState {
  const factory CategoryFormState({
    @Default('') String name,
    @Default(CategoryTransactionType.expense)
    CategoryTransactionType transactionType,
    @Default('restaurant') String iconName,
    @Default('#4CAF50') String colorHex,
    @Default(false) bool isEditMode,
    @Default(false) bool isSubmitting,
    @Default(false) bool isSuccess,
    CategoryEntity? initialCategory,
    String? errorMessage,
  }) = _CategoryFormState;
}
