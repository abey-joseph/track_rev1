import 'package:drift/drift.dart';

import 'daos/habits_dao.dart';
import 'daos/insights_dao.dart';
import 'daos/money_dao.dart';
import 'daos/settings_dao.dart';
import 'tables/accounts_table.dart';
import 'tables/budgets_table.dart';
import 'tables/categories_table.dart';
import 'tables/habit_logs_table.dart';
import 'tables/habit_streaks_table.dart';
import 'tables/habits_table.dart';
import 'tables/insights_table.dart';
import 'tables/transactions_table.dart';
import 'tables/user_settings_table.dart';

export 'tables/accounts_table.dart';
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
    Insights,
    UserSettings,
  ],
  daos: [
    HabitsDao,
    MoneyDao,
    InsightsDao,
    SettingsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
      );
}
