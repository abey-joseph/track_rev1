import 'package:flutter/material.dart';
import 'package:track/core/extensions/context_extensions.dart';
import 'package:track/features/money/domain/entities/money_summary.dart';
import 'package:track/features/money/presentation/utils/currency_formatter.dart';
import 'package:track/features/money/presentation/utils/money_icon_resolver.dart';

class CategoryBreakdownWidget extends StatelessWidget {
  const CategoryBreakdownWidget({
    required this.categories,
    required this.totalExpenseCents,
    super.key,
  });

  final List<CategorySpending> categories;
  final int totalExpenseCents;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

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
              'Top Spending',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 14),
            ...categories.map(
              (cat) => _CategoryBar(
                category: cat,
                maxAmount: totalExpenseCents,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({required this.category, required this.maxAmount});

  final CategorySpending category;
  final int maxAmount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final color = _parseColor(category.colorHex);
    final fraction = maxAmount > 0 ? category.amountCents / maxAmount : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15),
                ),
                child: Icon(
                  resolveMoneyIcon(category.iconName),
                  size: 14,
                  color: color,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  category.name,
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                formatCurrency(category.amountCents),
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

Color _parseColor(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}
