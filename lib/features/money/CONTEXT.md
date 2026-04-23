# money — CONTEXT

Transactions, accounts, categories, currencies, budgets, and recurring-transaction rules. All amounts are stored as **integer cents** (never doubles). Largest feature in the codebase — every sub-area has its own BLoC.

## Key files

### Domain

#### Entities
- `transaction_entity.dart` — `TransactionEntity { id, userId, accountId, categoryId, type (income/expense/transfer), amountCents, title, transactionDate (ISO yyyy-MM-dd), isBookmarked, note?, originalCurrencyCode='USD', originalAmountCents=0, transferPeerId?, sourceRecurringTransactionId?, sourceOccurrenceDate?, createdAt, updatedAt }` + `enum TransactionType { income, expense, transfer }`.
- `transaction_with_details.dart` — `TransactionWithDetails { transaction, categoryName, categoryIconName, categoryColorHex, accountName, currencyCode='USD', currencySymbol='$', toAccountName? }`.
- `account_entity.dart` — `AccountEntity { id, userId, name, type (checking/savings/cash/creditCard/investment), balanceCents, currency (ISO-4217), iconName, colorHex, isDefault, isArchived, sortOrder, description?, createdAt, updatedAt }`.
- `category_entity.dart` — `CategoryEntity { id, name, transactionType (income/expense/both/transfer), iconName, colorHex, isDefault, sortOrder, createdAt, userId? (null = system default) }`.
- `currency_entity.dart` — `CurrencyEntity { id, userId, name, code (ISO-4217), symbol, exchangeRate (1.0 for default), isDefault, createdAt, updatedAt }`.
- `budget_entity.dart` — `BudgetEntity { id, userId, name, amountLimitCents, period (monthly/weekly), isActive, categoryId? (null = overall), createdAt, updatedAt }`.
- `recurring_transaction_entity.dart` — `RecurringTransactionEntity { id, userId, accountId, categoryId, type, amountCents, title, scheduleType (daily/weekly/monthlyFixed/monthlyMultiple/once), startDate, toAccountId? (transfers), weekdays, monthDay?, monthDays, timesPerMonth?, isActive, isCompleted, lastGeneratedDate?, completedAt?, originalCurrencyCode/originalAmountCents, ... }`.
- `money_summary.dart` — `MoneySummary { totalIncomeCents, totalExpenseCents, topCategories: List<CategorySpending> }`, `CategorySpending { categoryId, name, iconName, colorHex, amountCents }`.

#### Use cases (one per verb, `@lazySingleton`)
Transactions: `CreateTransaction`, `CreateTransfer`, `DeleteTransaction`, `GetTransactionsWithDetails`, `WatchTransactionsWithDetails`, `SetTransactionBookmark`, `WatchBookmarkedTransactions`, `GetMonthlySummary`.
Accounts: `CreateAccount`, `UpdateAccount`, `DeleteAccount`, `GetAccounts`, `WatchAccounts`, `SetDefaultAccount`.
Categories: `CreateCategory`, `UpdateCategory`, `DeleteCategory`, `GetCategories`, `WatchCategories`.
Currencies: `CreateCurrency`, `UpdateCurrency`, `DeleteCurrency`, `WatchCurrencies`.
Recurring: `CreateRecurringTransaction`, `UpdateRecurringTransaction`, `DeleteRecurringTransaction`, `WatchRecurringTransactions`, `ProcessDueRecurringTransactions`.

### Data
- `datasources/money_local_data_source.dart` — delegates to `MoneyDao`.
- `mappers/money_mapper.dart` — Drift ↔ entity for all money types.
- `repositories/money_repository_impl.dart` — `@LazySingleton(as: MoneyRepository)`.

### Presentation

#### Main BLoC
- `bloc/money_bloc.dart` — loads monthly transactions + computes a `MoneySummary` inline; runs `ProcessDueRecurringTransactions` before loading; re-uses `emit.forEach` on a stream. Events: `loadRequested(userId)`, `refreshRequested`. State: `initial|loading|loaded(transactions, summary)|error`.

