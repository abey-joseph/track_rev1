import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/database/app_database.dart';
import 'package:track/core/error/exceptions.dart';

abstract class MoneyLocalDataSource {
  // ── Transactions ──────────────────────────────────────────────────────────

  Stream<List<Transaction>> watchTransactions(
    String userId, {
    String? fromDate,
    String? toDate,
  });

  Future<List<Transaction>> getTransactions(
    String userId, {
    String? fromDate,
    String? toDate,
  });

  Future<int> insertTransaction(TransactionsCompanion entry, int balanceDelta);

  Future<void> deleteTransaction(int id, int accountId, int balanceDelta);

  Stream<List<Transaction>> watchBookmarkedTransactions(String userId);

  Future<void> setBookmark(int transactionId, {required bool isBookmarked});

  // ── Accounts ──────────────────────────────────────────────────────────────

  Future<List<Account>> getAccounts(String userId);

  Stream<List<Account>> watchAccounts(String userId);

  Future<Account?> getAccountById(int id);

  Future<int> insertAccount(AccountsCompanion entry);

  Future<bool> updateAccount(AccountsCompanion entry);

  Future<void> deleteAccount(int id);

  Future<void> setDefaultAccount(int accountId, String userId);

  Future<void> ensureDefaultAccounts(String userId);

  // ── Categories ────────────────────────────────────────────────────────────

  Future<List<Category>> getCategories(String userId);

  Future<Category?> getCategoryById(int id);

  // ── Currencies ────────────────────────────────────────────────────────────

  Future<List<Currency>> getCurrencies(String userId);

  Stream<List<Currency>> watchCurrencies(String userId);

  Future<Currency?> getCurrencyById(int id);

  Future<int> insertCurrency(CurrenciesCompanion entry);

  Future<bool> updateCurrency(CurrenciesCompanion entry);

  Future<void> deleteCurrency(int id);

  Future<bool> isCurrencyInUse(String currencyCode, String userId);

  Future<void> ensureDefaultCurrencies(String userId);
}

@LazySingleton(as: MoneyLocalDataSource)
class MoneyLocalDataSourceImpl implements MoneyLocalDataSource {
  MoneyLocalDataSourceImpl(this._db);

  final AppDatabase _db;

  // ── Transactions ──────────────────────────────────────────────────────────

  @override
  Stream<List<Transaction>> watchTransactions(
    String userId, {
    String? fromDate,
    String? toDate,
  }) {
    try {
      return _db.moneyDao.watchTransactions(
        userId,
        fromDate: fromDate,
        toDate: toDate,
      );
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> deleteTransaction(
    int id,
    int accountId,
    int balanceDelta,
  ) async {
    try {
      await _db.moneyDao.deleteTransaction(id, accountId, balanceDelta);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Stream<List<Transaction>> watchBookmarkedTransactions(String userId) {
    try {
      return _db.moneyDao.watchBookmarkedTransactions(userId);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> setBookmark(
    int transactionId, {
    required bool isBookmarked,
  }) async {
    try {
      await _db.moneyDao.setBookmark(
        transactionId,
        isBookmarked: isBookmarked,
      );
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<List<Transaction>> getTransactions(
    String userId, {
    String? fromDate,
    String? toDate,
  }) async {
    try {
      return await _db.moneyDao.getTransactions(
        userId,
        fromDate: fromDate,
        toDate: toDate,
      );
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<int> insertTransaction(
    TransactionsCompanion entry,
    int balanceDelta,
  ) async {
    try {
      return await _db.moneyDao.insertTransaction(entry, balanceDelta);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  // ── Accounts ──────────────────────────────────────────────────────────────

  @override
  Future<List<Account>> getAccounts(String userId) async {
    try {
      return await _db.moneyDao.getAccounts(userId);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Stream<List<Account>> watchAccounts(String userId) {
    try {
      return _db.moneyDao.watchAccounts(userId);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<Account?> getAccountById(int id) async {
    try {
      return await _db.moneyDao.getAccountById(id);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<int> insertAccount(AccountsCompanion entry) async {
    try {
      return await _db.moneyDao.insertAccount(entry);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<bool> updateAccount(AccountsCompanion entry) async {
    try {
      return await _db.moneyDao.updateAccount(entry);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> deleteAccount(int id) async {
    try {
      await _db.moneyDao.deleteAccount(id);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> setDefaultAccount(int accountId, String userId) async {
    try {
      await _db.moneyDao.setDefaultAccount(accountId, userId);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> ensureDefaultAccounts(String userId) async {
    try {
      final count = await _db.moneyDao.getAccountCount(userId);
      if (count > 0) return;

      final now = DateTime.now();
      final defaults = <AccountsCompanion>[
        AccountsCompanion.insert(
          userId: userId,
          name: 'Cash',
          type: 'cash',
          iconName: const Value('account_balance_wallet'),
          colorHex: const Value('#4CAF50'),
          isDefault: const Value(true),
          sortOrder: const Value(0),
          createdAt: now,
          updatedAt: now,
        ),
        AccountsCompanion.insert(
          userId: userId,
          name: 'Card',
          type: 'credit_card',
          iconName: const Value('credit_card'),
          colorHex: const Value('#E91E63'),
          sortOrder: const Value(1),
          createdAt: now,
          updatedAt: now,
        ),
        AccountsCompanion.insert(
          userId: userId,
          name: 'Bank',
          type: 'checking',
          iconName: const Value('account_balance'),
          colorHex: const Value('#2196F3'),
          sortOrder: const Value(2),
          createdAt: now,
          updatedAt: now,
        ),
      ];

      for (final entry in defaults) {
        await _db.moneyDao.insertAccount(entry);
      }
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  // ── Categories ────────────────────────────────────────────────────────────

  @override
  Future<List<Category>> getCategories(String userId) async {
    try {
      return await _db.moneyDao.getCategories(userId);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<Category?> getCategoryById(int id) async {
    try {
      return await _db.moneyDao.getCategoryById(id);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  // ── Currencies ────────────────────────────────────────────────────────────

  @override
  Future<List<Currency>> getCurrencies(String userId) async {
    try {
      return await _db.moneyDao.getCurrencies(userId);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Stream<List<Currency>> watchCurrencies(String userId) {
    try {
      return _db.moneyDao.watchCurrencies(userId);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<Currency?> getCurrencyById(int id) async {
    try {
      return await _db.moneyDao.getCurrencyById(id);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<int> insertCurrency(CurrenciesCompanion entry) async {
    try {
      return await _db.moneyDao.insertCurrency(entry);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<bool> updateCurrency(CurrenciesCompanion entry) async {
    try {
      return await _db.moneyDao.updateCurrency(entry);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> deleteCurrency(int id) async {
    try {
      await _db.moneyDao.deleteCurrency(id);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<bool> isCurrencyInUse(String currencyCode, String userId) async {
    try {
      return await _db.moneyDao.isCurrencyInUse(currencyCode, userId);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> ensureDefaultCurrencies(String userId) async {
    try {
      final count = await _db.moneyDao.getCurrencyCount(userId);
      if (count > 0) return;

      final now = DateTime.now();
      await _db.moneyDao.insertCurrency(
        CurrenciesCompanion.insert(
          userId: userId,
          name: 'US Dollar',
          code: 'USD',
          symbol: r'$',
          exchangeRate: const Value(1),
          isDefault: const Value(true),
          createdAt: now,
          updatedAt: now,
        ),
      );
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }
}
