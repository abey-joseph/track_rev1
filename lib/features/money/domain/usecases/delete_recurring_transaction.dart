import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/core/usecases/usecase.dart';
import 'package:track/features/money/domain/repositories/money_repository.dart';

@lazySingleton
class DeleteRecurringTransaction
    implements UseCase<void, DeleteRecurringTransactionParams> {
  DeleteRecurringTransaction(this._repository);

  final MoneyRepository _repository;

  @override
  Future<Either<Failure, void>> call(
    DeleteRecurringTransactionParams params,
  ) => _repository.deleteRecurringTransaction(params.id);
}

class DeleteRecurringTransactionParams extends Equatable {
  const DeleteRecurringTransactionParams({required this.id});

  final int id;

  @override
  List<Object?> get props => [id];
}
