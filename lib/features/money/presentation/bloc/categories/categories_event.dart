import 'package:freezed_annotation/freezed_annotation.dart';

part 'categories_event.freezed.dart';

@freezed
sealed class CategoriesEvent with _$CategoriesEvent {
  const factory CategoriesEvent.started(String userId) = CategoriesStarted;
  const factory CategoriesEvent.deleteRequested(int categoryId) =
      CategoriesDeleteRequested;
}
