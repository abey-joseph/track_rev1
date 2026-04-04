import 'package:drift/drift.dart';

import 'package:track/core/database/app_database.dart';

part 'money_dao.g.dart';

@DriftAccessor(tables: [Accounts, Categories, Transactions, Budgets])
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

  Future<int> deleteCategory(int id) =>
      (delete(categories)..where((c) => c.id.equals(id))).go();

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
