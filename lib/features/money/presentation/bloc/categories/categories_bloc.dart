import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:track/features/money/domain/usecases/delete_category.dart';
import 'package:track/features/money/domain/usecases/get_accounts.dart';
import 'package:track/features/money/domain/usecases/watch_categories.dart';
import 'package:track/features/money/presentation/bloc/categories/categories_event.dart';
import 'package:track/features/money/presentation/bloc/categories/categories_state.dart';

@injectable
class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  CategoriesBloc(this._watchCategories, this._deleteCategory)
    : super(const CategoriesState.initial()) {
    on<CategoriesStarted>(_onStarted);
    on<CategoriesDeleteRequested>(_onDeleteRequested);
  }

  final WatchCategories _watchCategories;
  final DeleteCategory _deleteCategory;

  Future<void> _onStarted(
    CategoriesStarted event,
    Emitter<CategoriesState> emit,
  ) async {
    emit(const CategoriesState.loading());

    await emit.forEach(
      _watchCategories(UserIdParams(userId: event.userId)),
      onData:
          (result) => result.fold(
            (failure) => CategoriesState.error(failure: failure),
            (categories) => CategoriesState.loaded(categories: categories),
          ),
    );
  }

  Future<void> _onDeleteRequested(
    CategoriesDeleteRequested event,
    Emitter<CategoriesState> emit,
  ) async {
    final current = state;
    if (current is! CategoriesLoaded) return;

    final result = await _deleteCategory(
      DeleteCategoryParams(categoryId: event.categoryId),
    );

    result.fold(
      (_) => emit(
        current.copyWith(
          deleteError: 'Failed to delete category. Please try again.',
        ),
      ),
      (_) {
        if (current.deleteError != null) {
          emit(current.copyWith(deleteError: null));
        }
      },
    );
  }
}
