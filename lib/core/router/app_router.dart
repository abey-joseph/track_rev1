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
    AutoRoute(page: HomeRoute.page, guards: [_authGuard]),
  ];

  @override
  List<AutoRouteGuard> get guards => [];
}
