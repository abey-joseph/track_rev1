import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:track/core/extensions/context_extensions.dart';

@RoutePage()
class AccountDetailPage extends StatelessWidget {
  const AccountDetailPage({
    @PathParam('id') required this.accountId,
    super.key,
  });

  final String accountId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account Detail')),
      body: Center(
        child: Text(
          'Account: $accountId',
          style: context.textTheme.titleMedium,
        ),
      ),
    );
  }
}
