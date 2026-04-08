import 'package:flutter/material.dart';
import 'package:track/core/extensions/context_extensions.dart';
import 'package:track/features/money/domain/entities/transaction_with_details.dart';
import 'package:track/features/money/presentation/widgets/transaction_list_item.dart';

class TransactionDateGroup extends StatelessWidget {
  const TransactionDateGroup({
    required this.dateLabel,
    required this.transactions,
    super.key,
  });

  final String dateLabel;
  final List<TransactionWithDetails> transactions;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
          child: Text(
            dateLabel,
            style: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
        ...transactions.map(
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: TransactionListItem(transaction: t),
          ),
        ),
      ],
    );
  }

  /// Groups a flat list of transactions by date and returns
  /// a map of date label → transactions.
  static Map<String, List<TransactionWithDetails>> groupByDate(
    List<TransactionWithDetails> transactions,
  ) {
    final groups = <String, List<TransactionWithDetails>>{};
    for (final t in transactions) {
      final dateStr = t.transaction.transactionDate;
      final label = _formatDateLabel(dateStr);
      groups.putIfAbsent(label, () => []).add(t);
    }
    return groups;
  }

  static String _formatDateLabel(String isoDate) {
    final now = DateTime.now();
    final today =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final yesterdayStr =
        '${yesterday.year.toString().padLeft(4, '0')}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

    if (isoDate == today) return 'Today';
    if (isoDate == yesterdayStr) return 'Yesterday';

    final parts = isoDate.split('-');
    if (parts.length != 3) return isoDate;

    final month = int.tryParse(parts[1]) ?? 1;
    final day = int.tryParse(parts[2]) ?? 1;
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
    return '${months[month]} $day';
  }
}
