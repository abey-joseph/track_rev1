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
import 'package:track/features/money/domain/entities/recurring_transaction_entity.dart';
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
            final enriched = await Future.wait(
              transactions.map((t) => _enrichTransaction(t.toEntity())),
            );
            final results = _deduplicateTransfers(enriched);
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
      final enriched = await Future.wait(
        transactions.map((t) => _enrichTransaction(t.toEntity())),
      );
      return Right(_deduplicateTransfers(enriched));
    } on CacheException catch (e) {
      return Left(Failure.cache(message: e.message));
    }
  }

  Future<TransactionWithDetails> _enrichTransaction(
    TransactionEntity entity,
  ) async {
    final category = await _localDataSource.getCategoryById(entity.categoryId);
    final account = await _localDataSource.getAccountById(entity.accountId);

    // Resolve currency symbol from the original currency code
    final currencyCode = entity.originalCurrencyCode;
    var currencySymbol = r'$';
    final currencyRow = await _localDataSource.getCurrencyByCode(
      entity.originalCurrencyCode,
      entity.userId,
    );
    if (currencyRow != null) {
      currencySymbol = currencyRow.toEntity().symbol;
    }

    // For transfers, look up the to-account name via the peer row
    String? toAccountName;
    if (entity.type == TransactionType.transfer &&
        entity.transferPeerId != null) {
      final peer = await _localDataSource.getTransactionById(
        entity.transferPeerId!,
      );
      if (peer != null) {
        final toAccount = await _localDataSource.getAccountById(
          peer.toEntity().accountId,
        );
        toAccountName = toAccount?.name;
      }
    }

    return TransactionWithDetails(
      transaction: entity,
      categoryName: category?.name ?? 'Unknown',
      categoryIconName: category?.iconName ?? 'more_horiz',
      categoryColorHex: category?.colorHex ?? '#795548',
      accountName: account?.name ?? 'Unknown',
      currencyCode: currencyCode,
      currencySymbol: currencySymbol,
      toAccountName: toAccountName,
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
  Future<Either<Failure, void>> deleteTransaction(
    TransactionEntity transaction,
  ) async {
    try {
      if (transaction.type == TransactionType.transfer &&
          transaction.transferPeerId != null) {
        final peer = await _localDataSource.getTransactionById(
          transaction.transferPeerId!,
        );
        if (peer != null) {
          await _localDataSource.deleteTransferPair(
            transaction.id,
            peer.id,
            transaction.accountId,
            peer.accountId,
            transaction.amountCents,
          );
        } else {
          await _localDataSource.deleteTransaction(
            transaction.id,
            transaction.accountId,
            -transaction.amountCents,
          );
        }
      } else {
        final balanceDelta =
            transaction.type == TransactionType.income
                ? transaction.amountCents
                : -transaction.amountCents;
        await _localDataSource.deleteTransaction(
          transaction.id,
          transaction.accountId,
          balanceDelta,
        );
      }
      return const Right(null);
    } on CacheException catch (e) {
      return Left(Failure.cache(message: e.message));
    }
  }

  @override
  Stream<Either<Failure, List<TransactionWithDetails>>>
  watchBookmarkedTransactions(
    String userId,
  ) {
    return _localDataSource.watchBookmarkedTransactions(userId).asyncMap((
      transactions,
    ) async {
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
  Future<Either<Failure, void>> setBookmark(
    int transactionId, {
    required bool isBookmarked,
  }) async {
    try {
      await _localDataSource.setBookmark(
        transactionId,
        isBookmarked: isBookmarked,
      );
      return const Right(null);
    } on CacheException catch (e) {
      return Left(Failure.cache(message: e.message));
    }
  }

  @override
  Future<Either<Failure, int>> createTransaction(
    TransactionEntity transaction,
  ) async {
    try {
      final originalCents =
          transaction.originalAmountCents > 0
              ? transaction.originalAmountCents
              : transaction.amountCents;
      final amountCents = await _convertToAccountCurrency(
        transaction.userId,
        transaction.accountId,
        transaction.originalCurrencyCode,
        originalCents,
      );
      final converted = transaction.copyWith(amountCents: amountCents);
      final balanceDelta =
          converted.type == TransactionType.income ? amountCents : -amountCents;

      final id = await _localDataSource.insertTransaction(
        converted.toCompanion(),
        balanceDelta,
      );
      return Right(id);
    } on CacheException catch (e) {
      return Left(Failure.cache(message: e.message));
    }
  }

  @override
  Future<Either<Failure, int>> createTransfer({
    required TransactionEntity fromTransaction,
    required int toAccountId,
  }) async {
    try {
      final now = DateTime.now();
      final categoryId =
          await _findTransferCategoryId(fromTransaction.userId) ??
          fromTransaction.categoryId;

      final originalCents =
          fromTransaction.originalAmountCents > 0
              ? fromTransaction.originalAmountCents
              : fromTransaction.amountCents;

      final fromAmountCents = await _convertToAccountCurrency(
        fromTransaction.userId,
        fromTransaction.accountId,
        fromTransaction.originalCurrencyCode,
        originalCents,
      );
      final toAmountCents = await _convertToAccountCurrency(
        fromTransaction.userId,
        toAccountId,
        fromTransaction.originalCurrencyCode,
        originalCents,
      );

      final fromEntry =
          fromTransaction
              .copyWith(
                categoryId: categoryId,
                amountCents: fromAmountCents,
                originalAmountCents: originalCents,
                createdAt: now,
                updatedAt: now,
              )
              .toCompanion();

      final toEntry =
          TransactionEntity(
            id: 0,
            userId: fromTransaction.userId,
            accountId: toAccountId,
            categoryId: categoryId,
            type: TransactionType.transfer,
            amountCents: toAmountCents,
            originalCurrencyCode: fromTransaction.originalCurrencyCode,
            originalAmountCents: originalCents,
            title: fromTransaction.title,
            note: fromTransaction.note,
            transactionDate: fromTransaction.transactionDate,
            sourceRecurringTransactionId:
                fromTransaction.sourceRecurringTransactionId,
            sourceOccurrenceDate: fromTransaction.sourceOccurrenceDate,
            createdAt: now,
            updatedAt: now,
          ).toCompanion();

      final id = await _localDataSource.insertTransferPair(
        fromEntry,
        toEntry,
        fromTransaction.accountId,
        toAccountId,
        fromAmountCents,
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

  @override
  Stream<Either<Failure, List<CategoryEntity>>> watchCategories(
    String userId,
  ) {
    return _localDataSource
        .watchCategories(userId)
        .map(
          (categories) => Right<Failure, List<CategoryEntity>>(
            categories.map((c) => c.toEntity()).toList(),
          ),
        );
  }

  @override
  Future<Either<Failure, int>> createCategory(CategoryEntity category) async {
    try {
      final id = await _localDataSource.insertCategory(
        category.toCompanion(),
      );
      return Right(id);
    } on CacheException catch (e) {
      return Left(Failure.cache(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updateCategory(CategoryEntity category) async {
    try {
      await _localDataSource.updateCategory(category.toCompanion());
      return const Right(null);
    } on CacheException catch (e) {
      return Left(Failure.cache(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCategory(int id) async {
    try {
      await _localDataSource.deleteCategory(id);
      return const Right(null);
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

  // ── Recurring Transactions ──────────────────────────────────────────

  @override
  Future<Either<Failure, List<RecurringTransactionEntity>>>
  getRecurringTransactions(String userId) async {
    try {
      final rows = await _localDataSource.getRecurringTransactions(userId);
      return Right(rows.map((r) => r.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(Failure.cache(message: e.message));
    }
  }

  @override
  Stream<Either<Failure, List<RecurringTransactionEntity>>>
  watchRecurringTransactions(String userId) {
    return _localDataSource.watchRecurringTransactions(userId).map((
      rows,
    ) {
      try {
        return Right<Failure, List<RecurringTransactionEntity>>(
          rows.map((r) => r.toEntity()).toList(),
        );
      } on CacheException catch (e) {
        return Left<Failure, List<RecurringTransactionEntity>>(
          Failure.cache(message: e.message),
        );
      }
    });
  }

  @override
  Future<Either<Failure, int>> createRecurringTransaction(
    RecurringTransactionEntity entity,
  ) async {
    try {
      final id = await _localDataSource.insertRecurringTransaction(
        entity.toCompanion(),
      );
      return Right(id);
    } on CacheException catch (e) {
      return Left(Failure.cache(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updateRecurringTransaction(
    RecurringTransactionEntity entity,
  ) async {
    try {
      await _localDataSource.updateRecurringTransaction(
        entity.toCompanion(),
      );
      return const Right(null);
    } on CacheException catch (e) {
      return Left(Failure.cache(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteRecurringTransaction(
    int id,
  ) async {
    try {
      await _localDataSource.deleteRecurringTransaction(id);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(Failure.cache(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> processDueRecurringTransactions(
    String userId,
    DateTime now,
  ) async {
    try {
      final rows = await _localDataSource.getRecurringTransactions(userId);
      final todayStr = _formatDate(now);

      for (final row in rows) {
        final entity = row.toEntity();
        if (!entity.isActive) continue;

        final datesToGenerate = _computeDueDates(entity, todayStr);
        var lastDate = entity.lastGeneratedDate;

        for (final dateStr in datesToGenerate) {
          final exists = await _localDataSource.hasGeneratedOccurrence(
            entity.id,
            dateStr,
          );
          if (exists) continue;

          final originalCents =
              entity.originalAmountCents > 0
                  ? entity.originalAmountCents
                  : entity.amountCents;

          if (entity.type == TransactionType.transfer &&
              entity.toAccountId != null) {
            final categoryId =
                await _findTransferCategoryId(entity.userId) ??
                entity.categoryId;

            final fromAmountCents = await _convertToAccountCurrency(
              entity.userId,
              entity.accountId,
              entity.originalCurrencyCode,
              originalCents,
            );
            final toAmountCents = await _convertToAccountCurrency(
              entity.userId,
              entity.toAccountId!,
              entity.originalCurrencyCode,
              originalCents,
            );

            final fromEntry =
                TransactionEntity(
                  id: 0,
                  userId: entity.userId,
                  accountId: entity.accountId,
                  categoryId: categoryId,
                  type: TransactionType.transfer,
                  amountCents: fromAmountCents,
                  originalCurrencyCode: entity.originalCurrencyCode,
                  originalAmountCents: originalCents,
                  title: entity.title,
                  note: entity.note,
                  transactionDate: dateStr,
                  sourceRecurringTransactionId: entity.id,
                  sourceOccurrenceDate: dateStr,
                  createdAt: now,
                  updatedAt: now,
                ).toCompanion();

            final toEntry =
                TransactionEntity(
                  id: 0,
                  userId: entity.userId,
                  accountId: entity.toAccountId!,
                  categoryId: categoryId,
                  type: TransactionType.transfer,
                  amountCents: toAmountCents,
                  originalCurrencyCode: entity.originalCurrencyCode,
                  originalAmountCents: originalCents,
                  title: entity.title,
                  note: entity.note,
                  transactionDate: dateStr,
                  sourceRecurringTransactionId: entity.id,
                  sourceOccurrenceDate: dateStr,
                  createdAt: now,
                  updatedAt: now,
                ).toCompanion();

            await _localDataSource.insertTransferPair(
              fromEntry,
              toEntry,
              entity.accountId,
              entity.toAccountId!,
              fromAmountCents,
            );
          } else {
            final amountCents = await _convertToAccountCurrency(
              entity.userId,
              entity.accountId,
              entity.originalCurrencyCode,
              originalCents,
            );
            final balanceDelta =
                entity.type == TransactionType.income
                    ? amountCents
                    : -amountCents;

            final txn = TransactionEntity(
              id: 0,
              userId: entity.userId,
              accountId: entity.accountId,
              categoryId: entity.categoryId,
              type: entity.type,
              amountCents: amountCents,
              originalCurrencyCode: entity.originalCurrencyCode,
              originalAmountCents: originalCents,
              title: entity.title,
              note: entity.note,
              transactionDate: dateStr,
              sourceRecurringTransactionId: entity.id,
              sourceOccurrenceDate: dateStr,
              createdAt: now,
              updatedAt: now,
            );

            await _localDataSource.insertTransaction(
              txn.toCompanion(),
              balanceDelta,
            );
          }

          lastDate = dateStr;
        }

        if (lastDate != null && lastDate != entity.lastGeneratedDate) {
          await _localDataSource.updateLastGeneratedDate(
            entity.id,
            lastDate,
            now,
          );
        }

        if (entity.scheduleType == RecurringScheduleType.once &&
            datesToGenerate.isNotEmpty) {
          await _localDataSource.markRecurringCompleted(
            entity.id,
            now,
          );
        }
      }
      return const Right(null);
    } on CacheException catch (e) {
      return Left(Failure.cache(message: e.message));
    }
  }

  /// Computes the list of ISO-8601 date strings that need transactions
  /// generated for [entity] up through [todayStr].
  List<String> _computeDueDates(
    RecurringTransactionEntity entity,
    String todayStr,
  ) {
    final startDate = DateTime.parse(entity.startDate);
    final today = DateTime.parse(todayStr);

    if (startDate.isAfter(today)) return [];

    if (entity.scheduleType == RecurringScheduleType.once) {
      if (entity.lastGeneratedDate != null) return [];
      return [entity.startDate];
    }

    // Range: max(startDate, lastGeneratedDate + 1) .. today
    DateTime rangeStart;
    if (entity.lastGeneratedDate != null) {
      final lastGen = DateTime.parse(entity.lastGeneratedDate!);
      rangeStart = lastGen.add(const Duration(days: 1));
    } else {
      rangeStart = startDate;
    }

    if (rangeStart.isAfter(today)) return [];

    final dates = <String>[];

    switch (entity.scheduleType) {
      case RecurringScheduleType.daily:
        var d = rangeStart;
        while (!d.isAfter(today)) {
          dates.add(_formatDate(d));
          d = d.add(const Duration(days: 1));
        }
      case RecurringScheduleType.weekly:
        var d = rangeStart;
        while (!d.isAfter(today)) {
          if (entity.weekdays.contains(d.weekday)) {
            dates.add(_formatDate(d));
          }
          d = d.add(const Duration(days: 1));
        }
      case RecurringScheduleType.monthlyFixed:
        _addMonthlyFixedDates(
          dates,
          rangeStart,
          today,
          entity.monthDay ?? 1,
        );
      case RecurringScheduleType.monthlyMultiple:
        _addMonthlyMultipleDates(
          dates,
          rangeStart,
          today,
          entity.monthDays,
        );
      case RecurringScheduleType.once:
        break; // already handled above
    }

    return dates;
  }

  void _addMonthlyFixedDates(
    List<String> dates,
    DateTime rangeStart,
    DateTime today,
    int targetDay,
  ) {
    var year = rangeStart.year;
    var month = rangeStart.month;

    while (true) {
      final lastDay = DateTime(year, month + 1, 0).day;
      final resolvedDay = targetDay > lastDay ? lastDay : targetDay;
      final candidate = DateTime(year, month, resolvedDay);

      if (candidate.isAfter(today)) break;
      if (!candidate.isBefore(rangeStart)) {
        dates.add(_formatDate(candidate));
      }

      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
    }
  }

  void _addMonthlyMultipleDates(
    List<String> dates,
    DateTime rangeStart,
    DateTime today,
    List<int> targetDays,
  ) {
    var year = rangeStart.year;
    var month = rangeStart.month;

    while (true) {
      final lastDay = DateTime(year, month + 1, 0).day;
      final firstOfMonth = DateTime(year, month);

      if (firstOfMonth.isAfter(today)) break;

      // Resolve each target day, clamp to last day, collect unique.
      final resolvedDays = <int>{};
      for (final td in targetDays) {
        resolvedDays.add(td > lastDay ? lastDay : td);
      }

      final sortedDays = resolvedDays.toList()..sort();
      for (final day in sortedDays) {
        final candidate = DateTime(year, month, day);
        if (candidate.isAfter(today)) break;
        if (!candidate.isBefore(rangeStart)) {
          dates.add(_formatDate(candidate));
        }
      }

      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
    }
  }

  /// Filters out the "to" side of transfer pairs to avoid duplicates in lists.
  List<TransactionWithDetails> _deduplicateTransfers(
    List<TransactionWithDetails> items,
  ) {
    return items.where((d) {
      final t = d.transaction;
      if (t.type == TransactionType.transfer && t.transferPeerId != null) {
        return t.id < t.transferPeerId!;
      }
      return true;
    }).toList();
  }

  /// Converts [originalAmountCents] in [originalCurrencyCode] to the account's
  /// base currency. Returns [originalAmountCents] unchanged if currencies match
  /// or rate data is unavailable.
  Future<int> _convertToAccountCurrency(
    String userId,
    int accountId,
    String originalCurrencyCode,
    int originalAmountCents,
  ) async {
    final account = await _localDataSource.getAccountById(accountId);
    if (account == null || account.currency == originalCurrencyCode) {
      return originalAmountCents;
    }
    final origCurrencyRow = await _localDataSource.getCurrencyByCode(
      originalCurrencyCode,
      userId,
    );
    final acctCurrencyRow = await _localDataSource.getCurrencyByCode(
      account.currency,
      userId,
    );
    final origRate = origCurrencyRow?.exchangeRate ?? 1.0;
    final acctRate = acctCurrencyRow?.exchangeRate ?? 1.0;
    final safeOrigRate = origRate <= 0 ? 1.0 : origRate;
    return (originalAmountCents * acctRate / safeOrigRate).round();
  }

  /// Returns the ID of the seeded "Transfer" category, or null if not found.
  Future<int?> _findTransferCategoryId(String userId) async {
    final categories = await _localDataSource.getCategories(userId);
    for (final c in categories) {
      if (c.transactionType == 'transfer' && c.isDefault) return c.id;
    }
    return null;
  }

  static String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
