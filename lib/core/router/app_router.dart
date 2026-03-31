import 'package:auto_route/auto_route.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/router/app_router.gr.dart';
import 'package:track/core/router/auth_guard.dart';

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
@lazySingleton
class AppRouter extends RootStackRouter {
  AppRouter(this._authGuard);

  final AuthGuard _authGuard;

  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: SplashRoute.page, initial: true),
    AutoRoute(page: LoginRoute.page),

    // Main app shell with bottom navigation
    AutoRoute(
      page: AppShellRoute.page,
      guards: [_authGuard],
      children: [
        AutoRoute(page: DashboardRoute.page, initial: true),
        AutoRoute(page: HabitsRoute.page),
        AutoRoute(page: MoneyRoute.page),
        AutoRoute(page: InsightsRoute.page),
      ],
    ),

    // Habits detail routes
    AutoRoute(page: HabitDetailRoute.page, path: '/habit/:id'),
    CustomRoute<HabitCreateEditRoute>(
      page: HabitCreateEditRoute.page,
      fullscreenDialog: true,
      transitionsBuilder: TransitionsBuilders.slideBottom,
    ),
    AutoRoute(page: HabitStatsRoute.page, path: '/habit/:id/stats'),

    // Money detail routes
    AutoRoute(page: TransactionDetailRoute.page, path: '/transaction/:id'),
    CustomRoute<TransactionCreateEditRoute>(
      page: TransactionCreateEditRoute.page,
      fullscreenDialog: true,
      transitionsBuilder: TransitionsBuilders.slideBottom,
    ),
    AutoRoute(page: AccountsRoute.page),
    AutoRoute(page: AccountDetailRoute.page, path: '/account/:id'),
    AutoRoute(page: BudgetRoute.page),
    AutoRoute(page: BudgetDetailRoute.page, path: '/budget/:id'),

    // Insights detail routes
    AutoRoute(page: InsightDetailRoute.page, path: '/insight/:id'),
    AutoRoute(page: AnalysisRoute.page),

    // Settings
    AutoRoute(page: SettingsRoute.page),
    AutoRoute(page: ProfileRoute.page),
  ];

  @override
  List<AutoRouteGuard> get guards => [];
}
