import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:track/core/extensions/context_extensions.dart';

@RoutePage()
class HabitCreateEditPage extends StatelessWidget {
  const HabitCreateEditPage({super.key, this.habitId});

  final String? habitId;

  @override
  Widget build(BuildContext context) {
    final isEditing = habitId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Habit' : 'New Habit'),
      ),
      body: Center(
        child: Text(
          isEditing ? 'Edit habit: $habitId' : 'Create new habit',
          style: context.textTheme.titleMedium,
        ),
      ),
    );
  }
}
