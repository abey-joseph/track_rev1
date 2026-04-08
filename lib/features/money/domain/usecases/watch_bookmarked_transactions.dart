import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/core/usecases/usecase.dart';
import 'package:track/features/money/domain/entities/transaction_with_details.dart';
import 'package:track/features/money/domain/repositories/money_repository.dart';
import 'package:track/features/money/domain/usecases/get_accounts.dart';

@lazySingleton
class WatchBookmarkedTransactions
    implements StreamUseCase<List<TransactionWithDetails>, UserIdParams> {
  WatchBookmarkedTransactions(this._repository);

  final MoneyRepository _repository;

  @override
  Stream<Either<Failure, List<TransactionWithDetails>>> call(
    UserIdParams params,
  ) => _repository.watchBookmarkedTransactions(params.userId);
}
