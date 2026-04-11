import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:track/core/router/app_router.gr.dart';
import 'package:track/features/onboarding/domain/entities/onboarding_step_entity.dart';
import 'package:track/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:track/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:track/features/onboarding/presentation/bloc/onboarding_state.dart';
import 'package:track/features/onboarding/presentation/widgets/onboarding_accounts_step.dart';
import 'package:track/features/onboarding/presentation/widgets/onboarding_categories_step.dart';
import 'package:track/features/onboarding/presentation/widgets/onboarding_currency_step.dart';
import 'package:track/features/onboarding/presentation/widgets/onboarding_name_step.dart';
import 'package:track/features/onboarding/presentation/widgets/onboarding_personalising_step.dart';
import 'package:track/features/onboarding/presentation/widgets/onboarding_progress_indicator.dart';
import 'package:track/injection.dart';

@RoutePage()
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({required this.userId, super.key});

  final String userId;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _stepWidget(OnboardingStepType type) => switch (type) {
    OnboardingStepType.name => const OnboardingNameStep(),
    OnboardingStepType.currency => const OnboardingCurrencyStep(),
    OnboardingStepType.categories => const OnboardingCategoriesStep(),
    OnboardingStepType.accounts => const OnboardingAccountsStep(),
    OnboardingStepType.personalising => const OnboardingPersonalisingStep(),
  };

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OnboardingBloc>(
      create:
          (_) =>
              getIt<OnboardingBloc>()
                ..add(OnboardingEvent.started(userId: widget.userId)),
      child: BlocListener<OnboardingBloc, OnboardingState>(
        listener: (context, state) {
          if (state.isCompleted) {
            unawaited(context.router.replaceAll([const AppShellRoute()]));
            return;
          }
          // Animate PageView when step index changes.
          if (_pageController.hasClients &&
              _pageController.page?.round() != state.currentStepIndex) {
            unawaited(
              _pageController.animateToPage(
                state.currentStepIndex,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              ),
            );
          }
        },
        child: Scaffold(
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                const OnboardingProgressIndicator(),
                const SizedBox(height: 8),
                Expanded(
                  child: BlocSelector<
                    OnboardingBloc,
                    OnboardingState,
                    List<OnboardingStepEntity>
                  >(
                    selector: (state) => state.steps,
                    builder: (context, steps) {
                      if (steps.isEmpty) return const SizedBox.shrink();
                      return PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children:
                            steps
                                .map((step) => _stepWidget(step.type))
                                .toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
