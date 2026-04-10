import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/core/usecases/usecase.dart';
import 'package:track/features/money/domain/repositories/money_repository.dart';

@lazySingleton
class DeleteCategory implements UseCase<void, DeleteCategoryParams> {
  DeleteCategory(this._repository);

  final MoneyRepository _repository;

  @override
  Future<Either<Failure, void>> call(DeleteCategoryParams params) =>
      _repository.deleteCategory(params.categoryId);
}

class DeleteCategoryParams extends Equatable {
  const DeleteCategoryParams({required this.categoryId});

  final int categoryId;

  @override
  List<Object?> get props => [categoryId];
}
