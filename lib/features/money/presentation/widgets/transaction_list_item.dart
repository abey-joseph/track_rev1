import 'package:flutter/material.dart';
import 'package:track/core/extensions/context_extensions.dart';
import 'package:track/features/money/domain/entities/transaction_entity.dart';
import 'package:track/features/money/domain/entities/transaction_with_details.dart';
import 'package:track/features/money/presentation/utils/currency_formatter.dart';
import 'package:track/features/money/presentation/utils/money_icon_resolver.dart';

class TransactionListItem extends StatelessWidget {
  const TransactionListItem({
    required this.transaction,
    super.key,
    this.onTap,
  });

  final TransactionWithDetails transaction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final txn = transaction.transaction;
    final isTransfer = txn.type == TransactionType.transfer;
    final isIncome = txn.type == TransactionType.income;

    final amountColor = switch (txn.type) {
      TransactionType.income => const Color(0xFF4CAF50),
      TransactionType.transfer => const Color(0xFF2196F3),
      _ => const Color(0xFFF44336),
    };

    // For transfers: blue circle with swap icon; otherwise use category color/icon
    final iconColor =
        isTransfer
            ? const Color(0xFF2196F3)
            : _parseColor(transaction.categoryColorHex);
    final icon =
        isTransfer
            ? Icons.swap_horiz_rounded
            : resolveMoneyIcon(transaction.categoryIconName);

    // Subtitle: for transfers show "From X → To Y"; otherwise "Category · Account"
    final subtitle =
        isTransfer && transaction.toAccountName != null
            ? '${transaction.accountName} → ${transaction.toAccountName}'
            : '${transaction.categoryName} · ${transaction.accountName}';

    // Display the original entered amount
    final displayCents =
        txn.originalAmountCents > 0 ? txn.originalAmountCents : txn.amountCents;
    final amountStr = formatCurrency(
      displayCents,
      symbol: transaction.currencySymbol,
    );
    final prefix = isTransfer ? '' : (isIncome ? '+' : '-');

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
              // Category / transfer icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              // Title and subtitle
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
                      subtitle,
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
                '$prefix$amountStr',
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
