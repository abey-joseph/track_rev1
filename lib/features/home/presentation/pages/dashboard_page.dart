import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:track/core/extensions/context_extensions.dart';
import 'package:track/core/router/app_router.gr.dart';
import 'package:track/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:track/features/auth/presentation/bloc/auth_state.dart';
import 'package:track/features/habits/domain/entities/habit_with_details.dart';
import 'package:track/features/habits/presentation/bloc/habits_bloc.dart';
import 'package:track/features/habits/presentation/bloc/habits_event.dart';
import 'package:track/features/habits/presentation/bloc/habits_state.dart';
import 'package:track/features/habits/presentation/utils/habit_icon_resolver.dart';
import 'package:track/features/home/presentation/widgets/ai_insight_card.dart';
import 'package:track/features/home/presentation/widgets/recent_activity_feed.dart';
import 'package:track/features/home/presentation/widgets/spending_summary_card.dart';
import 'package:track/features/home/presentation/widgets/streak_score_card.dart';
import 'package:track/features/habits/presentation/widgets/measurable_log_sheet.dart';
import 'package:track/features/home/presentation/widgets/today_habits_section.dart';
import 'package:intl/intl.dart';
import 'package:track/injection.dart';

@RoutePage()
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is Authenticated ? authState.user.uid : '';

    return BlocProvider(
      create:
          (_) =>
              getIt<HabitsBloc>()
                ..add(HabitsEvent.loadRequested(userId: userId)),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMM d').format(now);
    final greeting = _greeting(now.hour);

    final todayIso =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              dateStr,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(
                Icons.person_outline,
                size: 18,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            onPressed: () => context.router.push(const SettingsRoute()),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          // Streak & score card
          BlocBuilder<HabitsBloc, HabitsState>(
            builder: (context, state) {
              if (state is HabitsLoaded) {
                final todayWeekday = now.weekday;
                final todayHabits =
                    state.habits
                        .where(
                          (h) => h.habit.frequencyDays.contains(todayWeekday),
                        )
                        .toList();
                final completed =
                    todayHabits
                        .where(
                          (h) => h.recentLogs.any(
                            (l) =>
                                l.loggedDate == todayIso &&
                                l.value >= h.habit.targetValue,
                          ),
                        )
                        .length;
                final bestStreak = state.habits.fold<int>(
                  0,
                  (max, h) =>
                      h.streak.currentStreak > max
                          ? h.streak.currentStreak
                          : max,
                );
                return StreakScoreCard(
                  currentStreak: bestStreak,
                  habitsCompleted: completed,
                  habitsTotal: todayHabits.length,
                );
              }
              return const StreakScoreCard(
                currentStreak: 0,
                habitsCompleted: 0,
                habitsTotal: 0,
              );
            },
          ),
          const SizedBox(height: 20),

          // Today's habits
          BlocBuilder<HabitsBloc, HabitsState>(
            builder: (context, state) {
              final List<HabitItem> habitItems;
              if (state is HabitsLoaded) {
                final todayWeekday = now.weekday;
                habitItems =
                    state.habits
                        .where(
                          (h) => h.habit.frequencyDays.contains(todayWeekday),
                        )
                        .map((h) {
                          final isCompleted = h.recentLogs.any(
                            (l) =>
                                l.loggedDate == todayIso &&
                                l.value >= h.habit.targetValue,
                          );
                          return HabitItem(
                            id: h.habit.id.toString(),
                            name: h.habit.name,
                            icon: resolveHabitIcon(h.habit.iconName),
                            color: _parseColor(h.habit.colorHex),
                            isCompleted: isCompleted,
                            subtitle: h.habit.targetUnit,
                          );
                        })
                        .toList();
              } else {
                habitItems = [];
              }

              // Build a lookup for measurable habit info
              final habitMap = state is HabitsLoaded
                  ? {
                      for (final h in state.habits)
                        h.habit.id.toString(): h,
                    }
                  : <String, HabitWithDetails>{};

              return TodayHabitsSection(
                habits: habitItems,
                onToggle: (id) async {
                  final h = habitMap[id];
                  if (h != null && h.habit.targetValue > 1.0) {
                    // Measurable habit: show bottom sheet
                    final todayLog =
                        h.recentLogs
                            .where((l) => l.loggedDate == todayIso)
                            .firstOrNull;
                    final result =
                        await showModalBottomSheet<MeasurableLogResult>(
                          context: context,
                          isScrollControlled: true,
                          builder:
                              (_) => MeasurableLogSheet(
                                habitName: h.habit.name,
                                targetValue: h.habit.targetValue,
                                targetUnit: h.habit.targetUnit,
                                targetType: h.habit.targetType,
                                currentValue: todayLog?.value,
                              ),
                        );
                    if (result == null || !context.mounted) return;
                    if (result.delete) {
                      context.read<HabitsBloc>().add(
                        HabitsEvent.deleteLog(
                          habitId: int.parse(id),
                          date: todayIso,
                        ),
                      );
                    } else if (result.value != null) {
                      context.read<HabitsBloc>().add(
                        HabitsEvent.logValue(
                          habitId: int.parse(id),
                          date: todayIso,
                          value: result.value!,
                        ),
                      );
                    }
                  } else {
                    // Yes/No habit: existing toggle
                    context.read<HabitsBloc>().add(
                      HabitsEvent.toggleLog(
                        habitId: int.parse(id),
                        date: todayIso,
                      ),
                    );
                  }
                },
                onSeeAll: () {
                  AutoTabsRouter.of(context).setActiveIndex(1);
                },
              );
            },
          ),
          const SizedBox(height: 20),

          // Spending summary
          SpendingSummaryCard(
            todaySpend: 45.2,
            weekSpend: 312,
            topCategories: const [
              CategorySpend(
                name: 'Food',
                icon: Icons.restaurant_rounded,
                amount: 23,
              ),
              CategorySpend(
                name: 'Transport',
                icon: Icons.directions_car_rounded,
                amount: 12,
              ),
              CategorySpend(
                name: 'Coffee',
                icon: Icons.coffee_rounded,
                amount: 10.20,
              ),
            ],
            dailySpends: const [32, 28, 45, 52, 38, 41, 45.20],
            onSeeAll: () {
              AutoTabsRouter.of(context).setActiveIndex(2);
            },
          ),
          const SizedBox(height: 20),

          // AI insight
          AiInsightCard(
            insightText:
                'Your spending drops 30% on days you meditate. '
                "You've meditated 5 out of the last 7 days — "
                'keep it up to stay on track with your budget this month.',
            onTap: () {
              AutoTabsRouter.of(context).setActiveIndex(3);
            },
          ),
          const SizedBox(height: 20),

          // Recent activity
          const RecentActivityFeed(
            activities: [
              ActivityItem(
                time: '2:30 PM',
                title: 'Meditate',
                type: ActivityType.habitCompletion,
              ),
              ActivityItem(
                time: '1:15 PM',
                title: 'Lunch',
                type: ActivityType.expense,
                subtitle: r'-$12.00',
              ),
              ActivityItem(
                time: '9:00 AM',
                title: 'Exercise',
                type: ActivityType.habitCompletion,
              ),
              ActivityItem(
                time: '8:30 AM',
                title: 'Coffee',
                type: ActivityType.expense,
                subtitle: r'-$5.50',
              ),
              ActivityItem(
                time: '7:00 AM',
                title: 'Read',
                type: ActivityType.habitCompletion,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _greeting(int hour) {
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Color _parseColor(String hex) {
    final buffer = StringBuffer();
    final cleaned = hex.startsWith('#') ? hex.substring(1) : hex;
    if (cleaned.length == 6) buffer.write('FF');
    buffer.write(cleaned);
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
