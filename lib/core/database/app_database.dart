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
import 'package:track/core/database/tables/user_settings_table.dart';

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
  daos: [HabitsDao, MoneyDao, InsightsDao, SettingsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(habits, habits.targetType);
          }
        },
      );
}
