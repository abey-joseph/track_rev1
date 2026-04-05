import 'package:flutter/material.dart';
import 'package:track/features/money/domain/entities/transaction_entity.dart';

class TransactionTypeToggle extends StatelessWidget {
  const TransactionTypeToggle({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final TransactionType selected;
  final ValueChanged<TransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<TransactionType>(
      segments: const [
        ButtonSegment(
          value: TransactionType.expense,
          label: Text('Expense'),
          icon: Icon(Icons.arrow_upward_rounded),
        ),
        ButtonSegment(
          value: TransactionType.income,
          label: Text('Income'),
          icon: Icon(Icons.arrow_downward_rounded),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (s) => onChanged(s.first),
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