#### Sub-BLoCs (one folder per area)
- `bloc/accounts/`, `bloc/account_form/`
- `bloc/all_transactions/` (full-list page), `bloc/bookmarks/`
- `bloc/categories/`, `bloc/category_form/`
- `bloc/currency/`, `bloc/currency_form/`
- `bloc/recurring_transactions/`, `bloc/recurring_transaction_form/`
- `bloc/transaction_form_bloc.dart` (+ event/state files alongside) — note: **not** namespaced in a subfolder, unlike the others.

#### Pages
`money_page.dart`, `all_transactions_page.dart`, `transaction_detail_page.dart`, `transaction_create_edit_page.dart`, `bookmarks_page.dart`, `accounts_page.dart`, `account_detail_page.dart`, `account_create_edit_page.dart`, `categories_page.dart`, `category_create_edit_page.dart`, `currency_page.dart`, `currency_create_edit_page.dart`, `recurring_transactions_page.dart`, `recurring_transaction_create_edit_page.dart`, `budget_page.dart`, `budget_detail_page.dart`.

#### Utils / widgets
- `utils/currency_formatter.dart` — cents → display string.
- `utils/money_icon_resolver.dart` — icon name string → `IconData`.
- `widgets/account_picker_grid.dart`, `account_picker_sheet.dart`
- `widgets/category_picker_grid.dart`, `category_picker_sheet.dart`, `category_breakdown_widget.dart`
- `widgets/money_overview_card.dart`
- `widgets/transaction_list_item.dart`, `transaction_date_group.dart`, `transaction_type_toggle.dart`.

## Public surface — `MoneyRepository`
Grouped (see `domain/repositories/money_repository.dart` for exact signatures):
- **Transactions:** `watchTransactionsWithDetails(userId, {fromDate, toDate})`, `getTransactionsWithDetails(...)`, `getMonthlySummary(userId, year, month)`, `createTransaction`, `createTransfer({fromTransaction, toAccountId})` (atomic pair; returns "from" id), `deleteTransaction`, `watchBookmarkedTransactions`, `setBookmark(id, {isBookmarked})`.
- **Accounts:** `getAccounts`, `watchAccounts`, `createAccount`, `updateAccount`, `deleteAccount(id, userId)`, `setDefaultAccount(accountId, userId)`.
- **Categories:** `getCategories`, `watchCategories`, `createCategory`, `updateCategory`, `deleteCategory(id)`.
- **Currencies:** `getCurrencies`, `watchCurrencies`, `createCurrency`, `updateCurrency`, `deleteCurrency(id, userId)` — fails with `Failure.cache` if in-use.
- **Recurring:** `getRecurringTransactions`, `watchRecurringTransactions`, `createRecurringTransaction`, `updateRecurringTransaction`, `deleteRecurringTransaction(id)`, `processDueRecurringTransactions(userId, now)`.

## Gotchas
- **Amounts are always positive `int` cents.** Never store negative numbers; `type` (income/expense/transfer) determines sign in presentation.
- Transfers are **two** transaction rows paired via `transferPeerId`. Use `createTransfer` — never insert two rows manually.
- Recurring-transaction processing is triggered every `MoneyLoadRequested`; it's idempotent via `lastGeneratedDate`.
- Original-currency fields (`originalCurrencyCode`, `originalAmountCents`) carry the user's entered amount pre-conversion. `amountCents` is already converted to the account's currency. FX conversion lives in `MoneyDao`.
- `deleteCurrency` enforces referential integrity at the repo level (not via FK) — surface `Failure.cache` to the user.
- `transaction_form_bloc.dart` lives at `bloc/` root (no subfolder) — if adding another form bloc, follow the **subfolder** convention (`account_form/`, `category_form/`, …).
- **BlocSelector Mandate:** transaction lists and account lists must use the parent-IDs / child-selector pattern — never a single `BlocBuilder` around the whole list (see `CLAUDE.md`).
- `MoneyBloc` keeps `_currentUserId` for `refreshRequested`; forgetting `loadRequested(userId)` first means refresh is a no-op.
