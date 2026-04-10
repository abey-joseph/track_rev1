import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:track/core/extensions/context_extensions.dart';
import 'package:track/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:track/features/auth/presentation/bloc/auth_state.dart';
import 'package:track/features/money/domain/entities/category_entity.dart';
import 'package:track/features/money/presentation/bloc/category_form/category_form_bloc.dart';
import 'package:track/features/money/presentation/bloc/category_form/category_form_event.dart';
import 'package:track/features/money/presentation/bloc/category_form/category_form_state.dart';
import 'package:track/features/money/presentation/utils/money_icon_resolver.dart';
import 'package:track/injection.dart';

const _categoryColors = [
  '#4CAF50',
  '#2196F3',
  '#E91E63',
  '#FF9800',
  '#9C27B0',
  '#00BCD4',
  '#F44336',
  '#3F51B5',
  '#FF5722',
  '#607D8B',
  '#795548',
  '#FFC107',
  '#8BC34A',
  '#009688',
  '#673AB7',
];

const _categoryIcons = [
  'restaurant',
  'directions_car',
  'movie',
  'shopping_bag',
  'receipt_long',
  'favorite',
  'school',
  'more_horiz',
  'payments',
  'work',
  'trending_up',
  'card_giftcard',
  'home',
  'flight',
  'fitness_center',
  'local_hospital',
  'local_grocery_store',
  'phone_android',
  'coffee',
  'sports_esports',
];

@RoutePage()
class CategoryCreateEditPage extends StatelessWidget {
  const CategoryCreateEditPage({super.key, this.category});

  /// Provide an existing [CategoryEntity] to open in edit mode.
  final CategoryEntity? category;

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is Authenticated ? authState.user.uid : '';

    return BlocProvider(
      create:
          (_) =>
              getIt<CategoryFormBloc>()..add(
                CategoryFormEvent.initialized(
                  userId: userId,
                  category: category,
                ),
              ),
      child: const _CategoryFormView(),
    );
  }
}

