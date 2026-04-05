import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/database/app_database.dart';
import 'package:track/core/error/exceptions.dart';

abstract class MoneyLocalDataSource {
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

  Future<List<Account>> getAccounts(String userId);

  Stream<List<Account>> watchAccounts(String userId);

  Future<Account?> getAccountById(int id);

  Future<List<Category>> getCategories(String userId);

  Future<Category?> getCategoryById(int id);

  Future<int> insertAccount(AccountsCompanion entry);

  Future<void> ensureDefaultAccounts(String userId);
}

@LazySingleton(as: MoneyLocalDataSource)
class MoneyLocalDataSourceImpl implements MoneyLocalDataSource {
  MoneyLocalDataSourceImpl(this._db);

  final AppDatabase _db;

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

  @override
  Future<int> insertAccount(AccountsCompanion entry) async {
    try {
      return await _db.moneyDao.insertAccount(entry);
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
          name: 'Bank Account',
          type: 'checking',
          iconName: const Value('account_balance'),
          colorHex: const Value('#2196F3'),
          sortOrder: const Value(1),
          createdAt: now,
          updatedAt: now,
        ),
        AccountsCompanion.insert(
          userId: userId,
          name: 'Credit Card',
          type: 'credit_card',
          iconName: const Value('credit_card'),
          colorHex: const Value('#E91E63'),
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
}
