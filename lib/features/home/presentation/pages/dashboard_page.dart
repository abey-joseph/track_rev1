import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:track/core/extensions/context_extensions.dart';
import 'package:track/core/router/app_router.gr.dart';
import 'package:track/features/home/presentation/widgets/ai_insight_card.dart';
import 'package:track/features/home/presentation/widgets/recent_activity_feed.dart';
import 'package:track/features/home/presentation/widgets/spending_summary_card.dart';
import 'package:track/features/home/presentation/widgets/streak_score_card.dart';
import 'package:track/features/home/presentation/widgets/today_habits_section.dart';

@RoutePage()
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMM d').format(now);
    final greeting = _greeting(now.hour);

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
          const StreakScoreCard(
            currentStreak: 12,
            habitsCompleted: 5,
            habitsTotal: 7,
          ),
          const SizedBox(height: 20),

          // Today's habits
          TodayHabitsSection(
            habits: _mockHabits,
            onToggle: (_) {},
            onSeeAll: () {
              AutoTabsRouter.of(context).setActiveIndex(1);
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
}

// Mock data for dashboard display
const _mockHabits = [
  HabitItem(
    id: '1',
    name: 'Meditate',
    icon: Icons.self_improvement_rounded,
    color: Color(0xFF31473A),
    isCompleted: true,
    subtitle: '10 min',
  ),
  HabitItem(
    id: '2',
    name: 'Read',
    icon: Icons.menu_book_rounded,
    color: Color(0xFF7C8363),
    isCompleted: true,
    subtitle: '30 min',
  ),
  HabitItem(
    id: '3',
    name: 'Exercise',
    icon: Icons.fitness_center_rounded,
    color: Color(0xFF4CAF50),
    isCompleted: true,
  ),
  HabitItem(
    id: '4',
    name: 'Journal',
    icon: Icons.edit_note_rounded,
    color: Color(0xFFFF9800),
    isCompleted: true,
  ),
  HabitItem(
    id: '5',
    name: 'Drink Water',
    icon: Icons.water_drop_rounded,
    color: Color(0xFF2196F3),
    isCompleted: true,
  ),
  HabitItem(
    id: '6',
    name: 'No Social Media',
    icon: Icons.phone_disabled_rounded,
    color: Color(0xFFE91E63),
  ),
  HabitItem(
    id: '7',
    name: 'Sleep by 11 PM',
    icon: Icons.bedtime_rounded,
    color: Color(0xFF9C27B0),
  ),
];
