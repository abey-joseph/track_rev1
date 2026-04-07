import 'package:drift/drift.dart';

import 'package:track/core/database/daos/habits_dao.dart';
import 'package:track/core/database/daos/insights_dao.dart';
import 'package:track/core/database/daos/money_dao.dart';
import 'package:track/core/database/daos/settings_dao.dart';
import 'package:track/core/database/tables/accounts_table.dart';
import 'package:track/core/database/tables/budgets_table.dart';
import 'package:track/core/database/tables/categories_table.dart';
import 'package:track/core/database/tables/habit_logs_table.dart';
import 'package:track/core/database/tables/habit_streaks_table.dart';
import 'package:track/core/database/tables/habits_table.dart';
import 'package:track/core/database/tables/insights_table.dart';
import 'package:track/core/database/tables/transactions_table.dart';
import 'package:track/core/database/tables/currencies_table.dart';
import 'package:track/core/database/tables/user_settings_table.dart';

export 'tables/accounts_table.dart';
export 'tables/currencies_table.dart';
export 'tables/budgets_table.dart';
export 'tables/categories_table.dart';
export 'tables/habit_logs_table.dart';
export 'tables/habit_streaks_table.dart';
export 'tables/habits_table.dart';
export 'tables/insights_table.dart';
export 'tables/transactions_table.dart';
export 'tables/user_settings_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Habits,
    HabitLogs,
    HabitStreaks,
    Accounts,
    Categories,
    Transactions,
    Budgets,
    Currencies,
    Insights,
    UserSettings,
  ],
  daos: [HabitsDao, MoneyDao, InsightsDao, SettingsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedDefaultCategories();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(habits, habits.targetType);
      }
      if (from < 3) {
        await _seedDefaultCategories();
      }
      if (from < 4) {
        await m.addColumn(accounts, accounts.description);
        await m.createTable(currencies);
      }
    },
  );

  Future<void> _seedDefaultCategories() async {
    final now = DateTime.now();
    final defaults = <CategoriesCompanion>[
      // Expense categories
      CategoriesCompanion.insert(
        name: 'Food & Dining',
        transactionType: 'expense',
        iconName: 'restaurant',
        colorHex: '#FF9800',
        isDefault: const Value(true),
        sortOrder: const Value(0),
        createdAt: now,
      ),
      CategoriesCompanion.insert(
        name: 'Transport',
        transactionType: 'expense',
        iconName: 'directions_car',
        colorHex: '#2196F3',
        isDefault: const Value(true),
        sortOrder: const Value(1),
        createdAt: now,
      ),
      CategoriesCompanion.insert(
        name: 'Entertainment',
        transactionType: 'expense',
        iconName: 'movie',
        colorHex: '#E91E63',
        isDefault: const Value(true),
        sortOrder: const Value(2),
        createdAt: now,
      ),
      CategoriesCompanion.insert(
        name: 'Shopping',
        transactionType: 'expense',
        iconName: 'shopping_bag',
        colorHex: '#9C27B0',
        isDefault: const Value(true),
        sortOrder: const Value(3),
        createdAt: now,
      ),
      CategoriesCompanion.insert(
        name: 'Bills & Utilities',
        transactionType: 'expense',
        iconName: 'receipt_long',
        colorHex: '#607D8B',
        isDefault: const Value(true),
        sortOrder: const Value(4),
        createdAt: now,
      ),
      CategoriesCompanion.insert(
        name: 'Health',
        transactionType: 'expense',
        iconName: 'favorite',
        colorHex: '#F44336',
        isDefault: const Value(true),
        sortOrder: const Value(5),
        createdAt: now,
      ),
      CategoriesCompanion.insert(
        name: 'Education',
        transactionType: 'expense',
        iconName: 'school',
        colorHex: '#3F51B5',
        isDefault: const Value(true),
        sortOrder: const Value(6),
        createdAt: now,
      ),
      CategoriesCompanion.insert(
        name: 'Other Expense',
        transactionType: 'expense',
        iconName: 'more_horiz',
        colorHex: '#795548',
        isDefault: const Value(true),
        sortOrder: const Value(7),
        createdAt: now,
      ),
      // Income categories
      CategoriesCompanion.insert(
        name: 'Salary',
        transactionType: 'income',
        iconName: 'payments',
        colorHex: '#4CAF50',
        isDefault: const Value(true),
        sortOrder: const Value(0),
        createdAt: now,
      ),
      CategoriesCompanion.insert(
        name: 'Freelance',
        transactionType: 'income',
        iconName: 'work',
        colorHex: '#00BCD4',
        isDefault: const Value(true),
        sortOrder: const Value(1),
        createdAt: now,
      ),
      CategoriesCompanion.insert(
        name: 'Investment',
        transactionType: 'income',
        iconName: 'trending_up',
        colorHex: '#FF5722',
        isDefault: const Value(true),
        sortOrder: const Value(2),
        createdAt: now,
      ),
      CategoriesCompanion.insert(
        name: 'Gift',
        transactionType: 'income',
        iconName: 'card_giftcard',
        colorHex: '#FFC107',
        isDefault: const Value(true),
        sortOrder: const Value(3),
        createdAt: now,
      ),
      CategoriesCompanion.insert(
        name: 'Other Income',
        transactionType: 'income',
        iconName: 'more_horiz',
        colorHex: '#795548',
        isDefault: const Value(true),
        sortOrder: const Value(4),
        createdAt: now,
      ),
    ];

    for (final entry in defaults) {
      await into(categories).insert(entry);
    }
  }
}
