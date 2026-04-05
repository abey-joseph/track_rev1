import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/core/usecases/usecase.dart';
import 'package:track/features/money/domain/entities/transaction_with_details.dart';
import 'package:track/features/money/domain/repositories/money_repository.dart';
import 'package:track/features/money/domain/usecases/get_transactions.dart';

@lazySingleton
class WatchTransactionsWithDetails
    implements
        StreamUseCase<List<TransactionWithDetails>, MoneyParams> {
  WatchTransactionsWithDetails(this._repository);

  final MoneyRepository _repository;

  @override
  Stream<Either<Failure, List<TransactionWithDetails>>> call(
    MoneyParams params,
  ) =>
      _repository.watchTransactionsWithDetails(
        params.userId,
        fromDate: params.fromDate,
        toDate: params.toDate,
      );
}
