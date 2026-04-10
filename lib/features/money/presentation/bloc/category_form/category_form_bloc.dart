import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:track/features/money/domain/entities/category_entity.dart';
import 'package:track/features/money/domain/usecases/create_category.dart';
import 'package:track/features/money/domain/usecases/update_category.dart';
import 'package:track/features/money/presentation/bloc/category_form/category_form_event.dart';
import 'package:track/features/money/presentation/bloc/category_form/category_form_state.dart';

@injectable
class CategoryFormBloc extends Bloc<CategoryFormEvent, CategoryFormState> {
  CategoryFormBloc(this._createCategory, this._updateCategory)
    : super(const CategoryFormState()) {
    on<CategoryFormInitialized>(_onInitialized);
    on<CategoryFormNameChanged>(_onNameChanged);
    on<CategoryFormTransactionTypeChanged>(_onTransactionTypeChanged);
    on<CategoryFormIconChanged>(_onIconChanged);
    on<CategoryFormColorChanged>(_onColorChanged);
    on<CategoryFormSubmitted>(_onSubmitted);
  }

  final CreateCategory _createCategory;
  final UpdateCategory _updateCategory;
  String? _userId;

  void _onInitialized(
    CategoryFormInitialized event,
    Emitter<CategoryFormState> emit,
  ) {
    _userId = event.userId;

    if (event.category != null) {
      final c = event.category!;
      emit(
        state.copyWith(
          isEditMode: true,
          initialCategory: c,
          name: c.name,
          transactionType: c.transactionType,
          iconName: c.iconName,
          colorHex: c.colorHex,
        ),
      );
    }
  }

  void _onNameChanged(
    CategoryFormNameChanged event,
    Emitter<CategoryFormState> emit,
  ) {
    emit(state.copyWith(name: event.name, errorMessage: null));
  }

  void _onTransactionTypeChanged(
    CategoryFormTransactionTypeChanged event,
    Emitter<CategoryFormState> emit,
  ) {
    emit(state.copyWith(transactionType: event.transactionType));
  }

  void _onIconChanged(
    CategoryFormIconChanged event,
    Emitter<CategoryFormState> emit,
  ) {
    emit(state.copyWith(iconName: event.iconName));
  }

  void _onColorChanged(
    CategoryFormColorChanged event,
    Emitter<CategoryFormState> emit,
  ) {
    emit(state.copyWith(colorHex: event.colorHex));
  }

  Future<void> _onSubmitted(
    CategoryFormSubmitted event,
    Emitter<CategoryFormState> emit,
  ) async {
    if (state.name.trim().isEmpty) {
      emit(state.copyWith(errorMessage: 'Please enter a category name'));
      return;
    }
    if (_userId == null) return;

    emit(state.copyWith(isSubmitting: true, errorMessage: null));

    final now = DateTime.now();
    final isEdit = state.isEditMode && state.initialCategory != null;

    final category = CategoryEntity(
      id: isEdit ? state.initialCategory!.id : 0,
      userId: _userId,
      name: state.name.trim(),
      transactionType: state.transactionType,
      iconName: state.iconName,
      colorHex: state.colorHex,
      isDefault: false,
      sortOrder: isEdit ? state.initialCategory!.sortOrder : 0,
      createdAt: isEdit ? state.initialCategory!.createdAt : now,
    );

    final result =
        isEdit
            ? await _updateCategory(category)
            : await _createCategory(category);

    result.fold(
      (_) => emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: 'Failed to save category. Please try again.',
        ),
      ),
      (_) => emit(state.copyWith(isSubmitting: false, isSuccess: true)),
    );
  }
}
