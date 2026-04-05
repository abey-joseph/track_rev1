import 'package:flutter/material.dart';
import 'package:track/core/extensions/context_extensions.dart';
import 'package:track/features/money/domain/entities/money_summary.dart';
import 'package:track/features/money/presentation/utils/currency_formatter.dart';

class MoneyOverviewCard extends StatelessWidget {
  const MoneyOverviewCard({super.key, required this.summary});

  final MoneySummary summary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final netCents = summary.totalIncomeCents - summary.totalExpenseCents;
    final isPositive = netCents >= 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This Month',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            // Net balance — large prominent display
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isPositive
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFF44336))
                        .withValues(alpha: 0.12),
                  ),
                  child: Icon(
                    isPositive
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    size: 20,
                    color: isPositive
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFF44336),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Net Balance',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    Text(
                      formatCurrency(netCents),
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isPositive
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFF44336),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Income and Expense side by side
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    icon: Icons.arrow_downward_rounded,
                    iconColor: const Color(0xFF4CAF50),
                    label: 'Income',
                    amount: formatCurrency(summary.totalIncomeCents),
                    amountColor: const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    icon: Icons.arrow_upward_rounded,
                    iconColor: const Color(0xFFF44336),
                    label: 'Expenses',
                    amount: formatCurrency(summary.totalExpenseCents),
                    amountColor: const Color(0xFFF44336),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.amount,
    required this.amountColor,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String amount;
  final Color amountColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  amount,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: amountColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
