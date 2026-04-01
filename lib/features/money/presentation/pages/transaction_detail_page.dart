import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:track/core/extensions/context_extensions.dart';

@RoutePage()
class TransactionDetailPage extends StatelessWidget {
  const TransactionDetailPage({
    @PathParam('id') required this.transactionId,
    super.key,
  });

  final String transactionId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction Detail')),
      body: Center(
        child: Text(
          'Transaction: $transactionId',
          style: context.textTheme.titleMedium,
        ),
      ),
    );
  }
}
