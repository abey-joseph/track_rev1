import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:track/core/extensions/context_extensions.dart';
import 'package:track/core/router/app_router.gr.dart';
import 'package:track/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:track/features/auth/presentation/bloc/auth_state.dart';
import 'package:track/features/money/domain/entities/currency_entity.dart';
import 'package:track/features/money/presentation/bloc/currency/currency_bloc.dart';
import 'package:track/features/money/presentation/bloc/currency/currency_event.dart';
import 'package:track/features/money/presentation/bloc/currency/currency_state.dart';
import 'package:track/injection.dart';

@RoutePage()
class CurrencyPage extends StatelessWidget {
  const CurrencyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is Authenticated ? authState.user.uid : '';

    return BlocProvider(
      create: (_) => getIt<CurrencyBloc>()..add(CurrencyEvent.started(userId)),
      child: const _CurrencyView(),
    );
  }
}

class _CurrencyView extends StatelessWidget {
  const _CurrencyView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<CurrencyBloc, CurrencyState>(
      listenWhen: (prev, curr) {
        if (prev is CurrencyLoaded && curr is CurrencyLoaded) {
          return curr.deleteError != null &&
              curr.deleteError != prev.deleteError;
        }
        return false;
      },
      listener: (context, state) {
        if (state is CurrencyLoaded && state.deleteError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.deleteError!),
              backgroundColor: context.colorScheme.error,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Currencies')),
        body: BlocBuilder<CurrencyBloc, CurrencyState>(
          builder:
              (context, state) => switch (state) {
                CurrencyInitial() || CurrencyLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
                CurrencyLoaded() => _CurrencyList(state: state),
                CurrencyError() => _ErrorView(),
              },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.router.push(CurrencyCreateEditRoute()),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

// ── Currency List ─────────────────────────────────────────────────────────────

class _CurrencyList extends StatelessWidget {
  const _CurrencyList({required this.state});

  final CurrencyLoaded state;

  @override
  Widget build(BuildContext context) {
    if (state.currencies.isEmpty) {
      return _EmptyView();
    }

    final defaultCurrency = state.currencies.firstWhere(
      (c) => c.isDefault,
      orElse: () => state.currencies.first,
    );

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: state.currencies.length,
      itemBuilder: (context, index) {
        final currency = state.currencies[index];
        return BlocSelector<CurrencyBloc, CurrencyState, CurrencyEntity?>(
          selector:
              (s) =>
                  s is CurrencyLoaded
                      ? s.currencies
                          .where((c) => c.id == currency.id)
                          .firstOrNull
                      : null,
          builder: (context, c) {
            if (c == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CurrencyCard(
                currency: c,
                defaultCurrency: defaultCurrency,
              ),
            );
          },
        );
      },
    );
  }
}

class _CurrencyCard extends StatelessWidget {
  const _CurrencyCard({required this.currency, required this.defaultCurrency});

  final CurrencyEntity currency;
  final CurrencyEntity defaultCurrency;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return GestureDetector(
      onTap:
          () => context.router.push(
            CurrencyCreateEditRoute(
              currency: currency,
              defaultCurrencyCode: defaultCurrency.code,
            ),
          ),
      onLongPress: () => _showDeleteDialog(context, currency),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Currency symbol chip
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    currency.symbol,
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${currency.code} — ${currency.name}',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (currency.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Default',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (currency.isDefault)
                      Text(
                        'Base currency (rate: 1.00)',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      )
                    else
                      Text(
                        '1 ${defaultCurrency.code} = ${currency.exchangeRate.toStringAsFixed(4)} ${currency.code}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, CurrencyEntity currency) {
    if (currency.isDefault) {
      showDialog<void>(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text('Cannot Delete'),
              content: Text(
                '"${currency.name}" is the default currency and cannot be deleted.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Delete Currency?'),
            content: Text(
              'Delete "${currency.name} (${currency.code})"?\n\nThis cannot be undone. Currencies used by any account cannot be deleted.',
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
                  context.read<CurrencyBloc>().add(
                    CurrencyEvent.deleteRequested(currency.id),
                  );
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}

// ── Empty / Error Views ───────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.currency_exchange_rounded,
            size: 64,
            color: context.colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No currencies yet',
            style: context.textTheme.titleMedium?.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Failed to load currencies',
        style: context.textTheme.bodyMedium?.copyWith(
          color: context.colorScheme.error,
        ),
      ),
    );
  }
}
