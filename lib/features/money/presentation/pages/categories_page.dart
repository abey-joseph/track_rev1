import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:track/core/extensions/context_extensions.dart';
import 'package:track/core/router/app_router.gr.dart';
import 'package:track/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:track/features/auth/presentation/bloc/auth_state.dart';
import 'package:track/features/money/domain/entities/category_entity.dart';
import 'package:track/features/money/presentation/bloc/categories/categories_bloc.dart';
import 'package:track/features/money/presentation/bloc/categories/categories_event.dart';
import 'package:track/features/money/presentation/bloc/categories/categories_state.dart';
import 'package:track/features/money/presentation/utils/money_icon_resolver.dart';
import 'package:track/injection.dart';

@RoutePage()
class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is Authenticated ? authState.user.uid : '';

    return BlocProvider(
      create:
          (_) => getIt<CategoriesBloc>()..add(CategoriesEvent.started(userId)),
      child: const _CategoriesView(),
    );
  }
}

class _CategoriesView extends StatelessWidget {
  const _CategoriesView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<CategoriesBloc, CategoriesState>(
      listenWhen: (prev, curr) {
        if (prev is CategoriesLoaded && curr is CategoriesLoaded) {
          return curr.deleteError != null &&
              curr.deleteError != prev.deleteError;
        }
        return false;
      },
      listener: (context, state) {
        if (state is CategoriesLoaded && state.deleteError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.deleteError!),
              backgroundColor: context.colorScheme.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Categories')),
        body: BlocBuilder<CategoriesBloc, CategoriesState>(
          builder:
              (context, state) => switch (state) {
                CategoriesInitial() || CategoriesLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
                CategoriesLoaded() => _CategoriesList(state: state),
                CategoriesError(:final failure) => _ErrorView(
                  failure: failure,
                ),
              },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.router.push(CategoryCreateEditRoute()),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

// ── Categories List ───────────────────────────────────────────────────────────

class _CategoriesList extends StatelessWidget {
  const _CategoriesList({required this.state});

  final CategoriesLoaded state;

  @override
  Widget build(BuildContext context) {
    if (state.categories.isEmpty) {
      return const _EmptyView();
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: state.categories.length,
      itemBuilder: (context, index) {
        final category = state.categories[index];
        return BlocSelector<CategoriesBloc, CategoriesState, CategoryEntity?>(
          selector:
              (s) =>
                  s is CategoriesLoaded
                      ? s.categories
                          .where((c) => c.id == category.id)
                          .firstOrNull
                      : null,
          builder: (context, c) {
            if (c == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CategoryCard(category: c),
            );
          },
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category});

  final CategoryEntity category;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final color = _parseColor(category.colorHex, colorScheme.primary);
    final typeLabel = _typeLabel(category.transactionType);
    final typeColor = _typeColor(category.transactionType, colorScheme);

    return GestureDetector(
      onLongPress: () => _showDeleteDialog(context, category),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    resolveMoneyIcon(category.iconName),
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          typeLabel,
                          style: textTheme.labelSmall?.copyWith(
                            color: typeColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap:
                      () => context.router.push(
                        CategoryCreateEditRoute(category: category),
                      ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.edit_rounded,
                      size: 18,
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, CategoryEntity category) {
    showDialog<void>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Delete Category?'),
            content: Text(
              'Delete "${category.name}"? This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: context.colorScheme.error,
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  context.read<CategoriesBloc>().add(
                    CategoriesEvent.deleteRequested(category.id),
                  );
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  Color _parseColor(String hex, Color fallback) {
    try {
      final clean = hex.replaceFirst('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  String _typeLabel(CategoryTransactionType type) => switch (type) {
    CategoryTransactionType.income => 'Income',
    CategoryTransactionType.expense => 'Expense',
    CategoryTransactionType.both => 'Both',
    CategoryTransactionType.transfer => 'Transfer',
  };

  Color _typeColor(CategoryTransactionType type, ColorScheme cs) =>
      switch (type) {
        CategoryTransactionType.income => Colors.green,
        CategoryTransactionType.expense => cs.error,
        CategoryTransactionType.both => cs.primary,
        CategoryTransactionType.transfer => const Color(0xFF2196F3),
      };
}

// ── Empty / Error Views ───────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.category_outlined,
            size: 64,
            color: context.colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No categories yet',
            style: context.textTheme.titleMedium?.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first category',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.failure});

  final Object failure;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Failed to load categories',
        style: context.textTheme.bodyMedium?.copyWith(
          color: context.colorScheme.error,
        ),
      ),
    );
  }
}
