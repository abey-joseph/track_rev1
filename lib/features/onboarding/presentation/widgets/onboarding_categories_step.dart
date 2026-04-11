import 'dart:async';

import 'package:dotlottie_flutter/dotlottie_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:track/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:track/features/onboarding/presentation/bloc/onboarding_event.dart';

/// Default category entries shown in the onboarding step.
/// IDs match the database seeded values in AppDatabase._seedDefaultCategories.
const _kDefaultCategories = [
  _CategoryItem(id: 1, name: 'Food & Dining', icon: Icons.restaurant),
  _CategoryItem(id: 2, name: 'Transport', icon: Icons.directions_car),
  _CategoryItem(id: 3, name: 'Entertainment', icon: Icons.movie),
  _CategoryItem(id: 4, name: 'Shopping', icon: Icons.shopping_bag),
  _CategoryItem(id: 5, name: 'Bills & Utilities', icon: Icons.receipt_long),
  _CategoryItem(id: 6, name: 'Health', icon: Icons.favorite),
  _CategoryItem(id: 7, name: 'Education', icon: Icons.school),
  _CategoryItem(id: 8, name: 'Other Expense', icon: Icons.more_horiz),
  _CategoryItem(id: 9, name: 'Salary', icon: Icons.payments),
  _CategoryItem(id: 10, name: 'Freelance', icon: Icons.work),
  _CategoryItem(id: 11, name: 'Investment', icon: Icons.trending_up),
  _CategoryItem(id: 12, name: 'Gift', icon: Icons.card_giftcard),
];

class OnboardingCategoriesStep extends StatefulWidget {
  const OnboardingCategoriesStep({super.key});

  @override
  State<OnboardingCategoriesStep> createState() =>
      _OnboardingCategoriesStepState();
}

class _OnboardingCategoriesStepState extends State<OnboardingCategoriesStep>
    with SingleTickerProviderStateMixin {
  late final Set<int> _selected;
  late final AnimationController _animController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();
    // Pre-select all categories by default.
    _selected = _kDefaultCategories.map((c) => c.id).toSet();
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

  void _toggle(int id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        const SizedBox(
          height: 240,
          child: DotLottieView(
            sourceType: 'asset',
            source: 'lottie/chat with machine.lottie',
            autoplay: true,
            loop: true,
          ),
        ),
        FadeTransition(
          opacity: _fadeIn,
          child: SlideTransition(
            position: _slideIn,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Choose your categories',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Select what matters to you',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Wrap(
                spacing: 5,
                runSpacing: 8,
                children:
                    _kDefaultCategories.map((cat) {
                      final isSelected = _selected.contains(cat.id);
                      return GestureDetector(
                        onTap: () => _toggle(cat.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? colorScheme.primaryContainer
                                    : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
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
                              Icon(
                                cat.icon,
                                size: 18,
                                color:
                                    isSelected
                                        ? colorScheme.primary
                                        : colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                cat.name,
                                style: textTheme.bodyMedium?.copyWith(
                                  color:
                                      isSelected
                                          ? colorScheme.onPrimaryContainer
                                          : colorScheme.onSurface,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                onPressed: () {
                  context.read<OnboardingBloc>().add(
                    OnboardingEvent.categoriesConfirmed(
                      selectedCategoryIds: _selected.toList(),
                    ),
                  );
                  context.read<OnboardingBloc>().add(
                    const OnboardingEvent.nextPressed(),
                  );
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Continue', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed:
                    () => context.read<OnboardingBloc>().add(
                      const OnboardingEvent.stepSkipped(),
                    ),
                child: Text(
                  'Skip for now',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryItem {
  const _CategoryItem({
    required this.id,
    required this.name,
    required this.icon,
  });

  final int id;
  final String name;
  final IconData icon;
}
