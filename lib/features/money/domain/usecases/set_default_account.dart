import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/core/usecases/usecase.dart';
import 'package:track/features/money/domain/repositories/money_repository.dart';

@lazySingleton
class SetDefaultAccount implements UseCase<void, SetDefaultAccountParams> {
  SetDefaultAccount(this._repository);

  final MoneyRepository _repository;

  @override
  Future<Either<Failure, void>> call(SetDefaultAccountParams params) =>
      _repository.setDefaultAccount(params.accountId, params.userId);
}

class SetDefaultAccountParams extends Equatable {
  const SetDefaultAccountParams({
    required this.accountId,
    required this.userId,
  });

  final int accountId;
  final String userId;

  @override
  List<Object?> get props => [accountId, userId];
}
