import 'package:drift/drift.dart';

import 'package:track/core/database/app_database.dart';

part 'money_dao.g.dart';

@DriftAccessor(
  tables: [Accounts, Categories, Transactions, Budgets, Currencies],
)
class MoneyDao extends DatabaseAccessor<AppDatabase> with _$MoneyDaoMixin {
  MoneyDao(super.db);

  // ── Accounts ─────────────────────────────────────────────────────────────

  Future<List<Account>> getAccounts(String userId) =>
      (select(accounts)
            ..where((a) => a.userId.equals(userId) & a.isArchived.equals(false))
            ..orderBy([(a) => OrderingTerm.asc(a.sortOrder)]))
          .get();

  Stream<List<Account>> watchAccounts(String userId) =>
      (select(accounts)
            ..where((a) => a.userId.equals(userId) & a.isArchived.equals(false))
            ..orderBy([(a) => OrderingTerm.asc(a.sortOrder)]))
          .watch();

  Future<Account?> getAccountById(int id) =>
      (select(accounts)..where((a) => a.id.equals(id))).getSingleOrNull();

  Future<int> insertAccount(AccountsCompanion entry) =>
      into(accounts).insert(entry);

  Future<bool> updateAccount(AccountsCompanion entry) =>
      update(accounts).replace(entry);

  Future<int> archiveAccount(int id) => (update(accounts)..where(
    (a) => a.id.equals(id),
  )).write(const AccountsCompanion(isArchived: Value(true)));

  Future<int> deleteAccount(int id) =>
      (delete(accounts)..where((a) => a.id.equals(id))).go();

