import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:track/core/router/app_router.gr.dart';
import 'package:track/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:track/features/auth/presentation/bloc/auth_event.dart';
import 'package:track/features/auth/presentation/bloc/auth_state.dart';

@RoutePage()
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(const AuthEvent.authCheckRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        state.when(
          initial: () {},
          loading: () {},
          authenticated: (user) {
            context.router.replaceAll([const HomeRoute()]);
          },
          unauthenticated: () {
            context.router.replaceAll([const LoginRoute()]);
          },
          error: (failure) {
            context.router.replaceAll([const LoginRoute()]);
          },
        );
      },
      child: const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      ),
    );
  }
}
