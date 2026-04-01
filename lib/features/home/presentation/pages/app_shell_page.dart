import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:track/core/router/app_router.gr.dart';
import 'package:track/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:track/features/auth/presentation/bloc/auth_state.dart';
import 'package:track/features/home/presentation/widgets/quick_add_fab.dart';

@RoutePage()
class AppShellPage extends StatelessWidget {
  const AppShellPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
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
          // Hide FAB on Insights tab (index 3)
          if (tabsRouter.activeIndex == 3) return null;

          return QuickAddFab(
            // On Money tab (index 2), single tap goes to transaction entry
            showSpeedDial: tabsRouter.activeIndex != 2,
            onLogHabit: () {
              context.router.push(HabitCreateEditRoute());
            },
            onAddTransaction: () {
              context.router.push(TransactionCreateEditRoute());
            },
          );
        },
      ),
    );
  }
}
