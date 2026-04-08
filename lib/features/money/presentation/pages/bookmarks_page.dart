import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:track/core/extensions/context_extensions.dart';
import 'package:track/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:track/features/auth/presentation/bloc/auth_state.dart';
import 'package:track/features/money/domain/entities/transaction_entity.dart';
import 'package:track/features/money/domain/entities/transaction_with_details.dart';
import 'package:track/features/money/presentation/bloc/bookmarks/bookmarks_bloc.dart';
import 'package:track/features/money/presentation/bloc/bookmarks/bookmarks_event.dart';
import 'package:track/features/money/presentation/bloc/bookmarks/bookmarks_state.dart';
import 'package:track/features/money/presentation/utils/currency_formatter.dart';
import 'package:track/injection.dart';

@RoutePage()
class BookmarksPage extends StatelessWidget {
  const BookmarksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is Authenticated ? authState.user.uid : '';

    return BlocProvider(
      create:
          (_) =>
              getIt<BookmarksBloc>()
                ..add(BookmarksEvent.loadRequested(userId: userId)),
      child: const _BookmarksView(),
    );
  }
}

class _BookmarksView extends StatelessWidget {
  const _BookmarksView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarks'),
        actions: const [_SortMenuButton()],
      ),
      body: const _BookmarksList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Sort Menu
// ---------------------------------------------------------------------------

class _SortMenuButton extends StatelessWidget {
  const _SortMenuButton();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      BookmarksBloc,
      BookmarksState,
      (BookmarkSortField, bool)
    >(
      selector: (state) => (state.sortField, state.sortAscending),
      builder: (context, data) {
        final (currentField, currentAsc) = data;
        return PopupMenuButton<(BookmarkSortField, bool)>(
          icon: const Icon(Icons.sort),
          onSelected: (value) {
            context.read<BookmarksBloc>().add(
              BookmarksEvent.sortChanged(
                sortField: value.$1,
                ascending: value.$2,
              ),
            );
          },
          itemBuilder:
              (_) => [
                _sortItem(
                  'Date (newest)',
                  BookmarkSortField.date,
                  false,
                  currentField,
                  currentAsc,
                ),
                _sortItem(
                  'Date (oldest)',
                  BookmarkSortField.date,
                  true,
                  currentField,
                  currentAsc,
                ),
                const PopupMenuDivider(),
                _sortItem(
                  'Amount (highest)',
                  BookmarkSortField.amount,
                  false,
                  currentField,
                  currentAsc,
                ),
                _sortItem(
                  'Amount (lowest)',
                  BookmarkSortField.amount,
                  true,
                  currentField,
                  currentAsc,
                ),
              ],
        );
      },
    );
  }

  PopupMenuItem<(BookmarkSortField, bool)> _sortItem(
    String label,
    BookmarkSortField field,
    bool asc,
    BookmarkSortField currentField,
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
// Bookmarks List
// ---------------------------------------------------------------------------

class _BookmarksList extends StatelessWidget {
  const _BookmarksList();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      BookmarksBloc,
      BookmarksState,
      (Map<String, List<TransactionWithDetails>>, bool)
    >(
      selector: (state) => (state.transactionsByMonth, state.isLoading),
      builder: (context, data) {
        final (groups, isLoading) = data;

        if (isLoading && groups.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (groups.isEmpty) {
          return _buildEmptyState(context);
        }

        final items = <_ListItem>[];
        for (final entry in groups.entries) {
          items.add(_ListItem.header(_yearMonthToLabel(entry.key)));
          for (final txn in entry.value) {
            items.add(_ListItem.transaction(txn));
          }
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return switch (item) {
              _HeaderItem(:final label) => _MonthHeader(label: label),
              _TransactionItem(:final transaction) => _SwipeableBookmarkRow(
                transaction: transaction,
              ),
            };
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bookmark_border_rounded,
            size: 48,
            color: colorScheme.onSurface.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 12),
          Text(
            'No bookmarks yet',
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Swipe left on a transaction to bookmark it',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.35),
            ),
          ),
        ],
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
// Month Header
// ---------------------------------------------------------------------------

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Text(
        label,
        style: context.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: context.colorScheme.onSurface.withValues(alpha: 0.45),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Swipeable Row (Bookmarks Page — swipe to remove)
// ---------------------------------------------------------------------------

class _SwipeableBookmarkRow extends StatefulWidget {
  const _SwipeableBookmarkRow({required this.transaction});

  final TransactionWithDetails transaction;

  @override
  State<_SwipeableBookmarkRow> createState() => _SwipeableBookmarkRowState();
}

class _SwipeableBookmarkRowState extends State<_SwipeableBookmarkRow> {
  static const double _maxReveal = 168; // 3 buttons × 56px
  double _offset = 0;
  bool _isDragging = false;

  void _close() => setState(() {
    _offset = 0;
    _isDragging = false;
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return GestureDetector(
      onHorizontalDragStart: (_) => setState(() => _isDragging = true),
      onHorizontalDragUpdate: (d) {
        setState(() {
          _offset = (_offset + d.delta.dx).clamp(-_maxReveal, 0);
        });
      },
      onHorizontalDragEnd: (d) {
        final vel = d.primaryVelocity ?? 0;
        final open = _offset < -_maxReveal / 2 || vel < -300;
        setState(() {
          _isDragging = false;
          _offset = open ? -_maxReveal : 0;
        });
      },
      onTap: () {
        if (_offset != 0) {
          _close();
        } else {
          setState(() {
            _isDragging = false;
            _offset = -_maxReveal;
          });
        }
      },
      child: Stack(
        children: [
          // Action buttons (behind the row)
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: _maxReveal,
                child: Row(
                  children: [
                    _ActionButton(
                      icon: Icons.bookmark_remove_rounded,
                      label: 'Remove',
                      color: colorScheme.primary,
                      onTap: () {
                        context.read<BookmarksBloc>().add(
                          BookmarksEvent.removeRequested(
                            transactionId: widget.transaction.transaction.id,
                          ),
                        );
                        _close();
                      },
                    ),
                    _ActionButton(
                      icon: Icons.copy_rounded,
                      label: 'Copy',
                      color: Colors.green,
                      onTap: _close,
                    ),
                    _ActionButton(
                      icon: Icons.delete_rounded,
                      label: 'Delete',
                      color: Colors.red,
                      onTap: _close,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Main row (slides left)
          AnimatedContainer(
            duration:
                _isDragging ? Duration.zero : const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(_offset, 0, 0),
            color: colorScheme.surface,
            child: _DenseTransactionRow(transaction: widget.transaction),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dense Row (mirrors AllTransactionsPage._DenseTransactionRow)
// ---------------------------------------------------------------------------

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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: categoryColor,
            ),
          ),
          const SizedBox(width: 10),
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
    );
  }
}

// ---------------------------------------------------------------------------
// Shared Action Button
// ---------------------------------------------------------------------------

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: ColoredBox(
          color: color,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _yearMonthToLabel(String yearMonth) {
  final parts = yearMonth.split('-');
  if (parts.length < 2) return yearMonth;
  final year = int.tryParse(parts[0]) ?? 0;
  final month = int.tryParse(parts[1]) ?? 1;
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
  if (month < 1 || month > 12) return yearMonth;
  return '${months[month]} $year';
}

Color _parseColor(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}
