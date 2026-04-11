import 'dart:async';
import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:track/core/router/app_router.gr.dart';
import 'package:track/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:track/features/auth/presentation/bloc/auth_event.dart';
import 'package:track/features/auth/presentation/bloc/auth_state.dart';
import 'package:track/features/onboarding/domain/usecases/check_onboarding_status.dart';
import 'package:track/injection.dart';

@RoutePage()
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _pulseController;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scale;
  late final Animation<double> _glowExpand;
  late final Animation<double> _glowFade;

  bool _minTimePassed = false;
  AuthState? _pendingState;

  @override
  void initState() {
    super.initState();

    // Entry animation — plays once slowly
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _fadeIn = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0, 0.3, curve: Curves.easeOut),
    );

    _scale = Tween<double>(begin: 0.7, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0, 0.35, curve: Curves.easeOutBack),
      ),
    );

    _glowExpand = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.25, 0.85, curve: Curves.easeOutSine),
      ),
    );

    _glowFade = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.6, 1, curve: Curves.easeInQuad),
      ),
    );

    // Repeating pulse — kicks in if loading takes long
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _entryController
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _minTimePassed = true;
          _navigateIfReady();
          // If auth isn't done yet, start pulsing
          if (_pendingState == null || _isWaiting(_pendingState!)) {
            _pulseController.repeat(reverse: true);
          }
        }
      })
      ..forward();
    context.read<AuthBloc>().add(const AuthEvent.authCheckRequested());
  }

  bool _isWaiting(AuthState state) {
    return state.when(
      initial: () => true,
      loading: () => true,
      authenticated: (_) => false,
      unauthenticated: () => false,
      error: (_) => false,
    );
  }

  void _navigateIfReady() {
    if (!_minTimePassed || _pendingState == null || !mounted) return;
    if (_isWaiting(_pendingState!)) return;

    _pendingState!.when(
      initial: () {},
      loading: () {},
      authenticated: (user) => unawaited(_navigateAuthenticated(user.uid)),
      unauthenticated:
          () => unawaited(context.router.replaceAll([const LoginRoute()])),
      error: (_) => unawaited(context.router.replaceAll([const LoginRoute()])),
    );
  }

  Future<void> _navigateAuthenticated(String uid) async {
    final result = await getIt<CheckOnboardingStatus>().call(uid);
    if (!mounted) return;
    result.fold(
      (_) => unawaited(context.router.replaceAll([const AppShellRoute()])),
      (completed) => unawaited(
        completed
            ? context.router.replaceAll([const AppShellRoute()])
            : context.router.replaceAll([OnboardingRoute(userId: uid)]),
      ),
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        _pendingState = state;
        _navigateIfReady();
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors:
                  isDark
                      ? [
                        colorScheme.surface,
                        Color.lerp(
                          colorScheme.surface,
                          colorScheme.primary,
                          0.08,
                        )!,
                      ]
                      : [
                        colorScheme.surface,
                        Color.lerp(
                          colorScheme.surface,
                          colorScheme.primary,
                          0.05,
                        )!,
                      ],
            ),
          ),
          child: Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_entryController, _pulseController]),
              builder: (context, child) {
                // Pulse value: 0 during entry, then 0↔1 repeating
                final pulse = _pulseController.value;
                final glowProgress =
                    _glowExpand.value +
                    (_entryController.isCompleted ? pulse * 0.3 : 0);

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Blurred glow that spreads slowly and fades
                    Opacity(
                      opacity:
                          _entryController.isCompleted
                              ? 0.3 + (pulse * 0.3)
                              : _glowExpand.value * _glowFade.value,
                      child: Container(
                        width: 100 + (glowProgress * 200),
                        height: 100 + (glowProgress * 200),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              colorScheme.primary.withValues(alpha: 0.4),
                              colorScheme.tertiary.withValues(alpha: 0.2),
                              colorScheme.surface.withValues(alpha: 0),
                            ],
                            stops: const [0, 0.5, 1],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(
                                alpha: 0.15,
                              ),
                              blurRadius: 40 + (glowProgress * 60),
                              spreadRadius: glowProgress * 30,
                            ),
                            BoxShadow(
                              color: colorScheme.tertiary.withValues(
                                alpha: 0.1,
                              ),
                              blurRadius: 60 + (glowProgress * 40),
                              spreadRadius: glowProgress * 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Logo + text
                    FadeTransition(
                      opacity: _fadeIn,
                      child: ScaleTransition(
                        scale: _scale,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Center(
                                child: Transform.rotate(
                                  angle: -math.pi / 12,
                                  child: Icon(
                                    Icons.show_chart_rounded,
                                    size: 48,
                                    color: colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Track',
                              style: Theme.of(
                                context,
                              ).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
