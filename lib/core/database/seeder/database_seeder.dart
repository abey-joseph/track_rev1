// Seeder builds long lists via repeated .add() — cascades hurt readability.
// ignore_for_file: cascade_invocations

import 'package:drift/drift.dart';
import 'package:track/core/database/app_database.dart';

/// Seeds the database with realistic mock data for development and
/// testing.
///
/// All data is deterministic — running the seeder twice on the same
/// empty database produces identical results.
///
/// **Usage** (called from `main.dart` when `ENV=mock`):
/// ```dart
/// final db = getIt<AppDatabase>();
/// await DatabaseSeeder(db).seedIfNeeded(userId);
/// ```
class DatabaseSeeder {
  const DatabaseSeeder(this._db);

  final AppDatabase _db;

  // ── Category IDs (seeded by AppDatabase.onCreate) ───────────────
  static const _kFood = 1;
  static const _kTransport = 2;
  static const _kEntertainment = 3;
  static const _kShopping = 4;
  static const _kBills = 5;
  static const _kHealth = 6;
  static const _kEducation = 7;
  // static const _kOtherExpense = 8; // unused
  static const _kSalary = 9;
  static const _kFreelance = 10;
  static const _kInvestmentIncome = 11;
  static const _kGift = 12;
  static const _kOtherIncome = 13;

  // ── Public API ──────────────────────────────────────────────────

  /// Seeds all tables if the database has no habits for [userId].
  ///
  /// Returns `true` if data was seeded, `false` if skipped.
  Future<bool> seedIfNeeded(String userId) async {
    final existing =
        await (_db.select(_db.habits)
          ..where((h) => h.userId.equals(userId))).get();
    if (existing.isNotEmpty) return false;

    await _seedAccounts(userId);
    await _seedCurrencies(userId);
    await _seedHabits(userId);
    await _seedHabitLogs(userId);
    await _seedTransactions(userId);
    await _seedBudgets(userId);
    await _seedInsights(userId);
    await _seedSettings(userId);
    return true;
  }

  // ── Accounts ────────────────────────────────────────────────────

  Future<void> _seedAccounts(String userId) async {
    final now = DateTime.now();
    final entries = <AccountsCompanion>[
      AccountsCompanion.insert(
        userId: userId,
        name: 'Checking',
        type: 'checking',
        iconName: const Value('account_balance'),
        colorHex: const Value('#2196F3'),
        sortOrder: const Value(0),
        createdAt: now,
        updatedAt: now,
      ),
      AccountsCompanion.insert(
        userId: userId,
        name: 'Savings',
        type: 'savings',
        iconName: const Value('savings'),
        colorHex: const Value('#4CAF50'),
        sortOrder: const Value(1),
        createdAt: now,
        updatedAt: now,
      ),
      AccountsCompanion.insert(
        userId: userId,
        name: 'Cash',
        type: 'cash',
        iconName: const Value('wallet'),
        colorHex: const Value('#FF9800'),
        isDefault: const Value(true),
        sortOrder: const Value(2),
        createdAt: now,
        updatedAt: now,
      ),
      AccountsCompanion.insert(
        userId: userId,
        name: 'Credit Card',
        type: 'credit_card',
        iconName: const Value('credit_card'),
        colorHex: const Value('#F44336'),
        sortOrder: const Value(3),
        createdAt: now,
        updatedAt: now,
      ),
      AccountsCompanion.insert(
        userId: userId,
        name: 'Investment',
        type: 'investment',
        iconName: const Value('trending_up'),
        colorHex: const Value('#9C27B0'),
        sortOrder: const Value(4),
        createdAt: now,
        updatedAt: now,
      ),
    ];

    await _db.batch((b) {
      for (final e in entries) {
        b.insert(_db.accounts, e);
      }
    });
  }

  // ── Currencies ──────────────────────────────────────────────────

