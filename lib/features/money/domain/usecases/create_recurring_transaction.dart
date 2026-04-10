import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/core/usecases/usecase.dart';
import 'package:track/features/money/domain/entities/recurring_transaction_entity.dart';
import 'package:track/features/money/domain/repositories/money_repository.dart';

@lazySingleton
class CreateRecurringTransaction
    implements UseCase<int, RecurringTransactionEntity> {
  CreateRecurringTransaction(this._repository);

  final MoneyRepository _repository;

  @override
  Future<Either<Failure, int>> call(
    RecurringTransactionEntity params,
  ) => _repository.createRecurringTransaction(params);
}
