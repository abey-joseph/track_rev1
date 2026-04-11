import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/core/usecases/usecase.dart';
import 'package:track/features/money/domain/entities/transaction_entity.dart';
import 'package:track/features/money/domain/repositories/money_repository.dart';

@lazySingleton
class CreateTransfer implements UseCase<int, CreateTransferParams> {
  CreateTransfer(this._repository);

  final MoneyRepository _repository;

  @override
  Future<Either<Failure, int>> call(CreateTransferParams params) =>
      _repository.createTransfer(
        fromTransaction: params.fromTransaction,
        toAccountId: params.toAccountId,
      );
}

class CreateTransferParams extends Equatable {
  const CreateTransferParams({
    required this.fromTransaction,
    required this.toAccountId,
  });

  final TransactionEntity fromTransaction;
  final int toAccountId;

  @override
  List<Object?> get props => [fromTransaction, toAccountId];
}
