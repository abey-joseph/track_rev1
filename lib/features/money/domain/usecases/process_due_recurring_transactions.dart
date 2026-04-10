import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/core/usecases/usecase.dart';
import 'package:track/features/money/domain/repositories/money_repository.dart';

@lazySingleton
class ProcessDueRecurringTransactions
    implements UseCase<void, ProcessDueParams> {
  ProcessDueRecurringTransactions(this._repository);

  final MoneyRepository _repository;

  @override
  Future<Either<Failure, void>> call(ProcessDueParams params) =>
      _repository.processDueRecurringTransactions(
        params.userId,
        params.now,
      );
}

class ProcessDueParams extends Equatable {
  const ProcessDueParams({required this.userId, required this.now});

  final String userId;
  final DateTime now;

  @override
  List<Object?> get props => [userId, now];
}
