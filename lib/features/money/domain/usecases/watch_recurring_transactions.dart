import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/core/usecases/usecase.dart';
import 'package:track/features/money/domain/entities/recurring_transaction_entity.dart';
import 'package:track/features/money/domain/repositories/money_repository.dart';
import 'package:track/features/money/domain/usecases/get_accounts.dart';

@lazySingleton
class WatchRecurringTransactions
    implements StreamUseCase<List<RecurringTransactionEntity>, UserIdParams> {
  WatchRecurringTransactions(this._repository);

  final MoneyRepository _repository;

  @override
  Stream<Either<Failure, List<RecurringTransactionEntity>>> call(
    UserIdParams params,
  ) => _repository.watchRecurringTransactions(params.userId);
}
