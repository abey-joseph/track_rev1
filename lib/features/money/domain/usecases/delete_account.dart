import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/core/usecases/usecase.dart';
import 'package:track/features/money/domain/repositories/money_repository.dart';

@lazySingleton
class DeleteAccount implements UseCase<void, DeleteAccountParams> {
  DeleteAccount(this._repository);

  final MoneyRepository _repository;

  @override
  Future<Either<Failure, void>> call(DeleteAccountParams params) =>
      _repository.deleteAccount(params.accountId, params.userId);
}

class DeleteAccountParams extends Equatable {
  const DeleteAccountParams({required this.accountId, required this.userId});

  final int accountId;
  final String userId;

  @override
  List<Object?> get props => [accountId, userId];
}
