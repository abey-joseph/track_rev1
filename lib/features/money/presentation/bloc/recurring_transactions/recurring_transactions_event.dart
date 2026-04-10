import 'package:freezed_annotation/freezed_annotation.dart';

part 'recurring_transactions_event.freezed.dart';

@freezed
sealed class RecurringTransactionsEvent with _$RecurringTransactionsEvent {
  const factory RecurringTransactionsEvent.started({
    required String userId,
  }) = RecurringTransactionsStarted;

  const factory RecurringTransactionsEvent.deleteRequested({
    required int id,
  }) = RecurringTransactionsDeleteRequested;
}
