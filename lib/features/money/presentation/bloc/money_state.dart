import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/features/money/domain/entities/money_summary.dart';
import 'package:track/features/money/domain/entities/transaction_with_details.dart';

part 'money_state.freezed.dart';

@freezed
sealed class MoneyState with _$MoneyState {
  const factory MoneyState.initial() = MoneyInitial;
  const factory MoneyState.loading() = MoneyLoading;
  const factory MoneyState.loaded({
    required List<TransactionWithDetails> transactions,
    required MoneySummary summary,
  }) = MoneyLoaded;
  const factory MoneyState.error({required Failure failure}) = MoneyError;
}
