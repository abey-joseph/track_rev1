import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:track/core/database/app_database.dart';
import 'package:track/features/money/domain/entities/account_entity.dart';
import 'package:track/features/money/domain/entities/budget_entity.dart';
import 'package:track/features/money/domain/entities/category_entity.dart';
import 'package:track/features/money/domain/entities/currency_entity.dart';
import 'package:track/features/money/domain/entities/recurring_transaction_entity.dart';
import 'package:track/features/money/domain/entities/transaction_entity.dart';

// ── Account ───────────────────────────────────────────────────────────────────

extension AccountRowToEntity on Account {
  AccountEntity toEntity() => AccountEntity(
    id: id,
    userId: userId,
    name: name,
    type: _parseAccountType(type),
    balanceCents: balance,
    currency: currency,
    iconName: iconName,
    colorHex: colorHex,
    isDefault: isDefault,
    isArchived: isArchived,
    sortOrder: sortOrder,
    createdAt: createdAt,
    updatedAt: updatedAt,
    description: description,
  );
}

extension AccountEntityToCompanion on AccountEntity {
  AccountsCompanion toCompanion() => AccountsCompanion(
    id: id == 0 ? const Value.absent() : Value(id),
    userId: Value(userId),
    name: Value(name),
    type: Value(_accountTypeName(type)),
    balance: Value(balanceCents),
    currency: Value(currency),
    description: Value(description),
    iconName: Value(iconName),
    colorHex: Value(colorHex),
    isDefault: Value(isDefault),
    isArchived: Value(isArchived),
    sortOrder: Value(sortOrder),
    createdAt: Value(createdAt),
    updatedAt: Value(updatedAt),
  );
}

// ── Currency ──────────────────────────────────────────────────────────────────

