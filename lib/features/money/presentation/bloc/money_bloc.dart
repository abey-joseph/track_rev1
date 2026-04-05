import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:track/features/money/domain/entities/money_summary.dart';
import 'package:track/features/money/domain/entities/transaction_entity.dart';
import 'package:track/features/money/domain/entities/transaction_with_details.dart';
import 'package:track/features/money/domain/usecases/get_monthly_summary.dart';
import 'package:track/features/money/domain/usecases/get_transactions.dart';
import 'package:track/features/money/domain/usecases/watch_transactions.dart';
import 'package:track/features/money/presentation/bloc/money_event.dart';
import 'package:track/features/money/presentation/bloc/money_state.dart';

@injectable
class MoneyBloc extends Bloc<MoneyEvent, MoneyState> {
  MoneyBloc(
    this._watchTransactions,
    this._getTransactions,
    this._getMonthlySummary,
  ) : super(const MoneyState.initial()) {
    on<MoneyLoadRequested>(_onLoad);
    on<MoneyRefreshRequested>(_onRefresh);
  }

  final WatchTransactionsWithDetails _watchTransactions;
  final GetTransactionsWithDetails _getTransactions;
  final GetMonthlySummary _getMonthlySummary;
  String? _currentUserId;

  Future<void> _onLoad(
    MoneyLoadRequested event,
    Emitter<MoneyState> emit,
  ) async {
    _currentUserId = event.userId;
    emit(const MoneyState.loading());

    final now = DateTime.now();
    final fromDate =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-01';
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final toDate =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';

    await emit.forEach(
      _watchTransactions(
        MoneyParams(
          userId: event.userId,
          fromDate: fromDate,
          toDate: toDate,
        ),
      ),
      onData: (result) => result.fold(
        (failure) => MoneyState.error(failure: failure),
        (transactions) {
          // Compute summary from the transactions inline to avoid
          // an extra async call inside onData.
          final summary = _computeSummary(transactions);
          return MoneyState.loaded(
            transactions: transactions,
            summary: summary,
          );
        },
      ),
    );
  }

  MoneySummary _computeSummary(
    List<TransactionWithDetails> transactions,
  ) {
    var totalIncome = 0;
    var totalExpense = 0;
    final categoryTotals = <int, _CatAccum>{};

    for (final t in transactions) {
      final txn = t.transaction;
      if (txn.type == TransactionType.income) {
        totalIncome += txn.amountCents;
      } else if (txn.type == TransactionType.expense) {
        totalExpense += txn.amountCents;
        categoryTotals.putIfAbsent(
          txn.categoryId,
          () => _CatAccum(
            name: t.categoryName,
            iconName: t.categoryIconName,
            colorHex: t.categoryColorHex,
          ),
        );
        categoryTotals[txn.categoryId]!.amount += txn.amountCents;
      }
    }

    final sorted = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.amount.compareTo(a.value.amount));

    final topCategories = sorted.take(5).map((e) {
      return CategorySpending(
        categoryId: e.key,
        name: e.value.name,
        iconName: e.value.iconName,
        colorHex: e.value.colorHex,
        amountCents: e.value.amount,
      );
    }).toList();

    return MoneySummary(
      totalIncomeCents: totalIncome,
      totalExpenseCents: totalExpense,
      topCategories: topCategories,
    );
  }

  Future<void> _onRefresh(
    MoneyRefreshRequested event,
    Emitter<MoneyState> emit,
  ) async {
    if (_currentUserId != null) {
      add(MoneyLoadRequested(userId: _currentUserId!));
    }
  }
}

class _CatAccum {
  _CatAccum({
    required this.name,
    required this.iconName,
    required this.colorHex,
  });

  final String name;
  final String iconName;
  final String colorHex;
  int amount = 0;
}
