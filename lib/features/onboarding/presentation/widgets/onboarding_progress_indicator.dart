import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:track/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:track/features/onboarding/presentation/bloc/onboarding_state.dart';

class OnboardingProgressIndicator extends StatelessWidget {
  const OnboardingProgressIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<OnboardingBloc, OnboardingState, (int, int)>(
      selector: (state) => (state.steps.length, state.currentStepIndex),
      builder: (context, data) {
        final (total, current) = data;
        if (total == 0) return const SizedBox.shrink();
        // Hide indicator on the final (personalising) step.
        final isLast = current == total - 1;
        if (isLast) return const SizedBox(height: 20);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(total - 1, (index) {
              final isActive = index == current;
              final isPast = index < current;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color:
                      isActive || isPast
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
