import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:track/core/extensions/context_extensions.dart';

@RoutePage()
class InsightDetailPage extends StatelessWidget {
  const InsightDetailPage({
    @PathParam('id') required this.insightId,
    super.key,
  });

  final String insightId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Insight Detail')),
      body: Center(
        child: Text(
          'Insight: $insightId',
          style: context.textTheme.titleMedium,
        ),
      ),
    );
  }
}
