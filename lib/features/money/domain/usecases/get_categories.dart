import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/core/usecases/usecase.dart';
import 'package:track/features/money/domain/entities/category_entity.dart';
import 'package:track/features/money/domain/repositories/money_repository.dart';
import 'package:track/features/money/domain/usecases/get_accounts.dart';

@lazySingleton
class GetCategories implements UseCase<List<CategoryEntity>, UserIdParams> {
  GetCategories(this._repository);

  final MoneyRepository _repository;

  @override
  Future<Either<Failure, List<CategoryEntity>>> call(UserIdParams params) =>
      _repository.getCategories(params.userId);
}