class _CategoryFormView extends StatelessWidget {
  const _CategoryFormView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<CategoryFormBloc, CategoryFormState>(
      listenWhen:
          (prev, curr) =>
              curr.isSuccess != prev.isSuccess ||
              curr.errorMessage != prev.errorMessage,
      listener: (context, state) {
        if (state.isSuccess) {
          context.router.maybePop();
        }
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: context.colorScheme.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: BlocSelector<CategoryFormBloc, CategoryFormState, bool>(
            selector: (s) => s.isEditMode,
            builder:
                (_, isEdit) => Text(isEdit ? 'Edit Category' : 'Add Category'),
          ),
          actions: [
            BlocSelector<CategoryFormBloc, CategoryFormState, (bool, bool)>(
              selector: (s) => (s.isSubmitting, s.name.trim().isEmpty),
              builder: (context, data) {
                final (isSubmitting, isEmpty) = data;
                if (isSubmitting) {
                  return const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                return TextButton(
                  onPressed:
                      isEmpty
                          ? null
                          : () => context.read<CategoryFormBloc>().add(
                            const CategoryFormEvent.submitted(),
                          ),
                  child: const Text('Save'),
                );
              },
            ),
          ],
        ),
        body: const SingleChildScrollView(
          padding: EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PreviewHeader(),
              SizedBox(height: 24),
              _NameField(),
              _TypeSelector(),
              _ColorSection(),
              _IconSection(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Preview Header ────────────────────────────────────────────────────────────

class _PreviewHeader extends StatelessWidget {
  const _PreviewHeader();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      CategoryFormBloc,
      CategoryFormState,
      (String, String, String)
    >(
      selector: (s) => (s.colorHex, s.iconName, s.name),
      builder: (context, data) {
        final (colorHex, iconName, name) = data;
        final color = _parseColor(colorHex, context.colorScheme.primary);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          color: color.withValues(alpha: 0.12),
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Container(
                  key: ValueKey(iconName),
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Icon(
                    resolveMoneyIcon(iconName),
                    color: color,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  key: ValueKey(name),
                  name.trim().isEmpty ? 'Category Name' : name.trim(),
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color:
                        name.trim().isEmpty
                            ? context.colorScheme.onSurface.withValues(
                              alpha: 0.3,
                            )
                            : context.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Name Field ────────────────────────────────────────────────────────────────

class _NameField extends StatefulWidget {
  const _NameField();

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final currentName = context.read<CategoryFormBloc>().state.name;
    _controller = TextEditingController(text: currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CategoryFormBloc, CategoryFormState>(
      listenWhen: (prev, curr) => prev.name != curr.name,
      listener: (context, state) {
        if (_controller.text != state.name) {
          _controller.text = state.name;
          _controller.selection = TextSelection.collapsed(
            offset: state.name.length,
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Name',
              style: context.textTheme.labelLarge?.copyWith(
                color: context.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              maxLength: 50,
              onChanged:
                  (v) => context.read<CategoryFormBloc>().add(
                    CategoryFormEvent.nameChanged(v),
                  ),
              decoration: const InputDecoration(
                hintText: 'e.g. Food & Dining, Transport…',
                counterText: '',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Type Selector ─────────────────────────────────────────────────────────────

class _TypeSelector extends StatelessWidget {
  const _TypeSelector();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      CategoryFormBloc,
      CategoryFormState,
      CategoryTransactionType
    >(
      selector: (s) => s.transactionType,
      builder: (context, selectedType) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Type',
                style: context.textTheme.labelLarge?.copyWith(
                  color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<CategoryTransactionType>(
                segments: const [
                  ButtonSegment(
                    value: CategoryTransactionType.expense,
                    label: Text('Expense'),
                    icon: Icon(Icons.arrow_downward_rounded),
                  ),
                  ButtonSegment(
                    value: CategoryTransactionType.income,
                    label: Text('Income'),
                    icon: Icon(Icons.arrow_upward_rounded),
                  ),
                  ButtonSegment(
                    value: CategoryTransactionType.both,
                    label: Text('Both'),
                    icon: Icon(Icons.swap_vert_rounded),
                  ),
                ],
                selected: {selectedType},
                onSelectionChanged: (set) {
                  if (set.isNotEmpty) {
                    context.read<CategoryFormBloc>().add(
                      CategoryFormEvent.transactionTypeChanged(set.first),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Color Section ─────────────────────────────────────────────────────────────

class _ColorSection extends StatelessWidget {
  const _ColorSection();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CategoryFormBloc, CategoryFormState, String>(
      selector: (s) => s.colorHex,
      builder: (context, selectedColor) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Color',
                style: context.textTheme.labelLarge?.copyWith(
                  color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children:
                    _categoryColors.map((hex) {
                      final color = _parseColor(
                        hex,
                        context.colorScheme.primary,
                      );
                      final isSelected = hex == selectedColor;
                      return GestureDetector(
                        onTap:
                            () => context.read<CategoryFormBloc>().add(
                              CategoryFormEvent.colorChanged(hex),
                            ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border:
                                isSelected
                                    ? Border.all(
                                      color: context.colorScheme.onSurface,
                                      width: 2.5,
                                    )
                                    : null,
                            boxShadow:
                                isSelected
                                    ? [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.4),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                    : null,
                          ),
                          child:
                              isSelected
                                  ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 18,
                                  )
                                  : null,
                        ),
                      );
                    }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Icon Section ──────────────────────────────────────────────────────────────

class _IconSection extends StatelessWidget {
  const _IconSection();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CategoryFormBloc, CategoryFormState, (String, String)>(
      selector: (s) => (s.iconName, s.colorHex),
      builder: (context, data) {
        final (selectedIcon, colorHex) = data;
        final color = _parseColor(colorHex, context.colorScheme.primary);

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Icon',
                style: context.textTheme.labelLarge?.copyWith(
                  color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children:
                    _categoryIcons.map((icon) {
                      final isSelected = icon == selectedIcon;
                      return GestureDetector(
                        onTap:
                            () => context.read<CategoryFormBloc>().add(
                              CategoryFormEvent.iconChanged(icon),
                            ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? color.withValues(alpha: 0.2)
                                    : context
                                        .colorScheme
                                        .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                isSelected
                                    ? Border.all(color: color, width: 2)
                                    : null,
                          ),
                          child: Icon(
                            resolveMoneyIcon(icon),
                            color:
                                isSelected
                                    ? color
                                    : context.colorScheme.onSurface.withValues(
                                      alpha: 0.6,
                                    ),
                            size: 24,
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Color _parseColor(String hex, Color fallback) {
  try {
    final clean = hex.replaceFirst('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  } on FormatException {
    return fallback;
  }
}
