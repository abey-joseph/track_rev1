import 'package:auto_route/auto_route.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/router/app_router.gr.dart';
import 'package:track/features/auth/domain/repositories/auth_repository.dart';

@lazySingleton
class AuthGuard extends AutoRouteGuard {
  AuthGuard(this._authRepository);

  final AuthRepository _authRepository;

  @override
  Future<void> onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    final result = _authRepository.currentUser;
    if (result != null) {
      resolver.next();
    } else {
      await router.replace(const LoginRoute());
      resolver.next(false);
    }
  }
}
