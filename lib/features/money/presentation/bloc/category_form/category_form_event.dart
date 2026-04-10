import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:track/features/money/domain/entities/category_entity.dart';

part 'category_form_event.freezed.dart';

@freezed
sealed class CategoryFormEvent with _$CategoryFormEvent {
  const factory CategoryFormEvent.initialized({
    required String userId,
    CategoryEntity? category,
  }) = CategoryFormInitialized;

  const factory CategoryFormEvent.nameChanged(String name) =
      CategoryFormNameChanged;
  const factory CategoryFormEvent.transactionTypeChanged(
    CategoryTransactionType transactionType,
  ) = CategoryFormTransactionTypeChanged;
  const factory CategoryFormEvent.iconChanged(String iconName) =
      CategoryFormIconChanged;
  const factory CategoryFormEvent.colorChanged(String colorHex) =
      CategoryFormColorChanged;
  const factory CategoryFormEvent.submitted() = CategoryFormSubmitted;
}
