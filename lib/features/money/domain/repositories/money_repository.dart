import 'package:fpdart/fpdart.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/features/money/domain/entities/account_entity.dart';
import 'package:track/features/money/domain/entities/category_entity.dart';
import 'package:track/features/money/domain/entities/currency_entity.dart';
import 'package:track/features/money/domain/entities/money_summary.dart';
import 'package:track/features/money/domain/entities/transaction_entity.dart';
import 'package:track/features/money/domain/entities/transaction_with_details.dart';

abstract class MoneyRepository {
  // ── Transactions ──────────────────────────────────────────────────────────

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

  Future<Either<Failure, void>> deleteTransaction(
    TransactionEntity transaction,
  );

  Stream<Either<Failure, List<TransactionWithDetails>>>
  watchBookmarkedTransactions(
    String userId,
  );

  Future<Either<Failure, void>> setBookmark(
    int transactionId, {
    required bool isBookmarked,
  });

  // ── Accounts ──────────────────────────────────────────────────────────────

  Future<Either<Failure, List<AccountEntity>>> getAccounts(String userId);

  Stream<Either<Failure, List<AccountEntity>>> watchAccounts(String userId);

  Future<Either<Failure, int>> createAccount(AccountEntity account);

  Future<Either<Failure, void>> updateAccount(AccountEntity account);

  Future<Either<Failure, void>> deleteAccount(int id, String userId);

  Future<Either<Failure, void>> setDefaultAccount(int accountId, String userId);

  // ── Categories ────────────────────────────────────────────────────────────

  Future<Either<Failure, List<CategoryEntity>>> getCategories(String userId);

  // ── Currencies ────────────────────────────────────────────────────────────

  Future<Either<Failure, List<CurrencyEntity>>> getCurrencies(String userId);

  Stream<Either<Failure, List<CurrencyEntity>>> watchCurrencies(String userId);

  Future<Either<Failure, int>> createCurrency(CurrencyEntity currency);

  Future<Either<Failure, void>> updateCurrency(CurrencyEntity currency);

  /// Fails with a [CacheFailure] if the currency is in use by any account.
  Future<Either<Failure, void>> deleteCurrency(int id, String userId);
}