  Future<void> _seedCurrencies(String userId) async {
    final now = DateTime.now();
    final entries = <CurrenciesCompanion>[
      CurrenciesCompanion.insert(
        userId: userId,
        name: 'US Dollar',
        code: 'USD',
        symbol: r'$',
        isDefault: const Value(true),
        createdAt: now,
        updatedAt: now,
      ),
      CurrenciesCompanion.insert(
        userId: userId,
        name: 'Euro',
        code: 'EUR',
        symbol: '\u20AC',
        exchangeRate: const Value(0.92),
        createdAt: now,
        updatedAt: now,
      ),
      CurrenciesCompanion.insert(
        userId: userId,
        name: 'British Pound',
        code: 'GBP',
        symbol: '\u00A3',
        exchangeRate: const Value(0.79),
        createdAt: now,
        updatedAt: now,
      ),
    ];

    await _db.batch((b) {
      for (final e in entries) {
        b.insert(_db.currencies, e);
      }
    });
  }

  // ── Habits ──────────────────────────────────────────────────────

  Future<void> _seedHabits(String userId) async {
    final now = DateTime.now();

    // Habit definitions: (name, icon, color, freqType, freqDays,
    //   targetValue, targetUnit, targetType, isArchived, sortOrder)
    final habits = <HabitsCompanion>[
      // 1 — Morning Run
      HabitsCompanion.insert(
        userId: userId,
        name: 'Morning Run',
        description: const Value('30-minute morning jog'),
        iconName: const Value('directions_run'),
        colorHex: const Value('#FF5722'),
        targetValue: const Value(30),
        targetUnit: const Value('min'),
        sortOrder: const Value(0),
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: now,
      ),
      // 2 — Read Books
      HabitsCompanion.insert(
        userId: userId,
        name: 'Read Books',
        description: const Value('Read at least 30 pages'),
        iconName: const Value('menu_book'),
        colorHex: const Value('#3F51B5'),
        targetValue: const Value(30),
        targetUnit: const Value('pages'),
        sortOrder: const Value(1),
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: now,
      ),
      // 3 — Drink Water
      HabitsCompanion.insert(
        userId: userId,
        name: 'Drink Water',
        description: const Value('8 glasses per day'),
        iconName: const Value('water_drop'),
        colorHex: const Value('#03A9F4'),
        targetValue: const Value(8),
        targetUnit: const Value('glasses'),
        sortOrder: const Value(2),
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: now,
      ),
      // 4 — Meditate
      HabitsCompanion.insert(
        userId: userId,
        name: 'Meditate',
        description: const Value('Mindfulness meditation'),
        iconName: const Value('self_improvement'),
        colorHex: const Value('#9C27B0'),
        targetValue: const Value(10),
        targetUnit: const Value('min'),
        sortOrder: const Value(3),
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now,
      ),
      // 5 — No Sugar
      HabitsCompanion.insert(
        userId: userId,
        name: 'No Sugar',
        description: const Value('Max 1 sugary item per day'),
        iconName: const Value('no_food'),
        colorHex: const Value('#F44336'),
        targetValue: const Value(1),
        targetType: const Value('max'),
        sortOrder: const Value(4),
        createdAt: now.subtract(const Duration(days: 45)),
        updatedAt: now,
      ),
      // 6 — Gym Workout (weekly Mon/Wed/Fri)
      HabitsCompanion.insert(
        userId: userId,
        name: 'Gym Workout',
        description: const Value('Strength training session'),
        iconName: const Value('fitness_center'),
        colorHex: const Value('#FF9800'),
        frequencyType: const Value('weekly'),
        frequencyDays: const Value('[1,3,5]'),
        sortOrder: const Value(5),
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: now,
      ),
      // 7 — Journal
      HabitsCompanion.insert(
        userId: userId,
        name: 'Journal',
        iconName: const Value('edit_note'),
        colorHex: const Value('#795548'),
        sortOrder: const Value(6),
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: now,
      ),
      // 8 — Learn Spanish (weekly Tue/Thu/Sat)
      HabitsCompanion.insert(
        userId: userId,
        name: 'Learn Spanish',
        description: const Value('Duolingo or textbook'),
        iconName: const Value('translate'),
        colorHex: const Value('#00BCD4'),
        frequencyType: const Value('weekly'),
        frequencyDays: const Value('[2,4,6]'),
        targetValue: const Value(20),
        targetUnit: const Value('min'),
        sortOrder: const Value(7),
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now,
      ),
      // 9 — Sleep Early (ARCHIVED)
      HabitsCompanion.insert(
        userId: userId,
        name: 'Sleep Early',
        description: const Value('In bed before 11 PM'),
        iconName: const Value('bedtime'),
        colorHex: const Value('#607D8B'),
        isArchived: const Value(true),
        sortOrder: const Value(8),
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: now.subtract(const Duration(days: 30)),
      ),
      // 10 — Practice Guitar
      HabitsCompanion.insert(
        userId: userId,
        name: 'Practice Guitar',
        description: const Value('Chords and scales'),
        iconName: const Value('music_note'),
        colorHex: const Value('#E91E63'),
        targetValue: const Value(15),
        targetUnit: const Value('min'),
        sortOrder: const Value(9),
        createdAt: now.subtract(const Duration(days: 14)),
        updatedAt: now,
      ),
    ];

    await _db.batch((b) {
      for (final h in habits) {
        b.insert(_db.habits, h);
      }
    });
  }

