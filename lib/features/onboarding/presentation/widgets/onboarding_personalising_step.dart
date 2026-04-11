import 'dart:async';

import 'package:dotlottie_flutter/dotlottie_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:track/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:track/features/onboarding/presentation/bloc/onboarding_event.dart';

const _kMessages = [
  'Setting up your categories\u2026',
  'Configuring your accounts\u2026',
  'Applying your preferences\u2026',
  'Almost there\u2026',
];

class OnboardingPersonalisingStep extends StatefulWidget {
  const OnboardingPersonalisingStep({super.key});

  @override
  State<OnboardingPersonalisingStep> createState() =>
      _OnboardingPersonalisingStepState();
}

class _OnboardingPersonalisingStepState
    extends State<OnboardingPersonalisingStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeIn;
  int _messageIndex = 0;
  Timer? _messageTimer;
  bool _hasTriggered = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    unawaited(_animController.forward());
    _startMessageCycle();
  }

  void _startMessageCycle() {
    _messageTimer = Timer.periodic(const Duration(milliseconds: 1600), (_) {
      if (!mounted) return;
      setState(() {
        _messageIndex = (_messageIndex + 1) % _kMessages.length;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Trigger finalization exactly once when this step becomes visible.
    if (!_hasTriggered) {
      _hasTriggered = true;
      context.read<OnboardingBloc>().add(
        const OnboardingEvent.finalizationRequested(),
      );
    }
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return FadeTransition(
      opacity: _fadeIn,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Expanded(
            flex: 5,
            child: DotLottieView(
              sourceType: 'asset',
              source: 'lottie/LOADING.lottie',
              autoplay: true,
              loop: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                Text(
                  'Setting things up\u2026',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder:
                      (child, animation) => FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                  child: Text(
                    _kMessages[_messageIndex],
                    key: ValueKey(_messageIndex),
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const Expanded(flex: 2, child: SizedBox()),
        ],
      ),
    );
  }
}
