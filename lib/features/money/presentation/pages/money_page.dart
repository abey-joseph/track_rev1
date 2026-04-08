import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:track/core/constants/animation_constants.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/core/extensions/context_extensions.dart';
import 'package:track/core/router/app_router.gr.dart';
import 'package:track/features/money/domain/entities/money_summary.dart';
import 'package:track/features/money/domain/entities/transaction_with_details.dart';
import 'package:track/features/money/presentation/bloc/money_bloc.dart';
import 'package:track/features/money/presentation/bloc/money_event.dart';
import 'package:track/features/money/presentation/bloc/money_state.dart';
import 'package:track/features/money/presentation/widgets/category_breakdown_widget.dart';
import 'package:track/features/money/presentation/widgets/money_overview_card.dart';
import 'package:track/features/money/presentation/widgets/transaction_date_group.dart';
import 'package:track/features/money/presentation/widgets/transaction_list_item.dart';

enum _MoneyMenuOption { bookmarks, accounts, currencies }

@RoutePage()
class MoneyPage extends StatelessWidget {
  const MoneyPage({super.key});

  @override
  Widget build(BuildContext context) {
    // MoneyBloc is provided by AppShellPage — no local BlocProvider needed.
    return const _MoneyView();
  }
}

class _MoneyView extends StatelessWidget {
  const _MoneyView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Money'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded),
            tooltip: 'All Transactions',
            onPressed: () => context.router.push(const AllTransactionsRoute()),
          ),
          PopupMenuButton<_MoneyMenuOption>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'More options',
            onSelected: (option) {
              switch (option) {
                case _MoneyMenuOption.bookmarks:
                  context.router.push(const BookmarksRoute());
                case _MoneyMenuOption.accounts:
                  context.router.push(const AccountsRoute());
                case _MoneyMenuOption.currencies:
                  context.router.push(const CurrencyRoute());
              }
            },
            itemBuilder:
                (_) => const [
                  PopupMenuItem(
                    value: _MoneyMenuOption.bookmarks,
                    child: ListTile(
                      leading: Icon(Icons.bookmark_rounded),
                      title: Text('Bookmarks'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: _MoneyMenuOption.accounts,
                    child: ListTile(
                      leading: Icon(Icons.account_balance_wallet_rounded),
                      title: Text('Accounts'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: _MoneyMenuOption.currencies,
                    child: ListTile(
                      leading: Icon(Icons.currency_exchange_rounded),
                      title: Text('Currencies'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: BlocBuilder<MoneyBloc, MoneyState>(
        buildWhen: (prev, curr) => prev.runtimeType != curr.runtimeType,
        builder:
            (context, state) => switch (state) {
              MoneyInitial() || MoneyLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
              MoneyLoaded() => _MoneyContent(
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),
              MoneyError(:final failure) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: colorScheme.error.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      switch (failure) {
                        ServerFailure(:final message) => message,
                        CacheFailure(:final message) => message,
                        NetworkFailure(:final message) => message,
                        AuthFailure(:final message) => message,
                        UnexpectedFailure(:final message) => message,
                      },
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed:
                          () => context.read<MoneyBloc>().add(
                            const MoneyEvent.refreshRequested(),
                          ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            },
      ),
    );
  }
}

class _MoneyContent extends StatelessWidget {
  const _MoneyContent({
    required this.colorScheme,
    required this.textTheme,
  });

  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MoneyBloc, MoneyState>(
      buildWhen: (prev, curr) {
        if (prev.runtimeType != curr.runtimeType) return true;
        if (prev is MoneyLoaded && curr is MoneyLoaded) {
          final prevIds =
              prev.transactions.map((t) => t.transaction.id).toList();
          final currIds =
              curr.transactions.map((t) => t.transaction.id).toList();
          return !listEquals(prevIds, currIds) || prev.summary != curr.summary;
        }
        return true;
      },
      builder: (context, state) {
        if (state is! MoneyLoaded) return const SizedBox.shrink();

        if (state.transactions.isEmpty) {
          return _buildEmptyState(colorScheme, textTheme);
        }

        final groups = TransactionDateGroup.groupByDate(state.transactions);
        final dateKeys = groups.keys.toList();

        return CustomScrollView(
          slivers: [
            // Summary cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _SummarySelector(),
              ),
            ),
            // Category breakdown
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _CategoryBreakdownSelector(),
              ),
            ),
            // Section header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Text(
                  'Recent Transactions',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
            // Date-grouped transactions
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index < dateKeys.length) {
                      final dateLabel = dateKeys[index];
                      final txns = groups[dateLabel]!;
                      return _AnimatedDateGroup(
                        dateLabel: dateLabel,
                        transactionIds:
                            txns.map((t) => t.transaction.id).toList(),
                        index: index,
                      );
                    }
                    // Bottom spacer
                    return const SizedBox(height: 100);
                  },
                  childCount: dateKeys.length + 1,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static Widget _buildEmptyState(ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Your finances will appear here',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Track income, expenses, and budgets',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Selects only the summary from BLoC state to minimize rebuilds.
class _SummarySelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocSelector<MoneyBloc, MoneyState, MoneySummary?>(
      selector: (state) => state is MoneyLoaded ? state.summary : null,
      builder: (context, summary) {
        if (summary == null) return const SizedBox.shrink();
        return MoneyOverviewCard(summary: summary);
      },
    );
  }
}

/// Selects only the category breakdown data.
class _CategoryBreakdownSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocSelector<MoneyBloc, MoneyState, (List<CategorySpending>, int)?>(
      selector:
          (state) =>
              state is MoneyLoaded
                  ? (
                    state.summary.topCategories,
                    state.summary.totalExpenseCents,
                  )
                  : null,
      builder: (context, data) {
        if (data == null || data.$1.isEmpty) return const SizedBox.shrink();
        return CategoryBreakdownWidget(
          categories: data.$1,
          totalExpenseCents: data.$2,
        );
      },
    );
  }
}

class _AnimatedDateGroup extends StatefulWidget {
  const _AnimatedDateGroup({
    required this.dateLabel,
    required this.transactionIds,
    required this.index,
  });

  final String dateLabel;
  final List<int> transactionIds;
  final int index;

  @override
  State<_AnimatedDateGroup> createState() => _AnimatedDateGroupState();
}

class _AnimatedDateGroupState extends State<_AnimatedDateGroup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AnimationConstants.defaultDuration,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: AnimationConstants.enterCurve,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AnimationConstants.enterCurve,
      ),
    );

    Future.delayed(
      Duration(
        milliseconds:
            AnimationConstants.staggerDelay.inMilliseconds * widget.index,
      ),
      () {
        if (mounted) _controller.forward();
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
              child: Text(
                widget.dateLabel,
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
            ...widget.transactionIds.map(
              (id) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _TransactionItemSelector(transactionId: id),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Selects only its own TransactionWithDetails by ID.
class _TransactionItemSelector extends StatelessWidget {
  const _TransactionItemSelector({required this.transactionId});

  final int transactionId;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<MoneyBloc, MoneyState, TransactionWithDetails?>(
      selector: (state) {
        if (state is! MoneyLoaded) return null;
        return state.transactions
            .where((t) => t.transaction.id == transactionId)
            .firstOrNull;
      },
      builder: (context, txn) {
        if (txn == null) return const SizedBox.shrink();
        return TransactionListItem(transaction: txn);
      },
    );
  }
}
