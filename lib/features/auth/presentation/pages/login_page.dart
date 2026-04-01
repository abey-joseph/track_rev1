import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:track/core/extensions/context_extensions.dart';
import 'package:track/core/router/app_router.gr.dart';
import 'package:track/core/widgets/app_button.dart';
import 'package:track/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:track/features/auth/presentation/bloc/auth_event.dart';
import 'package:track/features/auth/presentation/bloc/auth_state.dart';
import 'package:track/features/auth/presentation/widgets/email_sign_in_form.dart';
import 'package:track/features/auth/presentation/widgets/social_sign_in_button.dart';

@RoutePage()
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        state.whenOrNull(
          authenticated: (user) {
            context.router.replaceAll([const AppShellRoute()]);
          },
          error: (failure) {
            context.showSnackBar(failure.toString(), isError: true);
          },
        );
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Lottie.asset(
                  'assets/images/login_animation.json',
                  height: 150,
                  fit: BoxFit.contain,
                  repeat: true,
                ),
                const SizedBox(height: 16),
                Text(
                  'Track',
                  style: context.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Track your life',
                  style: context.textTheme.bodyLarge?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                const EmailSignInForm(),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),
                SocialSignInButton(
                  label: 'Continue with Google',
                  icon: Icons.g_mobiledata,
                  onPressed:
                      () => context.read<AuthBloc>().add(
                        const AuthEvent.signInWithGoogleRequested(),
                      ),
                ),
                const SizedBox(height: 12),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final isLoading = state is AuthLoading;
                    return AppButton(
                      label: 'Continue as Guest',
                      variant: AppButtonVariant.text,
                      isLoading: isLoading,
                      onPressed:
                          () => context.read<AuthBloc>().add(
                            const AuthEvent.signInAnonymouslyRequested(),
                          ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
