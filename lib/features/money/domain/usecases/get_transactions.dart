import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/core/usecases/usecase.dart';
import 'package:track/features/money/domain/entities/transaction_with_details.dart';
import 'package:track/features/money/domain/repositories/money_repository.dart';

@lazySingleton
class GetTransactionsWithDetails
    implements UseCase<List<TransactionWithDetails>, MoneyParams> {
  GetTransactionsWithDetails(this._repository);

  final MoneyRepository _repository;

  @override
  Future<Either<Failure, List<TransactionWithDetails>>> call(
    MoneyParams params,
  ) => _repository.getTransactionsWithDetails(
    params.userId,
    fromDate: params.fromDate,
    toDate: params.toDate,
  );
}

class MoneyParams extends Equatable {
  const MoneyParams({required this.userId, this.fromDate, this.toDate});

  final String userId;
  final String? fromDate;
  final String? toDate;

  @override
  List<Object?> get props => [userId, fromDate, toDate];
}
