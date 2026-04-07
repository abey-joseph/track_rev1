import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/error/exceptions.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/features/money/data/datasources/money_local_data_source.dart';
import 'package:track/features/money/data/mappers/money_mapper.dart';
import 'package:track/features/money/domain/entities/account_entity.dart';
import 'package:track/features/money/domain/entities/category_entity.dart';
import 'package:track/features/money/domain/entities/currency_entity.dart';
import 'package:track/features/money/domain/entities/money_summary.dart';
import 'package:track/features/money/domain/entities/transaction_entity.dart';
import 'package:track/features/money/domain/entities/transaction_with_details.dart';
import 'package:track/features/money/domain/repositories/money_repository.dart';

@LazySingleton(as: MoneyRepository)
class MoneyRepositoryImpl implements MoneyRepository {
  MoneyRepositoryImpl(this._localDataSource);

  final MoneyLocalDataSource _localDataSource;

  // ── Transactions ──────────────────────────────────────────────────────────

  @override
  Stream<Either<Failure, List<TransactionWithDetails>>>
  watchTransactionsWithDetails(
    String userId, {
    String? fromDate,
    String? toDate,
  }) {
    return _localDataSource
        .watchTransactions(userId, fromDate: fromDate, toDate: toDate)
        .asyncMap((transactions) async {
          try {
            final results = await Future.wait(
              transactions.map((t) => _enrichTransaction(t.toEntity())),
            );
            return Right<Failure, List<TransactionWithDetails>>(results);
          } on CacheException catch (e) {
            return Left<Failure, List<TransactionWithDetails>>(
              Failure.cache(message: e.message),
            );
          }
        });
  }

  @override
  Future<Either<Failure, List<TransactionWithDetails>>>
  getTransactionsWithDetails(
    String userId, {
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final transactions = await _localDataSource.getTransactions(
        userId,
        fromDate: fromDate,
        toDate: toDate,
      );
      final results = await Future.wait(
        transactions.map((t) => _enrichTransaction(t.toEntity())),
      );
      return Right(results);
    } on CacheException catch (e) {
      return Left(Failure.cache(message: e.message));
    }
  }

  Future<TransactionWithDetails> _enrichTransaction(
    TransactionEntity entity,
  ) async {
    final category = await _localDataSource.getCategoryById(entity.categoryId);
    final account = await _localDataSource.getAccountById(entity.accountId);

    return TransactionWithDetails(
      transaction: entity,
      categoryName: category?.name ?? 'Unknown',
      categoryIconName: category?.iconName ?? 'more_horiz',
      categoryColorHex: category?.colorHex ?? '#795548',
      accountName: account?.name ?? 'Unknown',
    );
  }

  @override
  Future<Either<Failure, MoneySummary>> getMonthlySummary(
    String userId,
    int year,
    int month,
  ) async {
    try {
      final fromDate =
          '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-01';
      final lastDay = DateTime(year, month + 1, 0).day;
      final toDate =
          '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';

      final transactions = await _localDataSource.getTransactions(
        userId,
        fromDate: fromDate,
        toDate: toDate,
      );

      var totalIncome = 0;
      var totalExpense = 0;
      final categoryTotals = <int, int>{};

      for (final t in transactions) {
        final entity = t.toEntity();
        if (entity.type == TransactionType.income) {
          totalIncome += entity.amountCents;
        } else if (entity.type == TransactionType.expense) {
          totalExpense += entity.amountCents;
          categoryTotals[entity.categoryId] =
              (categoryTotals[entity.categoryId] ?? 0) + entity.amountCents;
        }
      }

      final sortedCategoryIds =
          categoryTotals.keys.toList()
            ..sort((a, b) => categoryTotals[b]!.compareTo(categoryTotals[a]!));
      final topIds = sortedCategoryIds.take(5);

      final topCategories = <CategorySpending>[];
      for (final catId in topIds) {
        final cat = await _localDataSource.getCategoryById(catId);
        if (cat != null) {
          topCategories.add(
            CategorySpending(
              categoryId: catId,
              name: cat.name,
              iconName: cat.iconName,
              colorHex: cat.colorHex,
              amountCents: categoryTotals[catId]!,
            ),
          );
        }
      }

      return Right(
        MoneySummary(
          totalIncomeCents: totalIncome,
          totalExpenseCents: totalExpense,
          topCategories: topCategories,
        ),
      );
    } on CacheException catch (e) {
      return Left(Failure.cache(message: e.message));
    }
  }

