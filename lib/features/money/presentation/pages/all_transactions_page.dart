import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:track/core/constants/animation_constants.dart';
import 'package:track/core/extensions/context_extensions.dart';
import 'package:track/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:track/features/auth/presentation/bloc/auth_state.dart';
import 'package:track/features/money/domain/entities/account_entity.dart';
import 'package:track/features/money/domain/entities/category_entity.dart';
import 'package:track/features/money/domain/entities/transaction_entity.dart';
import 'package:track/features/money/domain/entities/transaction_with_details.dart';
import 'package:track/features/money/presentation/bloc/all_transactions/all_transactions_bloc.dart';
import 'package:track/features/money/presentation/bloc/all_transactions/all_transactions_event.dart';
import 'package:track/features/money/presentation/bloc/all_transactions/all_transactions_state.dart';
import 'package:track/features/money/presentation/utils/currency_formatter.dart';
import 'package:track/features/money/presentation/widgets/transaction_date_group.dart';
import 'package:track/injection.dart';

@RoutePage()
class AllTransactionsPage extends StatelessWidget {
  const AllTransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is Authenticated ? authState.user.uid : '';

    return BlocProvider(
      create:
          (_) =>
              getIt<AllTransactionsBloc>()
                ..add(AllTransactionsEvent.loadRequested(userId: userId)),
      child: const _AllTransactionsView(),
    );
  }
}

class _AllTransactionsView extends StatelessWidget {
  const _AllTransactionsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const _MonthNavigator(),
        centerTitle: true,
        actions: [
          _FilterToggleButton(),
          const _SortMenuButton(),
        ],
      ),
      body: const Column(
        children: [
          _FilterPanel(),
          Expanded(child: _TransactionList()),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AppBar Widgets
// ---------------------------------------------------------------------------

class _MonthNavigator extends StatelessWidget {
  const _MonthNavigator();

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;

    return BlocSelector<AllTransactionsBloc, AllTransactionsState, (int, int)>(
      selector: (state) => (state.year, state.month),
      builder: (context, data) {
        final (year, month) = data;
        if (month == 0) return const SizedBox.shrink();

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, size: 24),
              onPressed: () {
                final (py, pm) = _prevMonth(year, month);
                context.read<AllTransactionsBloc>().add(
                  AllTransactionsEvent.monthChanged(year: py, month: pm),
                );
              },
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            Text(
              _monthLabel(year, month),
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 24),
              onPressed: () {
                final (ny, nm) = _nextMonth(year, month);
                context.read<AllTransactionsBloc>().add(
                  AllTransactionsEvent.monthChanged(year: ny, month: nm),
                );
              },
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        );
      },
    );
  }
}

class _FilterToggleButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocSelector<AllTransactionsBloc, AllTransactionsState, (bool, int)>(
      selector: (state) => (state.isFilterExpanded, state.activeFilterCount),
      builder: (context, data) {
        final (isExpanded, filterCount) = data;
        return Badge(
          isLabelVisible: filterCount > 0,
          label: Text('$filterCount'),
          child: IconButton(
            icon: Icon(
              isExpanded ? Icons.filter_list_off : Icons.filter_list,
            ),
            onPressed:
                () => context.read<AllTransactionsBloc>().add(
                  const AllTransactionsEvent.filterPanelToggled(),
                ),
          ),
        );
      },
    );
  }
}

