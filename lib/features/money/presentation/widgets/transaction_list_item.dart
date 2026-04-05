import 'package:flutter/material.dart';
import 'package:track/core/extensions/context_extensions.dart';
import 'package:track/features/money/domain/entities/transaction_entity.dart';
import 'package:track/features/money/domain/entities/transaction_with_details.dart';
import 'package:track/features/money/presentation/utils/currency_formatter.dart';
import 'package:track/features/money/presentation/utils/money_icon_resolver.dart';

class TransactionListItem extends StatelessWidget {
  const TransactionListItem({
    super.key,
    required this.transaction,
    this.onTap,
  });

  final TransactionWithDetails transaction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final txn = transaction.transaction;
    final isIncome = txn.type == TransactionType.income;
    final color = _parseColor(transaction.categoryColorHex);
    final amountColor =
        isIncome ? const Color(0xFF4CAF50) : const Color(0xFFF44336);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Category icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
                child: Icon(
                  resolveMoneyIcon(transaction.categoryIconName),
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              // Title and category
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      txn.title,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${transaction.categoryName} · ${transaction.accountName}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Amount
              Text(
                '${isIncome ? '+' : '-'}${formatCurrency(txn.amountCents)}',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: amountColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _parseColor(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}
