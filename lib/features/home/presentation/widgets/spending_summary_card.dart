import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:track/core/constants/animation_constants.dart';

class SpendingSummaryCard extends StatelessWidget {
  const SpendingSummaryCard({
    required this.todaySpend,
    required this.weekSpend,
    required this.topCategories,
    required this.dailySpends,
    required this.onSeeAll,
    super.key,
  });

  final double todaySpend;
  final double weekSpend;
  final List<CategorySpend> topCategories;

  /// Last 7 days of spending for the sparkline.
  final List<double> dailySpends;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spending',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: onSeeAll,
                  child: Text(
                    'See All',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Amounts row
            Row(
              children: [
                _AmountColumn(
                  label: 'Today',
                  amount: todaySpend,
                  textTheme: textTheme,
                  colorScheme: colorScheme,
                ),
                const SizedBox(width: 32),
                _AmountColumn(
                  label: 'This Week',
                  amount: weekSpend,
                  textTheme: textTheme,
                  colorScheme: colorScheme,
                ),
                const Spacer(),
                // Sparkline
                SizedBox(
                  width: 80,
                  height: 40,
                  child: _Sparkline(
                    data: dailySpends,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Top categories
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children:
                  topCategories.map((category) {
                    return Chip(
                      avatar: Icon(
                        category.icon,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      label: Text(
                        '\$${category.amount.toStringAsFixed(0)}',
                        style: textTheme.labelSmall,
                      ),
                      labelPadding: const EdgeInsets.only(left: 2),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: BorderSide.none,
                      backgroundColor: colorScheme.surfaceContainerHigh,
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountColumn extends StatelessWidget {
  const _AmountColumn({
    required this.label,
    required this.amount,
    required this.textTheme,
    required this.colorScheme,
  });

  final String label;
  final double amount;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _Sparkline extends StatelessWidget {
  const _Sparkline({required this.data, required this.color});

  final List<double> data;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final spots = List.generate(
      data.length,
      (i) => FlSpot(i.toDouble(), data[i]),
    );

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              color: color.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
      duration: AnimationConstants.slow,
      curve: AnimationConstants.enterCurve,
    );
  }
}

class CategorySpend {
  const CategorySpend({
    required this.name,
    required this.icon,
    required this.amount,
  });

  final String name;
  final IconData icon;
  final double amount;
}
