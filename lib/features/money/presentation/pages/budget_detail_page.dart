import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:track/core/extensions/context_extensions.dart';

@RoutePage()
class BudgetDetailPage extends StatelessWidget {
  const BudgetDetailPage({
    @PathParam('id') required this.budgetId,
    super.key,
  });

  final String budgetId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Budget Detail')),
      body: Center(
        child: Text(
          'Budget: $budgetId',
          style: context.textTheme.titleMedium,
        ),
      ),
    );
  }
}
