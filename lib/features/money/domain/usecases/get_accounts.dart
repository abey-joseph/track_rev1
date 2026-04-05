import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/core/usecases/usecase.dart';
import 'package:track/features/money/domain/entities/account_entity.dart';
import 'package:track/features/money/domain/repositories/money_repository.dart';

@lazySingleton
class GetAccounts implements UseCase<List<AccountEntity>, UserIdParams> {
  GetAccounts(this._repository);

  final MoneyRepository _repository;

  @override
  Future<Either<Failure, List<AccountEntity>>> call(UserIdParams params) =>
      _repository.getAccounts(params.userId);
}

class UserIdParams extends Equatable {
  const UserIdParams({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}
