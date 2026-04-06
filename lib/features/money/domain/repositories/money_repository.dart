import 'package:fpdart/fpdart.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/features/money/domain/entities/account_entity.dart';
import 'package:track/features/money/domain/entities/category_entity.dart';
import 'package:track/features/money/domain/entities/money_summary.dart';
import 'package:track/features/money/domain/entities/transaction_entity.dart';
import 'package:track/features/money/domain/entities/transaction_with_details.dart';

abstract class MoneyRepository {
  Stream<Either<Failure, List<TransactionWithDetails>>>
  watchTransactionsWithDetails(
    String userId, {
    String? fromDate,
    String? toDate,
  });

  Future<Either<Failure, List<TransactionWithDetails>>>
  getTransactionsWithDetails(
    String userId, {
    String? fromDate,
    String? toDate,
  });

  Future<Either<Failure, MoneySummary>> getMonthlySummary(
    String userId,
    int year,
    int month,
  );

  Future<Either<Failure, int>> createTransaction(TransactionEntity transaction);

  Future<Either<Failure, List<AccountEntity>>> getAccounts(String userId);

  Stream<Either<Failure, List<AccountEntity>>> watchAccounts(String userId);

  Future<Either<Failure, List<CategoryEntity>>> getCategories(String userId);
}
