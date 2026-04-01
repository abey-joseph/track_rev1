import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:track/core/constants/animation_constants.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/core/extensions/context_extensions.dart';
import 'package:track/core/router/app_router.gr.dart';
import 'package:track/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:track/features/auth/presentation/bloc/auth_state.dart';
import 'package:track/features/habits/domain/entities/habit_with_details.dart';
import 'package:track/features/habits/presentation/bloc/habits_bloc.dart';
import 'package:track/features/habits/presentation/bloc/habits_event.dart';
import 'package:track/features/habits/presentation/bloc/habits_state.dart';
import 'package:track/features/habits/presentation/widgets/habit_card.dart';
import 'package:track/injection.dart';

@RoutePage()
class HabitsPage extends StatelessWidget {
  const HabitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is Authenticated ? authState.user.uid : '';

    return BlocProvider(
      create: (_) =>
          getIt<HabitsBloc>()..add(HabitsEvent.loadRequested(userId: userId)),
      child: const _HabitsView(),
    );
  }
}

class _HabitsView extends StatelessWidget {
  const _HabitsView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: BlocBuilder<HabitsBloc, HabitsState>(
        builder: (context, state) => switch (state) {
          HabitsInitial() || HabitsLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
          HabitsLoaded(:final habits) => habits.isEmpty
              ? _buildEmptyState(colorScheme, textTheme)
              : _buildHabitsList(context, habits),
          HabitsError(:final failure) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: colorScheme.error.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    switch (failure) {
                      ServerFailure(:final message) => message,
                      CacheFailure(:final message) => message,
                      NetworkFailure(:final message) => message,
                      AuthFailure(:final message) => message,
                      UnexpectedFailure(:final message) => message,
                    },
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context
                        .read<HabitsBloc>()
                        .add(const HabitsEvent.refreshRequested()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
        },
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Your habits will appear here',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Track daily habits and build streaks',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitsList(
    BuildContext context,
    List<HabitWithDetails> habits,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: habits.length,
      itemBuilder: (context, index) {
        return _AnimatedHabitCard(
          habitWithDetails: habits[index],
          index: index,
          onTap: () => context.router.push(
            HabitDetailRoute(habitId: habits[index].habit.id.toString()),
          ),
        );
      },
    );
  }
}

class _AnimatedHabitCard extends StatefulWidget {
  const _AnimatedHabitCard({
    required this.habitWithDetails,
    required this.index,
    required this.onTap,
  });

  final HabitWithDetails habitWithDetails;
  final int index;
  final VoidCallback onTap;

  @override
  State<_AnimatedHabitCard> createState() => _AnimatedHabitCardState();
}

class _AnimatedHabitCardState extends State<_AnimatedHabitCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AnimationConstants.defaultDuration,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: AnimationConstants.enterCurve,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AnimationConstants.enterCurve,
      ),
    );

    Future.delayed(
      Duration(
        milliseconds:
            AnimationConstants.staggerDelay.inMilliseconds * widget.index,
      ),
      () {
        if (mounted) _controller.forward();
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: HabitCard(
            habitWithDetails: widget.habitWithDetails,
            onTap: widget.onTap,
          ),
        ),
      ),
    );
  }
}
