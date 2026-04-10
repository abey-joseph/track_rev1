import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:track/core/extensions/context_extensions.dart';
import 'package:track/core/router/app_router.gr.dart';
import 'package:track/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:track/features/auth/presentation/bloc/auth_state.dart';
import 'package:track/features/money/domain/entities/recurring_transaction_entity.dart';
import 'package:track/features/money/domain/entities/transaction_entity.dart';
import 'package:track/features/money/presentation/bloc/recurring_transactions/recurring_transactions_bloc.dart';
import 'package:track/features/money/presentation/bloc/recurring_transactions/recurring_transactions_event.dart';
import 'package:track/features/money/presentation/bloc/recurring_transactions/recurring_transactions_state.dart';
import 'package:track/features/money/presentation/utils/currency_formatter.dart'
    as fmt;
import 'package:track/injection.dart';

@RoutePage()
class RecurringTransactionsPage extends StatelessWidget {
  const RecurringTransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is Authenticated ? authState.user.uid : '';

    return BlocProvider(
      create:
          (_) =>
              getIt<RecurringTransactionsBloc>()
                ..add(RecurringTransactionsEvent.started(userId: userId)),
      child: const _RecurringTransactionsView(),
    );
  }
}

class _RecurringTransactionsView extends StatelessWidget {
  const _RecurringTransactionsView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<RecurringTransactionsBloc, RecurringTransactionsState>(
      listenWhen: (prev, curr) {
        if (prev is RecurringTransactionsLoaded &&
            curr is RecurringTransactionsLoaded) {
          return curr.deleteError != null &&
              curr.deleteError != prev.deleteError;
        }
        return false;
      },
      listener: (context, state) {
        if (state is RecurringTransactionsLoaded && state.deleteError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.deleteError!),
              backgroundColor: context.colorScheme.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Recurring Transactions')),
        body:
            BlocBuilder<RecurringTransactionsBloc, RecurringTransactionsState>(
              builder:
                  (context, state) => switch (state) {
                    RecurringTransactionsInitial() ||
                    RecurringTransactionsLoading() => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    RecurringTransactionsLoaded() => _RecurringList(
                      state: state,
                    ),
                    RecurringTransactionsError() => Center(
                      child: Text(
                        'Failed to load recurring transactions',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colorScheme.error,
                        ),
                      ),
                    ),
                  },
            ),
        floatingActionButton: FloatingActionButton(
          onPressed:
              () => context.router.push(
                RecurringTransactionCreateEditRoute(),
              ),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _RecurringList extends StatelessWidget {
  const _RecurringList({required this.state});

  final RecurringTransactionsLoaded state;

  @override
  Widget build(BuildContext context) {
    if (state.recurringTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.autorenew_rounded,
              size: 64,
              color: context.colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No recurring transactions yet',
              style: context.textTheme.titleMedium?.copyWith(
                color: context.colorScheme.onSurface.withValues(
                  alpha: 0.6,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurface.withValues(
                  alpha: 0.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Sort: active items first, completed after.
    final sorted = [...state.recurringTransactions]..sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      return b.createdAt.compareTo(a.createdAt);
    });

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final item = sorted[index];
        return BlocSelector<
          RecurringTransactionsBloc,
          RecurringTransactionsState,
          RecurringTransactionEntity?
        >(
          selector:
              (s) =>
                  s is RecurringTransactionsLoaded
                      ? s.recurringTransactions
                          .where((r) => r.id == item.id)
                          .firstOrNull
                      : null,
          builder: (context, entity) {
            if (entity == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RecurringTransactionCard(entity: entity),
            );
          },
        );
      },
    );
  }
}

class _RecurringTransactionCard extends StatelessWidget {
  const _RecurringTransactionCard({required this.entity});

  final RecurringTransactionEntity entity;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final isIncome = entity.type == TransactionType.income;
    final amountColor =
        isIncome ? const Color(0xFF4CAF50) : const Color(0xFFF44336);
    final amountPrefix = isIncome ? '+' : '-';

    return GestureDetector(
      onLongPress: () => _showDeleteDialog(context, entity),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: amountColor, width: 4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: amountColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.autorenew_rounded,
                        color: amountColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  entity.title,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (entity.isCompleted)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Completed',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.6,
                                      ),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 4),
                              InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap:
                                    () => context.router.push(
                                      RecurringTransactionCreateEditRoute(
                                        existing: entity,
                                      ),
                                    ),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.edit_rounded,
                                    size: 18,
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _scheduleDescription(entity),
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      '$amountPrefix${fmt.formatCurrency(entity.amountCents)}',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: amountColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _scheduleDescription(RecurringTransactionEntity e) {
    switch (e.scheduleType) {
      case RecurringScheduleType.daily:
        return 'Daily';
      case RecurringScheduleType.weekly:
        final dayNames = e.weekdays.map(_weekdayName).join(', ');
        return 'Weekly: $dayNames';
      case RecurringScheduleType.monthlyFixed:
        final day = e.monthDay ?? 1;
        final suffix = _daySuffix(day);
        if (day > 28) {
          return 'Monthly on the $day$suffix '
              '(or last day if unavailable)';
        }
        return 'Monthly on the $day$suffix';
      case RecurringScheduleType.monthlyMultiple:
        final days = e.monthDays..sort();
        final dayStr = days.map((d) => '$d').join(', ');
        final hasHighDay = days.any((d) => d > 28);
        if (hasHighDay) {
          return 'Monthly on $dayStr '
              '(missing days move to month end)';
        }
        return 'Monthly on $dayStr';
      case RecurringScheduleType.once:
        return 'Once: ${e.startDate}';
    }
  }

  String _weekdayName(int d) => switch (d) {
    1 => 'Mon',
    2 => 'Tue',
    3 => 'Wed',
    4 => 'Thu',
    5 => 'Fri',
    6 => 'Sat',
    7 => 'Sun',
    _ => '?',
  };

  String _daySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    return switch (day % 10) {
      1 => 'st',
      2 => 'nd',
      3 => 'rd',
      _ => 'th',
    };
  }

  void _showDeleteDialog(
    BuildContext context,
    RecurringTransactionEntity entity,
  ) {
    showDialog<void>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Delete Recurring Transaction?'),
            content: Text(
              'Delete "${entity.title}"? '
              'Already generated transactions will not be affected.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: context.colorScheme.error,
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  context.read<RecurringTransactionsBloc>().add(
                    RecurringTransactionsEvent.deleteRequested(
                      id: entity.id,
                    ),
                  );
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}
