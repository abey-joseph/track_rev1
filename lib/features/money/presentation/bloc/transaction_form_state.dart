import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:track/features/money/domain/entities/account_entity.dart';
import 'package:track/features/money/domain/entities/category_entity.dart';
import 'package:track/features/money/domain/entities/currency_entity.dart';
import 'package:track/features/money/domain/entities/transaction_entity.dart';

part 'transaction_form_state.freezed.dart';

@freezed
abstract class TransactionFormState with _$TransactionFormState {
  const factory TransactionFormState({
    @Default(TransactionType.expense) TransactionType type,
    @Default('') String amount,
    @Default('') String title,
    @Default(null) int? categoryId,
    @Default(null) int? accountId,
    @Default(null) DateTime? date,
    @Default('') String note,
    @Default([]) List<CategoryEntity> allCategories,
    @Default([]) List<AccountEntity> availableAccounts,
    @Default([]) List<CurrencyEntity> availableCurrencies,
    @Default(null) int? toAccountId,
    @Default('USD') String selectedCurrencyCode,
    @Default(false) bool isSubmitting,
    @Default(false) bool isSuccess,
    String? errorMessage,
  }) = _TransactionFormState;
}
