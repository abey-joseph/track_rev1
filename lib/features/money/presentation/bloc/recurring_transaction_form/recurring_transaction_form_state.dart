import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:track/features/money/domain/entities/account_entity.dart';
import 'package:track/features/money/domain/entities/category_entity.dart';
import 'package:track/features/money/domain/entities/currency_entity.dart';
import 'package:track/features/money/domain/entities/recurring_transaction_entity.dart';
import 'package:track/features/money/domain/entities/transaction_entity.dart';

part 'recurring_transaction_form_state.freezed.dart';

@freezed
abstract class RecurringTransactionFormState
    with _$RecurringTransactionFormState {
  const factory RecurringTransactionFormState({
    @Default(TransactionType.expense) TransactionType type,
    @Default('') String amount,
    @Default('') String title,
    @Default(null) int? categoryId,
    @Default(null) int? accountId,
    @Default('') String note,
    @Default(RecurringScheduleType.monthlyFixed)
    RecurringScheduleType scheduleType,
    @Default(null) DateTime? startDate,
    @Default([]) List<int> weekdays,
    @Default(null) int? monthDay,
    @Default([]) List<int> monthDays,
    @Default(null) int? timesPerMonth,
    @Default([]) List<CategoryEntity> allCategories,
    @Default([]) List<AccountEntity> availableAccounts,
    @Default([]) List<CurrencyEntity> availableCurrencies,
    @Default(null) int? toAccountId,
    @Default('USD') String selectedCurrencyCode,
    @Default(false) bool isSubmitting,
    @Default(false) bool isSuccess,
    @Default(false) bool isEditMode,
    @Default(null) int? existingId,
    @Default(false) bool existingIsCompleted,
    String? errorMessage,
  }) = _RecurringTransactionFormState;
}
