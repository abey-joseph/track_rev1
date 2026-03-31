import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:track/core/extensions/context_extensions.dart';

@RoutePage()
class HabitStatsPage extends StatelessWidget {
  const HabitStatsPage({@PathParam('id') required this.habitId, super.key});

  final String habitId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Habit Statistics')),
      body: Center(
        child: Text(
          'Statistics for habit: $habitId',
          style: context.textTheme.titleMedium,
        ),
      ),
    );
  }
}
