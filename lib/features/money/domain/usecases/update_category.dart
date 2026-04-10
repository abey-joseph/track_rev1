import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/core/usecases/usecase.dart';
import 'package:track/features/money/domain/entities/category_entity.dart';
import 'package:track/features/money/domain/repositories/money_repository.dart';

@lazySingleton
class UpdateCategory implements UseCase<void, CategoryEntity> {
  UpdateCategory(this._repository);

  final MoneyRepository _repository;

  @override
  Future<Either<Failure, void>> call(CategoryEntity params) =>
      _repository.updateCategory(params);
}
