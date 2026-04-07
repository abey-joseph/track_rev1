import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/core/usecases/usecase.dart';
import 'package:track/features/money/domain/repositories/money_repository.dart';

@lazySingleton
class DeleteCurrency implements UseCase<void, DeleteCurrencyParams> {
  DeleteCurrency(this._repository);

  final MoneyRepository _repository;

  @override
  Future<Either<Failure, void>> call(DeleteCurrencyParams params) =>
      _repository.deleteCurrency(params.currencyId, params.userId);
}

class DeleteCurrencyParams extends Equatable {
  const DeleteCurrencyParams({required this.currencyId, required this.userId});

  final int currencyId;
  final String userId;

  @override
  List<Object?> get props => [currencyId, userId];
}
