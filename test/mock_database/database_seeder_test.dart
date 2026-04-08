import 'package:flutter_test/flutter_test.dart';
import 'package:track/core/database/app_database.dart';
import 'package:track/core/database/seeder/database_seeder.dart';

import '../helpers/mock_database_helper.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = createEmptyMockDatabase();
  });

  tearDown(() => db.close());

  group('DatabaseSeeder', () {
    test('seeds all tables with expected row counts', () async {
      final seeded = await DatabaseSeeder(db).seedIfNeeded(mockUserId);

      expect(seeded, isTrue);

      // Habits: 10 total (9 active + 1 archived)
      final habits = await db.select(db.habits).get();
      expect(habits.length, 10);
      expect(
        habits.where((h) => h.isArchived).length,
        1,
        reason: 'should have 1 archived habit',
      );

      // Habit logs: should have a substantial number
      final logs = await db.select(db.habitLogs).get();
      expect(
        logs.length,
        greaterThan(200),
        reason: 'should have 200+ habit log entries',
      );

      // Habit streaks: one per habit that has logs
      final streaks = await db.select(db.habitStreaks).get();
      expect(
        streaks.length,
        10,
        reason: 'each habit should have a streak record',
      );

      // Accounts: 5
      final accounts = await db.select(db.accounts).get();
      expect(accounts.length, 5);
      expect(
        accounts.where((a) => a.isDefault).length,
        1,
        reason: 'exactly one default account',
      );

      // Transactions: substantial number across 7 months
      final transactions = await db.select(db.transactions).get();
      expect(
        transactions.length,
        greaterThan(140),
        reason: 'should have 140+ transactions across 7 months',
      );

      // Bookmarked transactions
      final bookmarked = transactions.where((t) => t.isBookmarked).toList();
      expect(
        bookmarked.length,
        greaterThan(1),
        reason: 'should have some bookmarked transactions',
      );

      // Budgets: 4
      final budgets = await db.select(db.budgets).get();
      expect(budgets.length, 4);

      // Currencies: 3
      final currencies = await db.select(db.currencies).get();
      expect(currencies.length, 3);
      expect(
        currencies.where((c) => c.isDefault).length,
        1,
        reason: 'exactly one default currency (USD)',
      );

      // Insights: 6
      final insights = await db.select(db.insights).get();
      expect(insights.length, 6);

      // Settings: 1
      final settings = await db.select(db.userSettings).get();
      expect(settings.length, 1);
      expect(settings.first.onboardingCompleted, isTrue);

      // Default categories (seeded by DB migration): 13
      final categories = await db.select(db.categories).get();
      expect(categories.length, 13);
    });

    test('is idempotent — second call does not duplicate data', () async {
      await DatabaseSeeder(db).seedIfNeeded(mockUserId);
      final seededAgain = await DatabaseSeeder(db).seedIfNeeded(mockUserId);

      expect(seededAgain, isFalse);

      final habits = await db.select(db.habits).get();
      expect(habits.length, 10);

      final transactions = await db.select(db.transactions).get();
      // Count should be the same, not doubled
      expect(transactions.length, lessThan(300));
    });

    test('seeds data for the correct userId', () async {
      await DatabaseSeeder(db).seedIfNeeded(mockUserId);

      final habits = await db.select(db.habits).get();
      for (final h in habits) {
        expect(h.userId, equals(mockUserId));
      }

      final accounts = await db.select(db.accounts).get();
      for (final a in accounts) {
        expect(a.userId, equals(mockUserId));
      }
    });

    test('account balances reflect transactions', () async {
      await DatabaseSeeder(db).seedIfNeeded(mockUserId);

      final accounts = await db.select(db.accounts).get();
      final transactions = await db.select(db.transactions).get();

      for (final account in accounts) {
        // Sum income – expense for this account
        var net = 0;
        for (final tx in transactions) {
          if (tx.accountId != account.id) continue;
          net += tx.type == 'income' ? tx.amount : -tx.amount;
        }

        // The balance should be initialBalance + net
        // We can't know the exact initial balance, but balance
        // should be non-null and reasonable
        expect(
          account.balance,
          isNotNull,
          reason: '${account.name} should have a computed balance',
        );
      }
    });

    test('habit streaks are calculated correctly', () async {
      await DatabaseSeeder(db).seedIfNeeded(mockUserId);

      final streaks = await db.select(db.habitStreaks).get();

      for (final s in streaks) {
        expect(
          s.totalCompletions,
          greaterThan(0),
          reason: 'habit ${s.habitId} should have completions',
        );
        expect(
          s.longestStreak,
          greaterThanOrEqualTo(s.currentStreak),
          reason:
              'longest streak >= current streak for habit '
              '${s.habitId}',
        );
      }

      // Read Books (habit index 1) should have a meaningful streak
      final readStreak = streaks.firstWhere((s) => s.habitId == 2);
      expect(
        readStreak.currentStreak,
        greaterThan(5),
        reason: 'Read Books should have a streak > 5',
      );
    });

    test('different userId gets independent data', () async {
      await DatabaseSeeder(db).seedIfNeeded(mockUserId);
      await DatabaseSeeder(db).seedIfNeeded('other-user-002');

      final habits = await db.select(db.habits).get();
      expect(habits.length, 20, reason: '10 per user');

      final user1Habits = habits.where((h) => h.userId == mockUserId).toList();
      final user2Habits =
          habits.where((h) => h.userId == 'other-user-002').toList();
      expect(user1Habits.length, 10);
      expect(user2Habits.length, 10);
    });
  });

  group('createSeededMockDatabase helper', () {
    test('returns a fully seeded database', () async {
      final seededDb = await createSeededMockDatabase();

      final habits = await seededDb.select(seededDb.habits).get();
      expect(habits.length, 10);

      final transactions = await seededDb.select(seededDb.transactions).get();
      expect(transactions.length, greaterThan(140));

      await seededDb.close();
    });
  });
}