class _SortMenuButton extends StatelessWidget {
  const _SortMenuButton();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      AllTransactionsBloc,
      AllTransactionsState,
      (TransactionSortField, bool)
    >(
      selector: (state) => (state.sortField, state.sortAscending),
      builder: (context, data) {
        final (currentField, currentAsc) = data;
        return PopupMenuButton<(TransactionSortField, bool)>(
          icon: const Icon(Icons.sort),
          onSelected: (value) {
            context.read<AllTransactionsBloc>().add(
              AllTransactionsEvent.sortChanged(
                sortField: value.$1,
                ascending: value.$2,
              ),
            );
          },
          itemBuilder:
              (_) => [
                _sortItem(
                  'Date (newest)',
                  TransactionSortField.date,
                  false,
                  currentField,
                  currentAsc,
                ),
                _sortItem(
                  'Date (oldest)',
                  TransactionSortField.date,
                  true,
                  currentField,
                  currentAsc,
                ),
                const PopupMenuDivider(),
                _sortItem(
                  'Amount (highest)',
                  TransactionSortField.amount,
                  false,
                  currentField,
                  currentAsc,
                ),
                _sortItem(
                  'Amount (lowest)',
                  TransactionSortField.amount,
                  true,
                  currentField,
                  currentAsc,
                ),
                const PopupMenuDivider(),
                _sortItem(
                  'Title (A-Z)',
                  TransactionSortField.title,
                  true,
                  currentField,
                  currentAsc,
                ),
                _sortItem(
                  'Title (Z-A)',
                  TransactionSortField.title,
                  false,
                  currentField,
                  currentAsc,
                ),
              ],
        );
      },
    );
  }

  PopupMenuItem<(TransactionSortField, bool)> _sortItem(
    String label,
    TransactionSortField field,
    bool asc,
    TransactionSortField currentField,
    bool currentAsc,
  ) {
    final isSelected = field == currentField && asc == currentAsc;
    return PopupMenuItem(
      value: (field, asc),
      child: Row(
        children: [
          if (isSelected)
            const Icon(Icons.check, size: 18)
          else
            const SizedBox(width: 18),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter Panel
// ---------------------------------------------------------------------------

class _FilterPanel extends StatelessWidget {
  const _FilterPanel();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AllTransactionsBloc, AllTransactionsState, bool>(
      selector: (state) => state.isFilterExpanded,
      builder: (context, isExpanded) {
        return AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity, height: 0),
          secondChild: const _FilterPanelContent(),
          crossFadeState:
              isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: AnimationConstants.defaultDuration,
          sizeCurve: AnimationConstants.defaultCurve,
        );
      },
    );
  }
}

class _FilterPanelContent extends StatefulWidget {
  const _FilterPanelContent();

  @override
  State<_FilterPanelContent> createState() => _FilterPanelContentState();
}

class _FilterPanelContentState extends State<_FilterPanelContent> {
  final _searchController = TextEditingController();
  final _minAmountController = TextEditingController();
  final _maxAmountController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return Container(
      color: colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search
          SizedBox(
            height: 40,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            context.read<AllTransactionsBloc>().add(
                              const AllTransactionsEvent.searchQueryChanged(
                                query: '',
                              ),
                            );
                          },
                        )
                        : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              style: textTheme.bodySmall,
              onChanged: (value) {
                setState(() {});
                context.read<AllTransactionsBloc>().add(
                  AllTransactionsEvent.searchQueryChanged(query: value),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Type chips
          const _FilterSectionLabel(label: 'Type'),
          const SizedBox(height: 4),
          const _TypeFilterChips(),
          const SizedBox(height: 10),

          // Category chips
          const _FilterSectionLabel(label: 'Category'),
          const SizedBox(height: 4),
          const _CategoryFilterChips(),
          const SizedBox(height: 10),

          // Account chips
          const _FilterSectionLabel(label: 'Account'),
          const SizedBox(height: 4),
          const _AccountFilterChips(),
          const SizedBox(height: 10),

          // Amount range
          const _FilterSectionLabel(label: 'Amount range'),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    controller: _minAmountController,
                    decoration: InputDecoration(
                      hintText: 'Min',
                      prefixText: r'$ ',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    style: textTheme.bodySmall,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => _onAmountRangeChanged(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('to', style: textTheme.bodySmall),
              ),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    controller: _maxAmountController,
                    decoration: InputDecoration(
                      hintText: 'Max',
                      prefixText: r'$ ',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    style: textTheme.bodySmall,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => _onAmountRangeChanged(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Clear filters
          BlocSelector<AllTransactionsBloc, AllTransactionsState, bool>(
            selector: (state) => state.hasActiveFilters,
            builder: (context, hasFilters) {
              if (!hasFilters) return const SizedBox.shrink();
              return Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    _minAmountController.clear();
                    _maxAmountController.clear();
                    context.read<AllTransactionsBloc>().add(
                      const AllTransactionsEvent.filtersCleared(),
                    );
                  },
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Clear all filters'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _onAmountRangeChanged() {
    final minText = _minAmountController.text.trim();
    final maxText = _maxAmountController.text.trim();
    final minDollars = double.tryParse(minText);
    final maxDollars = double.tryParse(maxText);

    context.read<AllTransactionsBloc>().add(
      AllTransactionsEvent.amountRangeChanged(
        minCents: minDollars != null ? (minDollars * 100).round() : null,
        maxCents: maxDollars != null ? (maxDollars * 100).round() : null,
      ),
    );
  }
}

class _FilterSectionLabel extends StatelessWidget {
  const _FilterSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: context.textTheme.labelSmall?.copyWith(
        color: context.colorScheme.onSurface.withValues(alpha: 0.5),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _TypeFilterChips extends StatelessWidget {
  const _TypeFilterChips();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      AllTransactionsBloc,
      AllTransactionsState,
      List<TransactionType>
    >(
      selector: (state) => state.selectedTypes,
      builder: (context, selectedTypes) {
        return Wrap(
          spacing: 6,
          runSpacing: 4,
          children:
              TransactionType.values.map((type) {
                final isSelected = selectedTypes.contains(type);
                return FilterChip(
                  label: Text(_typeLabel(type)),
                  selected: isSelected,
                  onSelected:
                      (_) => context.read<AllTransactionsBloc>().add(
                        AllTransactionsEvent.typeFilterToggled(type: type),
                      ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
        );
      },
    );
  }

  static String _typeLabel(TransactionType type) => switch (type) {
    TransactionType.income => 'Income',
    TransactionType.expense => 'Expense',
    TransactionType.transfer => 'Transfer',
  };
}

class _CategoryFilterChips extends StatelessWidget {
  const _CategoryFilterChips();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      AllTransactionsBloc,
      AllTransactionsState,
      (List<CategoryEntity>, List<int>)
    >(
      selector: (state) => (state.categories, state.selectedCategoryIds),
      builder: (context, data) {
        final (categories, selectedIds) = data;
        if (categories.isEmpty) {
          return Text(
            'Loading...',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          );
        }
        return Wrap(
          spacing: 6,
          runSpacing: 4,
          children:
              categories.map((cat) {
                final isSelected = selectedIds.contains(cat.id);
                return FilterChip(
                  label: Text(cat.name),
                  selected: isSelected,
                  onSelected:
                      (_) => context.read<AllTransactionsBloc>().add(
                        AllTransactionsEvent.categoryFilterToggled(
                          categoryId: cat.id,
                        ),
                      ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
        );
      },
    );
  }
}

class _AccountFilterChips extends StatelessWidget {
  const _AccountFilterChips();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      AllTransactionsBloc,
      AllTransactionsState,
      (List<AccountEntity>, List<int>)
    >(
      selector: (state) => (state.accounts, state.selectedAccountIds),
      builder: (context, data) {
        final (accounts, selectedIds) = data;
        if (accounts.isEmpty) {
          return Text(
            'Loading...',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          );
        }
        return Wrap(
          spacing: 6,
          runSpacing: 4,
          children:
              accounts.where((a) => !a.isArchived).map((acc) {
                final isSelected = selectedIds.contains(acc.id);
                return FilterChip(
                  label: Text(acc.name),
                  selected: isSelected,
                  onSelected:
                      (_) => context.read<AllTransactionsBloc>().add(
                        AllTransactionsEvent.accountFilterToggled(
                          accountId: acc.id,
                        ),
                      ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Transaction List
// ---------------------------------------------------------------------------

class _TransactionList extends StatelessWidget {
  const _TransactionList();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      AllTransactionsBloc,
      AllTransactionsState,
      (List<TransactionWithDetails>, bool, int, int)
    >(
      selector:
          (state) => (
            state.filteredAndSortedTransactions,
            state.isLoading,
            state.year,
            state.month,
          ),
      builder: (context, data) {
        final (transactions, isLoading, year, month) = data;

        if (isLoading && transactions.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return GestureDetector(
          onHorizontalDragEnd:
              (details) => _handleSwipe(context, details, year, month),
          child: AnimatedSwitcher(
            duration: AnimationConstants.defaultDuration,
            child:
                transactions.isEmpty
                    ? _buildEmptyState(context, year, month)
                    : _buildGroupedList(context, transactions, year, month),
          ),
        );
      },
    );
  }

  void _handleSwipe(
    BuildContext context,
    DragEndDetails details,
    int year,
    int month,
  ) {
    final velocity = details.velocity.pixelsPerSecond.dx;
    if (velocity < -300) {
      final (ny, nm) = _nextMonth(year, month);
      context.read<AllTransactionsBloc>().add(
        AllTransactionsEvent.monthChanged(year: ny, month: nm),
      );
    } else if (velocity > 300) {
      final (py, pm) = _prevMonth(year, month);
      context.read<AllTransactionsBloc>().add(
        AllTransactionsEvent.monthChanged(year: py, month: pm),
      );
    }
  }

  Widget _buildEmptyState(BuildContext context, int year, int month) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    return Center(
      key: ValueKey('empty-$year-$month'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: colorScheme.onSurface.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 12),
          Text(
            'No transactions',
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedList(
    BuildContext context,
    List<TransactionWithDetails> transactions,
    int year,
    int month,
  ) {
    final groups = TransactionDateGroup.groupByDate(transactions);
    final items = <_ListItem>[];
    for (final entry in groups.entries) {
      items.add(_ListItem.header(entry.key));
      for (final txn in entry.value) {
        items.add(_ListItem.transaction(txn));
      }
    }

    return RefreshIndicator(
      key: ValueKey('list-$year-$month'),
      onRefresh: () async {
        context.read<AllTransactionsBloc>().add(
          const AllTransactionsEvent.refreshRequested(),
        );
        await context.read<AllTransactionsBloc>().stream.firstWhere(
          (s) => !s.isLoading,
        );
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return switch (item) {
            _HeaderItem(:final label) => _DateHeader(label: label),
            _TransactionItem(:final transaction) => _DenseTransactionRow(
              transaction: transaction,
            ),
          };
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// List Item Types
// ---------------------------------------------------------------------------

sealed class _ListItem {
  const _ListItem();
  const factory _ListItem.header(String label) = _HeaderItem;
  const factory _ListItem.transaction(TransactionWithDetails transaction) =
      _TransactionItem;
}

class _HeaderItem extends _ListItem {
  const _HeaderItem(this.label);
  final String label;
}

class _TransactionItem extends _ListItem {
  const _TransactionItem(this.transaction);
  final TransactionWithDetails transaction;
}

// ---------------------------------------------------------------------------
// Dense Row Widgets
// ---------------------------------------------------------------------------

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Text(
        label,
        style: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface.withValues(alpha: 0.45),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _DenseTransactionRow extends StatelessWidget {
  const _DenseTransactionRow({required this.transaction});

  final TransactionWithDetails transaction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final txn = transaction.transaction;
    final isIncome = txn.type == TransactionType.income;
    final categoryColor = _parseColor(transaction.categoryColorHex);
    final amountColor =
        isIncome ? const Color(0xFF4CAF50) : const Color(0xFFF44336);

    return InkWell(
      onTap: () {
        // TODO: navigate to transaction detail
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Color dot
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: categoryColor,
              ),
            ),
            const SizedBox(width: 10),
            // Title
            Expanded(
              flex: 3,
              child: Text(
                txn.title,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // Category
            Expanded(
              flex: 2,
              child: Text(
                transaction.categoryName,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.55),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // Amount
            Text(
              '${isIncome ? '+' : '-'}${formatCurrency(txn.amountCents)}',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: amountColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

(int, int) _prevMonth(int year, int month) {
  if (month == 1) return (year - 1, 12);
  return (year, month - 1);
}

(int, int) _nextMonth(int year, int month) {
  if (month == 12) return (year + 1, 1);
  return (year, month + 1);
}

String _monthLabel(int year, int month) {
  const months = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  if (month < 1 || month > 12) return '';
  return '${months[month]} $year';
}

Color _parseColor(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}