  // ── Habit Logs ──────────────────────────────────────────────────

  Future<void> _seedHabitLogs(String userId) async {
    final now = DateTime.now();

    // Query actual habit IDs (insertion order matches index below)
    final habits =
        await (_db.select(_db.habits)
              ..where((h) => h.userId.equals(userId))
              ..orderBy([(h) => OrderingTerm.asc(h.sortOrder)]))
            .get();

    // Index → log config. Use actual IDs from the database.
    final configs = <_LogConfig>[
      // 0: Morning Run
      _LogConfig.daily(90, 0.75, 20, 45, streak: 5, target: 30),
      // 1: Read Books
      _LogConfig.daily(90, 0.85, 15, 60, streak: 12, target: 30),
      // 2: Drink Water
      _LogConfig.daily(90, 0.65, 4, 10, streak: 3, target: 8),
      // 3: Meditate
      _LogConfig.daily(60, 0.90, 8, 20, streak: 8, target: 10),
      // 4: No Sugar (max)
      _LogConfig.daily(45, 0.70, 0, 2, streak: 2),
      // 5: Gym Workout
      _LogConfig.weekly(90, 0.80, [1, 3, 5]),
      // 6: Journal
      _LogConfig.daily(90, 0.40, 1, 1),
      // 7: Learn Spanish
      _LogConfig.weekly(60, 0.70, [2, 4, 6], min: 15, max: 35),
      // 8: Sleep Early (archived, stopped 30 days ago)
      _LogConfig.daily(90, 0.50, 1, 1, endDaysAgo: 30),
      // 9: Practice Guitar
      _LogConfig.daily(14, 0.85, 10, 25, streak: 4, target: 15),
    ];

    final allLogs = <HabitLogsCompanion>[];

    for (var i = 0; i < habits.length && i < configs.length; i++) {
      final hid = habits[i].id;
      final c = configs[i];

      if (c.activeDays != null) {
        allLogs.addAll(
          _genWeeklyLogs(
            habitId: hid,
            daysBack: c.daysBack,
            rate: c.rate,
            activeDays: c.activeDays!,
            minVal: c.minVal,
            maxVal: c.maxVal,
            now: now,
          ),
        );
      } else {
        allLogs.addAll(
          _genDailyLogs(
            habitId: hid,
            daysBack: c.daysBack,
            rate: c.rate,
            minVal: c.minVal,
            maxVal: c.maxVal,
            streakDays: c.streakDays,
            targetVal: c.targetVal,
            now: now,
            endDaysAgo: c.endDaysAgo,
          ),
        );
      }
    }

    // Batch insert all logs
    await _db.batch((b) {
      for (final l in allLogs) {
        b.insert(_db.habitLogs, l);
      }
    });

    // Trigger streak recalculation via DAO for each habit.
    // We delete the last log then re-insert it through upsertLog,
    // which triggers _recalculateStreak. This avoids a unique-key
    // conflict (upsertLog resolves on PK, not composite key).
    for (final habit in habits) {
      final last =
          await (_db.select(_db.habitLogs)
                ..where((l) => l.habitId.equals(habit.id))
                ..orderBy([(l) => OrderingTerm.desc(l.loggedDate)])
                ..limit(1))
              .getSingleOrNull();
      if (last != null) {
        await (_db.delete(_db.habitLogs)
          ..where((l) => l.id.equals(last.id))).go();
        await _db.habitsDao.upsertLog(
          HabitLogsCompanion.insert(
            habitId: last.habitId,
            loggedDate: last.loggedDate,
            value: Value(last.value),
            createdAt: last.createdAt,
          ),
        );
      }
    }
  }

