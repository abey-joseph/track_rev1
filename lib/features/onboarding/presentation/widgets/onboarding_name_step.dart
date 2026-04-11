import 'dart:async';

import 'package:dotlottie_flutter/dotlottie_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:track/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:track/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:track/features/onboarding/presentation/bloc/onboarding_state.dart';

class OnboardingNameStep extends StatefulWidget {
  const OnboardingNameStep({super.key});

  @override
  State<OnboardingNameStep> createState() => _OnboardingNameStepState();
}

class _OnboardingNameStepState extends State<OnboardingNameStep>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  late final AnimationController _animController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeIn = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    unawaited(_animController.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const Expanded(
            flex: 4,
            child: DotLottieView(
              sourceType: 'asset',
              backgroundColor: '#FFFFFFF',
              source: 'lottie/Loop.lottie',
              autoplay: true,
              loop: true,
            ),
          ),
          Expanded(
            flex: 6,
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideIn,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'What should we call you?',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Helps us make Track feel like yours',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),
                    BlocBuilder<OnboardingBloc, OnboardingState>(
                      buildWhen:
                          (prev, curr) => prev.displayName != curr.displayName,
                      builder: (context, state) {
                        return TextField(
                          controller: _controller,
                          autofocus: true,
                          textCapitalization: TextCapitalization.words,
                          style: textTheme.bodyLarge,
                          decoration: InputDecoration(
                            hintText: 'Enter your name',
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                          ),
                          onChanged:
                              (value) => context.read<OnboardingBloc>().add(
                                OnboardingEvent.nameChanged(name: value),
                              ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    BlocSelector<OnboardingBloc, OnboardingState, bool>(
                      selector: (state) => state.canProceed,
                      builder: (context, canProceed) {
                        return FilledButton(
                          onPressed:
                              canProceed
                                  ? () => context.read<OnboardingBloc>().add(
                                    const OnboardingEvent.nextPressed(),
                                  )
                                  : null,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Continue',
                            style: TextStyle(fontSize: 16),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
