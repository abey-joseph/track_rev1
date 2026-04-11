import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:track/features/money/domain/entities/recurring_transaction_entity.dart';
import 'package:track/features/money/domain/entities/transaction_entity.dart';

part 'recurring_transaction_form_event.freezed.dart';

@freezed
sealed class RecurringTransactionFormEvent
    with _$RecurringTransactionFormEvent {
  const factory RecurringTransactionFormEvent.initialized({
    required String userId,
    RecurringTransactionEntity? existing,
  }) = RecurringTransactionFormInitialized;

  const factory RecurringTransactionFormEvent.typeChanged({
    required TransactionType type,
  }) = RecurringTransactionFormTypeChanged;

  const factory RecurringTransactionFormEvent.amountChanged({
    required String amount,
  }) = RecurringTransactionFormAmountChanged;

  const factory RecurringTransactionFormEvent.titleChanged({
    required String title,
  }) = RecurringTransactionFormTitleChanged;

  const factory RecurringTransactionFormEvent.categorySelected({
    required int categoryId,
  }) = RecurringTransactionFormCategorySelected;

  const factory RecurringTransactionFormEvent.accountSelected({
    required int accountId,
  }) = RecurringTransactionFormAccountSelected;

  const factory RecurringTransactionFormEvent.noteChanged({
    required String note,
  }) = RecurringTransactionFormNoteChanged;

  const factory RecurringTransactionFormEvent.scheduleTypeChanged({
    required RecurringScheduleType scheduleType,
  }) = RecurringTransactionFormScheduleTypeChanged;

  const factory RecurringTransactionFormEvent.startDateChanged({
    required DateTime date,
  }) = RecurringTransactionFormStartDateChanged;

  const factory RecurringTransactionFormEvent.weekdaysChanged({
    required List<int> weekdays,
  }) = RecurringTransactionFormWeekdaysChanged;

  const factory RecurringTransactionFormEvent.monthDayChanged({
    required int day,
  }) = RecurringTransactionFormMonthDayChanged;

  const factory RecurringTransactionFormEvent.monthDaysChanged({
    required List<int> days,
  }) = RecurringTransactionFormMonthDaysChanged;

  const factory RecurringTransactionFormEvent.timesPerMonthChanged({
    required int count,
  }) = RecurringTransactionFormTimesPerMonthChanged;

  const factory RecurringTransactionFormEvent.toAccountSelected({
    required int accountId,
  }) = RecurringTransactionFormToAccountSelected;

  const factory RecurringTransactionFormEvent.currencySelected({
    required String currencyCode,
  }) = RecurringTransactionFormCurrencySelected;

  const factory RecurringTransactionFormEvent.submitted({
    required String userId,
  }) = RecurringTransactionFormSubmitted;
}