  // ── Transactions ────────────────────────────────────────────────

  Future<void> _seedTransactions(String userId) async {
    // Resolve actual account IDs (insertion order matches sort)
    final accts =
        await (_db.select(_db.accounts)
              ..where((a) => a.userId.equals(userId))
              ..orderBy([(a) => OrderingTerm.asc(a.sortOrder)]))
            .get();
    final checking = accts[0].id; // Checking
    final savings = accts[1].id; // Savings
    final cash = accts[2].id; // Cash
    final creditCard = accts[3].id; // Credit Card
    final investment = accts[4].id; // Investment

    final txns = <TransactionsCompanion>[];

    // 7 months: Oct 2025 – Apr 2026
    final months = [
      DateTime(2025, 10),
      DateTime(2025, 11),
      DateTime(2025, 12),
      DateTime(2026),
      DateTime(2026, 2),
      DateTime(2026, 3),
      DateTime(2026, 4),
    ];

    // Variation tables
    const utilityAmounts = [14500, 15800, 17200, 16100, 14800, 15300, 13900];
    const groceryAmounts = [
      [8550, 6230, 9475, 7820],
      [7200, 9100, 6850, 8400],
      [10200, 7500, 8900, 6100],
      [6800, 8200, 7400, 9600],
      [7900, 6500, 8800, 7100],
      [9300, 7800, 6200, 8600],
      [8100, 7300, 9800, 6700],
    ];
    const diningAmounts = [
      [4200, 2850, 6500],
      [3500, 5200, 2100],
      [7800, 3100, 4500],
      [2900, 4800, 3600],
      [5500, 2400, 3900],
      [3200, 6100, 4100],
      [4700, 2800, 5800],
    ];
    const transportAmounts = [
      [1250, 1800, 2500, 1550],
      [2200, 1400, 1900, 2800],
      [1600, 2100, 3200, 1300],
      [1850, 2400, 1100, 2600],
      [2000, 1500, 2700, 1400],
      [1700, 2300, 1200, 1900],
      [2100, 1600, 2500, 1800],
    ];
    const gasAmounts = [
      [5200, 4850],
      [4600, 5100],
      [5500, 4300],
      [4900, 5300],
      [4400, 5600],
      [5100, 4700],
      [4800, 5200],
    ];
    const shoppingAmounts = [
      [8999],
      [12500, 4599],
      [18999, 6500, 15000],
      [3499, 7999],
      [5999, 9999],
      [4299, 11500],
      [6999],
    ];

    for (var mi = 0; mi < months.length; mi++) {
      final m = months[mi];
      final bookmark = mi == 0 || mi == 5; // bookmark some months

      // ─ Income ─
      txns.add(
        _tx(
          userId,
          checking,
          _kSalary,
          'income',
          550000,
          'Monthly Salary',
          _d(m, 1),
          bookmarked: mi == 2,
        ),
      );

      // ─ Fixed expenses ─
      txns.add(
        _tx(
          userId,
          checking,
          _kBills,
          'expense',
          180000,
          'Rent',
          _d(m, 1),
        ),
      );
      txns.add(
        _tx(
          userId,
          checking,
          _kEntertainment,
          'expense',
          1599,
          'Netflix',
          _d(m, 15),
        ),
      );
      txns.add(
        _tx(
          userId,
          checking,
          _kEntertainment,
          'expense',
          999,
          'Spotify',
          _d(m, 15),
        ),
      );
      txns.add(
        _tx(
          userId,
          checking,
          _kHealth,
          'expense',
          4999,
          'Gym Membership',
          _d(m, 1),
        ),
      );
      txns.add(
        _tx(
          userId,
          checking,
          _kBills,
          'expense',
          5999,
          'Internet',
          _d(m, 10),
        ),
      );
      txns.add(
        _tx(
          userId,
          checking,
          _kBills,
          'expense',
          utilityAmounts[mi],
          'Electricity & Water',
          _d(m, 20),
        ),
      );

      // ─ Groceries (3–4 per month) ─
      final gc = 3 + (mi % 2);
      final groceryDays = [3, 10, 18, 25];
      for (var g = 0; g < gc; g++) {
        txns.add(
          _tx(
            userId,
            g.isEven ? cash : checking,
            _kFood,
            'expense',
            groceryAmounts[mi][g],
            'Groceries',
            _d(m, groceryDays[g]),
          ),
        );
      }

      // ─ Dining out (2–3 per month) ─
      final dc = 2 + (mi % 3 == 0 ? 1 : 0);
      final diningDays = [7, 16, 24];
      for (var d = 0; d < dc; d++) {
        txns.add(
          _tx(
            userId,
            d == 0 ? creditCard : cash,
            _kFood,
            'expense',
            diningAmounts[mi][d],
            d == 0 ? 'Restaurant dinner' : 'Lunch out',
            _d(m, diningDays[d]),
          ),
        );
      }

      // ─ Transport/Uber (3–4 per month) ─
      final tc = 3 + (mi % 2);
      final transportDays = [4, 11, 19, 26];
      for (var t = 0; t < tc; t++) {
        txns.add(
          _tx(
            userId,
            cash,
            _kTransport,
            'expense',
            transportAmounts[mi][t],
            t.isEven ? 'Uber ride' : 'Bus pass top-up',
            _d(m, transportDays[t]),
          ),
        );
      }

      // ─ Gas (1–2 per month) ─
      final gsc = 1 + (mi % 2);
      final gasDays = [8, 23];
      for (var gs = 0; gs < gsc; gs++) {
        txns.add(
          _tx(
            userId,
            checking,
            _kTransport,
            'expense',
            gasAmounts[mi][gs],
            'Gas station',
            _d(m, gasDays[gs]),
          ),
        );
      }

      // ─ Shopping (1–3 per month) ─
      final shopDays = [14, 21, 28];
      for (var s = 0; s < shoppingAmounts[mi].length; s++) {
        txns.add(
          _tx(
            userId,
            creditCard,
            _kShopping,
            'expense',
            shoppingAmounts[mi][s],
            s == 0 ? 'Online shopping' : 'Store purchase',
            _d(m, shopDays[s]),
            bookmarked: bookmark && s == 0,
          ),
        );
      }
    }

    // ─ Occasional / one-off transactions ─

    // Freelance income
    txns.add(
      _tx(
        userId,
        checking,
        _kFreelance,
        'income',
        120000,
        'Freelance web project',
        '2025-11-12',
        bookmarked: true,
      ),
    );
    txns.add(
      _tx(
        userId,
        checking,
        _kFreelance,
        'income',
        80000,
        'Logo design gig',
        '2026-02-08',
      ),
    );
    txns.add(
      _tx(
        userId,
        checking,
        _kFreelance,
        'income',
        150000,
        'Consulting work',
        '2026-04-03',
      ),
    );

    // Investment return
    txns.add(
      _tx(
        userId,
        investment,
        _kInvestmentIncome,
        'income',
        35000,
        'Dividend payment',
        '2026-01-15',
      ),
    );

    // Gift received
    txns.add(
      _tx(
        userId,
        cash,
        _kGift,
        'income',
        10000,
        'Birthday gift',
        '2025-12-18',
      ),
    );

    // Tax refund
    txns.add(
      _tx(
        userId,
        checking,
        _kOtherIncome,
        'income',
        120000,
        'Tax refund',
        '2026-03-22',
      ),
    );

    // Education
    txns.add(
      _tx(
        userId,
        creditCard,
        _kEducation,
        'expense',
        19900,
        'Online course - Flutter Advanced',
        '2025-11-05',
      ),
    );

    // Medical
    txns.add(
      _tx(
        userId,
        checking,
        _kHealth,
        'expense',
        15000,
        'Annual checkup',
        '2026-01-20',
      ),
    );

    // Holiday shopping
    txns.add(
      _tx(
        userId,
        creditCard,
        _kShopping,
        'expense',
        25000,
        'Holiday gifts',
        '2025-12-22',
      ),
    );
    txns.add(
      _tx(
        userId,
        creditCard,
        _kShopping,
        'expense',
        15000,
        'Holiday decorations',
        '2025-12-23',
      ),
    );

    // Savings transfer (modelled as expense from checking)
    txns.add(
      _tx(
        userId,
        checking,
        _kOtherIncome,
        'expense',
        50000,
        'Transfer to savings',
        '2026-01-02',
      ),
    );
    txns.add(
      _tx(
        userId,
        savings,
        _kOtherIncome,
        'income',
        50000,
        'Transfer from checking',
        '2026-01-02',
      ),
    );

    // Batch insert all transactions
    await _db.batch((b) {
      for (final tx in txns) {
        b.insert(_db.transactions, tx);
      }
    });

    // Compute and set account balances
    // Start with initial balances (money before tracking period)
    final balances = <int, int>{
      checking: 200000, //  $2,000
      savings: 1000000, // $10,000
      cash: 30000, //        $300
      creditCard: 0,
      investment: 800000, //  $8,000
    };

    for (final tx in txns) {
      final aid = tx.accountId.value;
      final amt = tx.amount.value;
      final type = tx.type.value;
      balances[aid] = (balances[aid] ?? 0) + (type == 'income' ? amt : -amt);
    }

    for (final entry in balances.entries) {
      await (_db.update(_db.accounts)
        ..where((a) => a.id.equals(entry.key))).write(
        AccountsCompanion(
          balance: Value(entry.value),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  // ── Budgets ─────────────────────────────────────────────────────

  Future<void> _seedBudgets(String userId) async {
    final now = DateTime.now();
    final entries = <BudgetsCompanion>[
      BudgetsCompanion.insert(
        userId: userId,
        name: 'Food & Dining',
        categoryId: const Value(_kFood),
        amountLimit: 60000,
        period: 'monthly',
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now,
      ),
      BudgetsCompanion.insert(
        userId: userId,
        name: 'Shopping',
        categoryId: const Value(_kShopping),
        amountLimit: 30000,
        period: 'monthly',
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now,
      ),
      BudgetsCompanion.insert(
        userId: userId,
        name: 'Entertainment',
        categoryId: const Value(_kEntertainment),
        amountLimit: 15000,
        period: 'monthly',
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now,
      ),
      BudgetsCompanion.insert(
        userId: userId,
        name: 'Transport',
        categoryId: const Value(_kTransport),
        amountLimit: 20000,
        period: 'monthly',
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now,
      ),
    ];

    await _db.batch((b) {
      for (final e in entries) {
        b.insert(_db.budgets, e);
      }
    });
  }

  // ── Insights ────────────────────────────────────────────────────

  Future<void> _seedInsights(String userId) async {
    final now = DateTime.now();
    final entries = <InsightsCompanion>[
      InsightsCompanion.insert(
        userId: userId,
        title: 'Spending is trending up',
        body:
            'Your total expenses this month are 12% higher than '
            'last month. Dining out and shopping are the main '
            'contributors.',
        type: 'trend',
        confidenceScore: const Value(0.85),
        generatedAt: now.subtract(const Duration(hours: 6)),
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
      InsightsCompanion.insert(
        userId: userId,
        title: 'Gym correlates with lower dining spend',
        body:
            'Weeks where you completed all 3 gym sessions had '
            '25% lower dining expenses on average.',
        type: 'correlation',
        confidenceScore: const Value(0.72),
        generatedAt: now.subtract(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      InsightsCompanion.insert(
        userId: userId,
        title: r'Reduce dining out to save ~$200/month',
        body:
            r'You spent an average of $380 on dining out per '
            'month. Cooking at home 2 more days/week could save '
            r'around $200.',
        type: 'suggestion',
        confidenceScore: const Value(0.80),
        generatedAt: now.subtract(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      InsightsCompanion.insert(
        userId: userId,
        title: 'Entertainment budget at 92%',
        body:
            r'You have used $138 of your $150 entertainment '
            'budget this month with 8 days remaining.',
        type: 'warning',
        confidenceScore: const Value(0.95),
        generatedAt: now.subtract(const Duration(hours: 12)),
        createdAt: now.subtract(const Duration(hours: 12)),
      ),
      InsightsCompanion.insert(
        userId: userId,
        title: 'Reading streak is your longest in 6 months',
        body:
            'Your current 12-day reading streak beats your '
            'previous best of 9 days. Keep it up!',
        type: 'trend',
        confidenceScore: const Value(0.90),
        isRead: const Value(true),
        generatedAt: now.subtract(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      InsightsCompanion.insert(
        userId: userId,
        title: 'Consider increasing savings allocation',
        body:
            'Your savings rate this quarter is 8%. Financial '
            'advisors recommend 15-20% for long-term goals.',
        type: 'suggestion',
        confidenceScore: const Value(0.75),
        generatedAt: now.subtract(const Duration(days: 5)),
        createdAt: now.subtract(const Duration(days: 5)),
      ),
    ];

    await _db.batch((b) {
      for (final e in entries) {
        b.insert(_db.insights, e);
      }
    });
  }

  // ── Settings ────────────────────────────────────────────────────

  Future<void> _seedSettings(String userId) async {
    await _db.settingsDao.upsertSettings(
      UserSettingsCompanion(
        userId: Value(userId),
        displayName: const Value('Test User'),
        currency: const Value('USD'),
        themeMode: const Value('system'),
        notificationsEnabled: const Value(true),
        dailyReminderEnabled: const Value(true),
        dailyReminderTime: const Value('09:00'),
        firstDayOfWeek: const Value(1),
        onboardingCompleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────

  /// Generates daily habit logs with a deterministic pseudo-random
  /// pattern.
  ///
  /// The last [streakDays] days are always logged (at or above
  /// [targetVal]) so the current streak is realistic.
  List<HabitLogsCompanion> _genDailyLogs({
    required int habitId,
    required int daysBack,
    required double rate,
    required double minVal,
    required double maxVal,
    required int streakDays,
    required double targetVal,
    required DateTime now,
    int endDaysAgo = 0,
  }) {
    final logs = <HabitLogsCompanion>[];
    for (var d = daysBack; d >= endDaysAgo; d--) {
      final date = now.subtract(Duration(days: d));
      final dateStr = _iso(date);

      // Force current streak
      if (d < streakDays + endDaysAgo) {
        final val = targetVal + ((habitId + d) % 3).toDouble();
        logs.add(_log(habitId, dateStr, val, date));
        continue;
      }

      // Deterministic "random"
      final hash = _hash(habitId, d);
      if (hash < (rate * 100).toInt()) {
        final frac = _hash(habitId * 3, d + 7) / 100.0;
        final val = minVal + (maxVal - minVal) * frac;
        logs.add(_log(habitId, dateStr, val, date));
      }
    }
    return logs;
  }

  /// Generates weekly habit logs (only on [activeDays] weekdays).
  List<HabitLogsCompanion> _genWeeklyLogs({
    required int habitId,
    required int daysBack,
    required double rate,
    required List<int> activeDays,
    required DateTime now,
    double minVal = 1,
    double maxVal = 1,
  }) {
    final logs = <HabitLogsCompanion>[];
    for (var d = daysBack; d >= 0; d--) {
      final date = now.subtract(Duration(days: d));
      if (!activeDays.contains(date.weekday)) continue;

      final hash = _hash(habitId, d);
      if (hash < (rate * 100).toInt()) {
        final frac = _hash(habitId * 5, d + 3) / 100.0;
        final val = minVal + (maxVal - minVal) * frac;
        logs.add(_log(habitId, _iso(date), val, date));
      }
    }
    return logs;
  }

  HabitLogsCompanion _log(
    int habitId,
    String date,
    double value,
    DateTime created,
  ) {
    return HabitLogsCompanion.insert(
      habitId: habitId,
      loggedDate: date,
      value: Value(value),
      createdAt: created,
    );
  }

  TransactionsCompanion _tx(
    String userId,
    int accountId,
    int categoryId,
    String type,
    int amountCents,
    String title,
    String date, {
    bool bookmarked = false,
  }) {
    final dt = DateTime.parse(date);
    return TransactionsCompanion.insert(
      userId: userId,
      accountId: accountId,
      categoryId: categoryId,
      type: type,
      amount: amountCents,
      title: title,
      transactionDate: date,
      isBookmarked: Value(bookmarked),
      createdAt: dt,
      updatedAt: dt,
    );
  }

  /// Returns a date string for day [day] of month [m].
  static String _d(DateTime m, int day) {
    final clamped = DateTime(m.year, m.month, day);
    return _iso(clamped);
  }

  /// Simple deterministic hash 0–99.
  static int _hash(int a, int b) {
    var h = (a * 31 + b * 17) & 0x7fffffff;
    h = ((h >> 16) ^ h) * 0x45d9f3b;
    return (h & 0x7fffffff) % 100;
  }

  /// ISO-8601 date (yyyy-MM-dd).
  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// Configuration for generating mock habit logs.
class _LogConfig {
  const _LogConfig._({
    required this.daysBack,
    required this.rate,
    required this.minVal,
    required this.maxVal,
    required this.streakDays,
    required this.targetVal,
    required this.endDaysAgo,
    this.activeDays,
  });

  factory _LogConfig.daily(
    int daysBack,
    double rate,
    double minVal,
    double maxVal, {
    int streak = 0,
    double target = 1,
    int endDaysAgo = 0,
  }) => _LogConfig._(
    daysBack: daysBack,
    rate: rate,
    minVal: minVal,
    maxVal: maxVal,
    streakDays: streak,
    targetVal: target,
    endDaysAgo: endDaysAgo,
  );

  factory _LogConfig.weekly(
    int daysBack,
    double rate,
    List<int> days, {
    double min = 1,
    double max = 1,
  }) => _LogConfig._(
    daysBack: daysBack,
    rate: rate,
    minVal: min,
    maxVal: max,
    streakDays: 0,
    targetVal: 1,
    endDaysAgo: 0,
    activeDays: days,
  );

  final int daysBack;
  final double rate;
  final double minVal;
  final double maxVal;
  final int streakDays;
  final double targetVal;
  final int endDaysAgo;
  final List<int>? activeDays;
}
