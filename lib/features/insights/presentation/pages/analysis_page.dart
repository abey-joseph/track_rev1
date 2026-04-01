import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:track/core/extensions/context_extensions.dart';

@RoutePage()
class AnalysisPage extends StatelessWidget {
  const AnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analysis')),
      body: Center(
        child: Text(
          'Custom analysis builder',
          style: context.textTheme.titleMedium,
        ),
      ),
    );
  }
}
