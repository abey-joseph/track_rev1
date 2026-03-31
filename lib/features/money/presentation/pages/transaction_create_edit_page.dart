import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:track/core/extensions/context_extensions.dart';

@RoutePage()
class TransactionCreateEditPage extends StatelessWidget {
  const TransactionCreateEditPage({super.key, this.transactionId});

  final String? transactionId;

  @override
  Widget build(BuildContext context) {
    final isEditing = transactionId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Transaction' : 'New Transaction'),
      ),
      body: Center(
        child: Text(
          isEditing
              ? 'Edit transaction: $transactionId'
              : 'Create new transaction',
          style: context.textTheme.titleMedium,
        ),
      ),
    );
  }
}
