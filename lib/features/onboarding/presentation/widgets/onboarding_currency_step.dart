import 'dart:async';

import 'package:dotlottie_flutter/dotlottie_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:track/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:track/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:track/features/onboarding/presentation/bloc/onboarding_state.dart';

const _kCurrencies = [
  _Currency('USD', r'$', 'US Dollar'),
  _Currency('EUR', '€', 'Euro'),
  _Currency('GBP', '£', 'British Pound'),
  _Currency('AUD', r'A$', 'Australian Dollar'),
  _Currency('JPY', '¥', 'Japanese Yen'),
  _Currency('CAD', r'C$', 'Canadian Dollar'),
  _Currency('SGD', r'S$', 'Singapore Dollar'),
  _Currency('MYR', 'RM', 'Malaysian Ringgit'),
  _Currency('INR', '₹', 'Indian Rupee'),
  _Currency('CHF', 'Fr', 'Swiss Franc'),
  _Currency('CNY', '¥', 'Chinese Yuan'),
  _Currency('NZD', r'NZ$', 'New Zealand Dollar'),
];

class OnboardingCurrencyStep extends StatefulWidget {
  const OnboardingCurrencyStep({super.key});

  @override
  State<OnboardingCurrencyStep> createState() => _OnboardingCurrencyStepState();
}

class _OnboardingCurrencyStepState extends State<OnboardingCurrencyStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    unawaited(_animController.forward());
  }

  @override
  void dispose() {
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
          const SizedBox(
            height: 180,
            child: DotLottieView(
              sourceType: 'asset',
              source: 'lottie/currency.lottie',
              autoplay: true,
              loop: true,
            ),
          ),
          const SizedBox(height: 8),
          FadeTransition(
            opacity: _fadeIn,
            child: SlideTransition(
              position: _slideIn,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Pick your currency',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You can always add more later',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  BlocSelector<OnboardingBloc, OnboardingState, String>(
                    selector: (state) => state.selectedCurrency,
                    builder: (context, selected) {
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children:
                            _kCurrencies.map((c) {
                              final isSelected = c.code == selected;
                              return GestureDetector(
                                onTap:
                                    () => context.read<OnboardingBloc>().add(
                                      OnboardingEvent.currencySelected(
                                        currencyCode: c.code,
                                      ),
                                    ),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? colorScheme.primaryContainer
                                            : colorScheme
                                                .surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? colorScheme.primary
                                              : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        c.symbol,
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color:
                                              isSelected
                                                  ? colorScheme.primary
                                                  : colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        c.code,
                                        style: textTheme.bodyMedium?.copyWith(
                                          color:
                                              isSelected
                                                  ? colorScheme
                                                      .onPrimaryContainer
                                                  : colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed:
                        () => context.read<OnboardingBloc>().add(
                          const OnboardingEvent.nextPressed(),
                        ),
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
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Currency {
  const _Currency(this.code, this.symbol, this.name);

  final String code;
  final String symbol;
  final String name;
}
