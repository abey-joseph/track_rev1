import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:track/core/router/app_router.gr.dart';
import 'package:track/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:track/features/auth/presentation/bloc/auth_state.dart';
import 'package:track/features/habits/presentation/bloc/habits_bloc.dart';
import 'package:track/features/habits/presentation/bloc/habits_event.dart';
import 'package:track/features/money/presentation/bloc/money_bloc.dart';
import 'package:track/features/money/presentation/bloc/money_event.dart';
import 'package:track/injection.dart';

@RoutePage()
class AppShellPage extends StatelessWidget {
  const AppShellPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is Authenticated ? authState.user.uid : '';

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create:
              (_) =>
                  getIt<HabitsBloc>()
                    ..add(HabitsEvent.loadRequested(userId: userId)),
        ),
        BlocProvider(
          create:
              (_) =>
                  getIt<MoneyBloc>()
                    ..add(MoneyEvent.loadRequested(userId: userId)),
        ),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          state.whenOrNull(
            unauthenticated: () {
              context.router.replaceAll([const LoginRoute()]);
            },
          );
        },
        child: AutoTabsScaffold(
          routes: const [
            DashboardRoute(),
            HabitsRoute(),
            MoneyRoute(),
            InsightsRoute(),
          ],
          transitionBuilder: (context, child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          bottomNavigationBuilder: (context, tabsRouter) {
            return NavigationBar(
              selectedIndex: tabsRouter.activeIndex,
              onDestinationSelected: tabsRouter.setActiveIndex,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: 'Today',
                ),
                NavigationDestination(
                  icon: Icon(Icons.check_circle_outline),
                  selectedIcon: Icon(Icons.check_circle_rounded),
                  label: 'Habits',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: Icon(Icons.account_balance_wallet_rounded),
                  label: 'Money',
                ),
                NavigationDestination(
                  icon: Icon(Icons.insights_outlined),
                  selectedIcon: Icon(Icons.insights_rounded),
                  label: 'Insights',
                ),
              ],
            );
          },
          floatingActionButtonBuilder: (context, tabsRouter) {
            final colorScheme = Theme.of(context).colorScheme;
            final activeIndex = tabsRouter.activeIndex;

            // No FAB on Insights tab
            if (activeIndex == 3) return null;

            // Habits tab → add habit
            if (activeIndex == 1) {
              return FloatingActionButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.router.push(HabitCreateEditRoute());
                },
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                child: const Icon(Icons.add, size: 28),
              );
            }

            // Today (0) and Money (2) → add transaction
            return FloatingActionButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                context.router.push(TransactionCreateEditRoute());
              },
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              child: const Icon(Icons.receipt_long_rounded, size: 26),
            );
          },
        ),
      ),
    );
  }
}
