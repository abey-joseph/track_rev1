import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:track/core/extensions/context_extensions.dart';

@RoutePage()
class HabitDetailPage extends StatelessWidget {
  const HabitDetailPage({@PathParam('id') required this.habitId, super.key});

  final String habitId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Habit Detail')),
      body: Center(
        child: Text(
          'Habit detail for: $habitId',
          style: context.textTheme.titleMedium,
        ),
      ),
    );
  }
}