  @override
  Future<Either<Failure, int>> createTransaction(
    TransactionEntity transaction,
  ) async {
    try {
      final balanceDelta =
          transaction.type == TransactionType.income
              ? transaction.amountCents
              : -transaction.amountCents;

      final id = await _localDataSource.insertTransaction(
        transaction.toCompanion(),
        balanceDelta,
      );
      return Right(id);
    } on CacheException catch (e) {
      return Left(Failure.cache(message: e.message));
    }
  }

  // ── Accounts ──────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<AccountEntity>>> getAccounts(
    String userId,
  ) async {
    try {
      await _localDataSource.ensureDefaultAccounts(userId);
      final accounts = await _localDataSource.getAccounts(userId);
      return Right(accounts.map((a) => a.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(Failure.cache(message: e.message));
    }
  }

  @override
  Stream<Either<Failure, List<AccountEntity>>> watchAccounts(String userId) {
    _localDataSource.ensureDefaultAccounts(userId).ignore();
    return _localDataSource.watchAccounts(userId).map((accounts) {
      try {
        return Right<Failure, List<AccountEntity>>(
          accounts.map((a) => a.toEntity()).toList(),
        );
      } on CacheException catch (e) {
        return Left<Failure, List<AccountEntity>>(
          Failure.cache(message: e.message),
        );
      }
    });
  }

  @override
  Future<Either<Failure, int>> createAccount(AccountEntity account) async {
    try {
      final id = await _localDataSource.insertAccount(account.toCompanion());
      return Right(id);
    } on CacheException catch (e) {
      return Left(Failure.cache(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updateAccount(AccountEntity account) async {
    try {
      await _localDataSource.updateAccount(account.toCompanion());
      return const Right(null);
    } on CacheException catch (e) {
      return Left(Failure.cache(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount(int id, String userId) async {
    try {
      await _localDataSource.deleteAccount(id);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(Failure.cache(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> setDefaultAccount(
    int accountId,
    String userId,
  ) async {
    try {
      await _localDataSource.setDefaultAccount(accountId, userId);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(Failure.cache(message: e.message));
    }
  }

  // ── Categories ────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<CategoryEntity>>> getCategories(
    String userId,
  ) async {
    try {
      final categories = await _localDataSource.getCategories(userId);
      return Right(categories.map((c) => c.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(Failure.cache(message: e.message));
    }
  }

  // ── Currencies ────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<CurrencyEntity>>> getCurrencies(
    String userId,
  ) async {
    try {
      await _localDataSource.ensureDefaultCurrencies(userId);
      final list = await _localDataSource.getCurrencies(userId);
      return Right(list.map((c) => c.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(Failure.cache(message: e.message));
    }
  }

  @override
  Stream<Either<Failure, List<CurrencyEntity>>> watchCurrencies(
    String userId,
  ) {
    _localDataSource.ensureDefaultCurrencies(userId).ignore();
    return _localDataSource.watchCurrencies(userId).map((list) {
      try {
        return Right<Failure, List<CurrencyEntity>>(
          list.map((c) => c.toEntity()).toList(),
        );
      } on CacheException catch (e) {
        return Left<Failure, List<CurrencyEntity>>(
          Failure.cache(message: e.message),
        );
      }
    });
  }

  @override
  Future<Either<Failure, int>> createCurrency(CurrencyEntity currency) async {
    try {
      final id = await _localDataSource.insertCurrency(
        currency.toCompanion(),
      );
      return Right(id);
    } on CacheException catch (e) {
      return Left(Failure.cache(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updateCurrency(CurrencyEntity currency) async {
    try {
      await _localDataSource.updateCurrency(currency.toCompanion());
      return const Right(null);
    } on CacheException catch (e) {
      return Left(Failure.cache(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCurrency(int id, String userId) async {
    try {
      final currency = await _localDataSource.getCurrencyById(id);
      if (currency == null) return const Right(null);

      final inUse = await _localDataSource.isCurrencyInUse(
        currency.code,
        userId,
      );
      if (inUse) {
        return Left(
          Failure.cache(
            message:
                'Cannot delete "${currency.name}" — it is used by one or more accounts.',
          ),
        );
      }

      await _localDataSource.deleteCurrency(id);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(Failure.cache(message: e.message));
    }
  }
}
