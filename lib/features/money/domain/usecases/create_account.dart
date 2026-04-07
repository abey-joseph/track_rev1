import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/core/usecases/usecase.dart';
import 'package:track/features/money/domain/entities/account_entity.dart';
import 'package:track/features/money/domain/repositories/money_repository.dart';

@lazySingleton
class CreateAccount implements UseCase<int, AccountEntity> {
  CreateAccount(this._repository);

  final MoneyRepository _repository;

  @override
  Future<Either<Failure, int>> call(AccountEntity params) =>
      _repository.createAccount(params);
}