extension CurrencyRowToEntity on Currency {
  CurrencyEntity toEntity() => CurrencyEntity(
    id: id,
    userId: userId,
    name: name,
    code: code,
    symbol: symbol,
    exchangeRate: exchangeRate,
    isDefault: isDefault,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

extension CurrencyEntityToCompanion on CurrencyEntity {
  CurrenciesCompanion toCompanion() => CurrenciesCompanion(
    id: id == 0 ? const Value.absent() : Value(id),
    userId: Value(userId),
    name: Value(name),
    code: Value(code),
    symbol: Value(symbol),
    exchangeRate: Value(exchangeRate),
    isDefault: Value(isDefault),
    createdAt: Value(createdAt),
    updatedAt: Value(updatedAt),
  );
}

// ── Category ──────────────────────────────────────────────────────────────────

extension CategoryRowToEntity on Category {
  CategoryEntity toEntity() => CategoryEntity(
    id: id,
    userId: userId,
    name: name,
    transactionType: _parseCategoryType(transactionType),
    iconName: iconName,
    colorHex: colorHex,
    isDefault: isDefault,
    sortOrder: sortOrder,
    createdAt: createdAt,
  );
}

extension CategoryEntityToCompanion on CategoryEntity {
  CategoriesCompanion toCompanion() => CategoriesCompanion(
    id: id == 0 ? const Value.absent() : Value(id),
    userId: Value(userId),
    name: Value(name),
    transactionType: Value(_categoryTypeName(transactionType)),
    iconName: Value(iconName),
    colorHex: Value(colorHex),
    isDefault: Value(isDefault),
    sortOrder: Value(sortOrder),
    createdAt: Value(createdAt),
  );
}

// ── Transaction ───────────────────────────────────────────────────────────────

extension TransactionRowToEntity on Transaction {
  TransactionEntity toEntity() => TransactionEntity(
    id: id,
    userId: userId,
    accountId: accountId,
    categoryId: categoryId,
    type: _parseTransactionType(type),
    amountCents: amount,
    title: title,
    note: note,
    isBookmarked: isBookmarked,
    transactionDate: transactionDate,
    transferPeerId: transferPeerId,
    sourceRecurringTransactionId: sourceRecurringTransactionId,
    sourceOccurrenceDate: sourceOccurrenceDate,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

extension TransactionEntityToCompanion on TransactionEntity {
  TransactionsCompanion toCompanion() => TransactionsCompanion(
    id: id == 0 ? const Value.absent() : Value(id),
    userId: Value(userId),
    accountId: Value(accountId),
    categoryId: Value(categoryId),
    type: Value(_transactionTypeName(type)),
    amount: Value(amountCents),
    title: Value(title),
    note: Value(note),
    isBookmarked: Value(isBookmarked),
    transactionDate: Value(transactionDate),
    transferPeerId: Value(transferPeerId),
    sourceRecurringTransactionId: Value(sourceRecurringTransactionId),
    sourceOccurrenceDate: Value(sourceOccurrenceDate),
    createdAt: Value(createdAt),
    updatedAt: Value(updatedAt),
  );
}

// ── Budget ────────────────────────────────────────────────────────────────────

extension BudgetRowToEntity on Budget {
  BudgetEntity toEntity() => BudgetEntity(
    id: id,
    userId: userId,
    name: name,
    categoryId: categoryId,
    amountLimitCents: amountLimit,
    period: _parseBudgetPeriod(period),
    isActive: isActive,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

extension BudgetEntityToCompanion on BudgetEntity {
  BudgetsCompanion toCompanion() => BudgetsCompanion(
    id: id == 0 ? const Value.absent() : Value(id),
    userId: Value(userId),
    name: Value(name),
    categoryId: Value(categoryId),
    amountLimit: Value(amountLimitCents),
    period: Value(_budgetPeriodName(period)),
    isActive: Value(isActive),
    createdAt: Value(createdAt),
    updatedAt: Value(updatedAt),
  );
}

// ── RecurringTransaction ─────────────────────────────────────────────────────

extension RecurringTransactionRowToEntity on RecurringTransaction {
  RecurringTransactionEntity toEntity() => RecurringTransactionEntity(
    id: id,
    userId: userId,
    accountId: accountId,
    categoryId: categoryId,
    type: _parseTransactionType(type),
    amountCents: amount,
    title: title,
    note: note,
    scheduleType: _parseScheduleType(scheduleType),
    startDate: startDate,
    weekdays:
        weekdaysJson != null
            ? (jsonDecode(weekdaysJson!) as List).cast<int>()
            : const [],
    monthDay: monthDay,
    monthDays:
        monthDaysJson != null
            ? (jsonDecode(monthDaysJson!) as List).cast<int>()
            : const [],
    timesPerMonth: timesPerMonth,
    isActive: isActive,
    isCompleted: isCompleted,
    lastGeneratedDate: lastGeneratedDate,
    completedAt: completedAt,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

extension RecurringTransactionEntityToCompanion on RecurringTransactionEntity {
  RecurringTransactionsCompanion toCompanion() =>
      RecurringTransactionsCompanion(
        id: id == 0 ? const Value.absent() : Value(id),
        userId: Value(userId),
        accountId: Value(accountId),
        categoryId: Value(categoryId),
        type: Value(_transactionTypeName(type)),
        amount: Value(amountCents),
        title: Value(title),
        note: Value(note),
        scheduleType: Value(_scheduleTypeName(scheduleType)),
        startDate: Value(startDate),
        weekdaysJson: Value(
          weekdays.isEmpty ? null : jsonEncode(weekdays),
        ),
        monthDay: Value(monthDay),
        monthDaysJson: Value(
          monthDays.isEmpty ? null : jsonEncode(monthDays),
        ),
        timesPerMonth: Value(timesPerMonth),
        isActive: Value(isActive),
        isCompleted: Value(isCompleted),
        lastGeneratedDate: Value(lastGeneratedDate),
        completedAt: Value(completedAt),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt),
      );
}

// ── Private helpers ───────────────────────────────────────────────────────────

AccountType _parseAccountType(String raw) => switch (raw) {
  'savings' => AccountType.savings,
  'cash' => AccountType.cash,
  'credit_card' => AccountType.creditCard,
  'investment' => AccountType.investment,
  _ => AccountType.checking,
};

String _accountTypeName(AccountType t) => switch (t) {
  AccountType.checking => 'checking',
  AccountType.savings => 'savings',
  AccountType.cash => 'cash',
  AccountType.creditCard => 'credit_card',
  AccountType.investment => 'investment',
};

CategoryTransactionType _parseCategoryType(String raw) => switch (raw) {
  'income' => CategoryTransactionType.income,
  'both' => CategoryTransactionType.both,
  _ => CategoryTransactionType.expense,
};

String _categoryTypeName(CategoryTransactionType t) => switch (t) {
  CategoryTransactionType.income => 'income',
  CategoryTransactionType.expense => 'expense',
  CategoryTransactionType.both => 'both',
};

TransactionType _parseTransactionType(String raw) => switch (raw) {
  'income' => TransactionType.income,
  'transfer' => TransactionType.transfer,
  _ => TransactionType.expense,
};

String _transactionTypeName(TransactionType t) => switch (t) {
  TransactionType.income => 'income',
  TransactionType.expense => 'expense',
  TransactionType.transfer => 'transfer',
};

BudgetPeriod _parseBudgetPeriod(String raw) => switch (raw) {
  'weekly' => BudgetPeriod.weekly,
  _ => BudgetPeriod.monthly,
};

String _budgetPeriodName(BudgetPeriod p) => switch (p) {
  BudgetPeriod.monthly => 'monthly',
  BudgetPeriod.weekly => 'weekly',
};

RecurringScheduleType _parseScheduleType(String raw) => switch (raw) {
  'daily' => RecurringScheduleType.daily,
  'weekly' => RecurringScheduleType.weekly,
  'monthlyFixed' => RecurringScheduleType.monthlyFixed,
  'monthlyMultiple' => RecurringScheduleType.monthlyMultiple,
  'once' => RecurringScheduleType.once,
  _ => RecurringScheduleType.daily,
};

String _scheduleTypeName(RecurringScheduleType t) => switch (t) {
  RecurringScheduleType.daily => 'daily',
  RecurringScheduleType.weekly => 'weekly',
  RecurringScheduleType.monthlyFixed => 'monthlyFixed',
  RecurringScheduleType.monthlyMultiple => 'monthlyMultiple',
  RecurringScheduleType.once => 'once',
};
