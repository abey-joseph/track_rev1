import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:track/features/money/domain/entities/transaction_entity.dart';

part 'transaction_form_event.freezed.dart';

@freezed
sealed class TransactionFormEvent with _$TransactionFormEvent {
  const factory TransactionFormEvent.initialized({
    required String userId,
  }) = TransactionFormInitialized;

  const factory TransactionFormEvent.typeChanged({
    required TransactionType type,
  }) = TransactionFormTypeChanged;

  const factory TransactionFormEvent.amountChanged({
    required String amount,
  }) = TransactionFormAmountChanged;

  const factory TransactionFormEvent.titleChanged({
    required String title,
  }) = TransactionFormTitleChanged;

  const factory TransactionFormEvent.categorySelected({
    required int categoryId,
  }) = TransactionFormCategorySelected;

  const factory TransactionFormEvent.accountSelected({
    required int accountId,
  }) = TransactionFormAccountSelected;

  const factory TransactionFormEvent.dateChanged({
    required DateTime date,
  }) = TransactionFormDateChanged;

  const factory TransactionFormEvent.noteChanged({
    required String note,
  }) = TransactionFormNoteChanged;

  const factory TransactionFormEvent.submitted({
    required String userId,
  }) = TransactionFormSubmitted;
}
