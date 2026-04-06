import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/core/usecases/usecase.dart';
import 'package:track/features/money/domain/entities/money_summary.dart';
import 'package:track/features/money/domain/repositories/money_repository.dart';

@lazySingleton
class GetMonthlySummary implements UseCase<MoneySummary, MonthlySummaryParams> {
  GetMonthlySummary(this._repository);

  final MoneyRepository _repository;

  @override
  Future<Either<Failure, MoneySummary>> call(
    MonthlySummaryParams params,
  ) => _repository.getMonthlySummary(params.userId, params.year, params.month);
}

class MonthlySummaryParams extends Equatable {
  const MonthlySummaryParams({
    required this.userId,
    required this.year,
    required this.month,
  });

  final String userId;
  final int year;
  final int month;

  @override
  List<Object?> get props => [userId, year, month];
}
