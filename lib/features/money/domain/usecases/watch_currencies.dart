import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/core/usecases/usecase.dart';
import 'package:track/features/money/domain/entities/currency_entity.dart';
import 'package:track/features/money/domain/repositories/money_repository.dart';
import 'package:track/features/money/domain/usecases/get_accounts.dart';

@lazySingleton
class WatchCurrencies
    implements StreamUseCase<List<CurrencyEntity>, UserIdParams> {
  WatchCurrencies(this._repository);

  final MoneyRepository _repository;

  @override
  Stream<Either<Failure, List<CurrencyEntity>>> call(UserIdParams params) =>
      _repository.watchCurrencies(params.userId);
}
