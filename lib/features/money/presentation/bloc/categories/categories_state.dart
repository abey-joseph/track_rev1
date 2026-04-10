import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/features/money/domain/entities/category_entity.dart';

part 'categories_state.freezed.dart';

@freezed
sealed class CategoriesState with _$CategoriesState {
  const factory CategoriesState.initial() = CategoriesInitial;
  const factory CategoriesState.loading() = CategoriesLoading;
  const factory CategoriesState.loaded({
    required List<CategoryEntity> categories,
    String? deleteError,
  }) = CategoriesLoaded;
  const factory CategoriesState.error({required Failure failure}) =
      CategoriesError;
}