  /// Sets [accountId] as the default, clearing any other default for [userId].
  Future<void> setDefaultAccount(int accountId, String userId) async {
    await transaction(() async {
      // Clear existing default
      await (update(accounts)..where((a) => a.userId.equals(userId))).write(
        const AccountsCompanion(isDefault: Value(false)),
      );
      // Set new default
      await (update(accounts)..where((a) => a.id.equals(accountId))).write(
        AccountsCompanion(
          isDefault: const Value(true),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  // ── Categories ───────────────────────────────────────────────────────────

  /// Returns system defaults (userId IS NULL) plus the user's own categories.
  Future<List<Category>> getCategories(String userId) =>
      (select(categories)
            ..where((c) => c.userId.isNull() | c.userId.equals(userId))
            ..orderBy([
              (c) => OrderingTerm.desc(c.isDefault),
              (c) => OrderingTerm.asc(c.sortOrder),
            ]))
          .get();

  Stream<List<Category>> watchCategories(String userId) =>
      (select(categories)
            ..where((c) => c.userId.isNull() | c.userId.equals(userId))
            ..orderBy([
              (c) => OrderingTerm.desc(c.isDefault),
              (c) => OrderingTerm.asc(c.sortOrder),
            ]))
          .watch();

  Future<int> insertCategory(CategoriesCompanion entry) =>
      into(categories).insert(entry);

  Future<bool> updateCategory(CategoriesCompanion entry) =>
      update(categories).replace(entry);

  Future<Category?> getCategoryById(int id) =>
      (select(categories)..where((c) => c.id.equals(id))).getSingleOrNull();

  Future<int> deleteCategory(int id) =>
      (delete(categories)..where((c) => c.id.equals(id))).go();

  Future<int> getAccountCount(String userId) async {
    final countExpr = accounts.id.count();
    final query =
        selectOnly(accounts)
          ..addColumns([countExpr])
          ..where(accounts.userId.equals(userId));
    final row = await query.getSingle();
    return row.read(countExpr)!;
  }

  // ── Transactions ─────────────────────────────────────────────────────────

  Future<List<Transaction>> getTransactions(
    String userId, {
    String? fromDate,
    String? toDate,
    int? accountId,
    int? categoryId,
  }) {
    final query = select(transactions)..where((t) => t.userId.equals(userId));
    if (fromDate != null) {
      query.where((t) => t.transactionDate.isBiggerOrEqualValue(fromDate));
    }
    if (toDate != null) {
      query.where((t) => t.transactionDate.isSmallerOrEqualValue(toDate));
    }
    if (accountId != null) {
      query.where((t) => t.accountId.equals(accountId));
    }
    if (categoryId != null) {
      query.where((t) => t.categoryId.equals(categoryId));
    }
    query.orderBy([(t) => OrderingTerm.desc(t.transactionDate)]);
    return query.get();
  }

  Stream<List<Transaction>> watchTransactions(
    String userId, {
    String? fromDate,
    String? toDate,
  }) {
    final query = select(transactions)..where((t) => t.userId.equals(userId));
    if (fromDate != null) {
      query.where((t) => t.transactionDate.isBiggerOrEqualValue(fromDate));
    }
    if (toDate != null) {
      query.where((t) => t.transactionDate.isSmallerOrEqualValue(toDate));
    }
    query.orderBy([(t) => OrderingTerm.desc(t.transactionDate)]);
    return query.watch();
  }

  Future<Transaction?> getTransactionById(int id) =>
      (select(transactions)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Inserts a transaction and adjusts [accountId]'s balance atomically.
  ///
  /// [balanceDelta] should be positive for income and negative for expenses
  /// (in cents).
  Future<int> insertTransaction(
    TransactionsCompanion entry,
    int balanceDelta,
  ) async {
    return transaction(() async {
      final id = await into(transactions).insert(entry);
      await _adjustBalance(entry.accountId.value, balanceDelta);
      return id;
    });
  }

  /// Updates a transaction, reversing the old balance effect and applying
  /// the new one atomically.
  Future<void> updateTransaction(
    TransactionsCompanion entry,
    int oldBalanceDelta,
    int newBalanceDelta,
  ) async {
    await transaction(() async {
      await update(transactions).replace(entry);
      // Reverse the old effect, then apply the new one.
      await _adjustBalance(
        entry.accountId.value,
        -oldBalanceDelta + newBalanceDelta,
      );
    });
  }

  /// Deletes a transaction and reverses its balance effect atomically.
  ///
  /// [accountId] and [balanceDelta] must be provided by the caller before
  /// deletion so the balance can be adjusted correctly.
  Future<void> deleteTransaction(
    int id,
    int accountId,
    int balanceDelta,
  ) async {
    await transaction(() async {
      await (delete(transactions)..where((t) => t.id.equals(id))).go();
      await _adjustBalance(accountId, -balanceDelta);
    });
  }

  /// Adjusts [Accounts.balance] for [accountId] by [delta] cents.
  Future<void> _adjustBalance(int accountId, int delta) async {
    await (update(accounts)..where((a) => a.id.equals(accountId))).write(
      AccountsCompanion.custom(
        balance: accounts.balance + Variable(delta),
        updatedAt: Variable(DateTime.now()),
      ),
    );
  }

  // ── Budgets ───────────────────────────────────────────────────────────────

  Future<List<Budget>> getBudgets(String userId) =>
      (select(
        budgets,
      )..where((b) => b.userId.equals(userId) & b.isActive.equals(true))).get();

  Stream<List<Budget>> watchBudgets(String userId) =>
      (select(budgets)..where(
        (b) => b.userId.equals(userId) & b.isActive.equals(true),
      )).watch();

  Future<Budget?> getBudgetById(int id) =>
      (select(budgets)..where((b) => b.id.equals(id))).getSingleOrNull();

  Future<int> insertBudget(BudgetsCompanion entry) =>
      into(budgets).insert(entry);

  Future<bool> updateBudget(BudgetsCompanion entry) =>
      update(budgets).replace(entry);

  Future<int> deactivateBudget(int id) => (update(budgets)..where(
    (b) => b.id.equals(id),
  )).write(const BudgetsCompanion(isActive: Value(false)));

  // ── Currencies ────────────────────────────────────────────────────────────

  Future<List<Currency>> getCurrencies(String userId) =>
      (select(currencies)
            ..where((c) => c.userId.equals(userId))
            ..orderBy([(c) => OrderingTerm.desc(c.isDefault)]))
          .get();

  Stream<List<Currency>> watchCurrencies(String userId) =>
      (select(currencies)
            ..where((c) => c.userId.equals(userId))
            ..orderBy([(c) => OrderingTerm.desc(c.isDefault)]))
          .watch();

  Future<Currency?> getCurrencyById(int id) =>
      (select(currencies)..where((c) => c.id.equals(id))).getSingleOrNull();

  Future<int> insertCurrency(CurrenciesCompanion entry) =>
      into(currencies).insert(entry);

  Future<bool> updateCurrency(CurrenciesCompanion entry) =>
      update(currencies).replace(entry);

  Future<int> deleteCurrency(int id) =>
      (delete(currencies)..where((c) => c.id.equals(id))).go();

  Future<int> updateExchangeRate(int id, double rate) =>
      (update(currencies)..where((c) => c.id.equals(id))).write(
        CurrenciesCompanion(
          exchangeRate: Value(rate),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<int> getCurrencyCount(String userId) async {
    final countExpr = currencies.id.count();
    final query =
        selectOnly(currencies)
          ..addColumns([countExpr])
          ..where(currencies.userId.equals(userId));
    final row = await query.getSingle();
    return row.read(countExpr)!;
  }

  /// Returns true if any non-archived account for [userId] uses [currencyCode].
  Future<bool> isCurrencyInUse(String currencyCode, String userId) async {
    final query = select(accounts)..where(
      (a) =>
          a.userId.equals(userId) &
          a.currency.equals(currencyCode) &
          a.isArchived.equals(false),
    );
    final rows = await query.get();
    return rows.isNotEmpty;
  }

  // ── Analytics ─────────────────────────────────────────────────────────────

  /// Calculates the total **cents** spent in [period] for a [categoryId]
  /// (or all categories if null).
  ///
  /// [fromDate] and [toDate] are ISO-8601 date strings defining the period.
  Future<int> getSpentAmount(
    String userId,
    String fromDate,
    String toDate, {
    int? categoryId,
  }) async {
    final query = select(transactions)..where(
      (t) =>
          t.userId.equals(userId) &
          t.type.equals('expense') &
          t.transactionDate.isBiggerOrEqualValue(fromDate) &
          t.transactionDate.isSmallerOrEqualValue(toDate),
    );
    if (categoryId != null) {
      query.where((t) => t.categoryId.equals(categoryId));
    }
    final rows = await query.get();
    return rows.fold<int>(0, (sum, t) => sum + t.amount);
  }
}
