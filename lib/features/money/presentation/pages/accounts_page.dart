import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:track/core/extensions/context_extensions.dart';
import 'package:track/core/router/app_router.gr.dart';
import 'package:track/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:track/features/auth/presentation/bloc/auth_state.dart';
import 'package:track/features/money/domain/entities/account_entity.dart';
import 'package:track/features/money/presentation/bloc/accounts/accounts_bloc.dart';
import 'package:track/features/money/presentation/bloc/accounts/accounts_event.dart';
import 'package:track/features/money/presentation/bloc/accounts/accounts_state.dart';
import 'package:track/features/money/presentation/utils/currency_formatter.dart'
    as fmt;
import 'package:track/injection.dart';

@RoutePage()
class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is Authenticated ? authState.user.uid : '';

    return BlocProvider(
      create: (_) => getIt<AccountsBloc>()..add(AccountsEvent.started(userId)),
      child: const _AccountsView(),
    );
  }
}

class _AccountsView extends StatelessWidget {
  const _AccountsView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AccountsBloc, AccountsState>(
      listenWhen: (prev, curr) {
        if (prev is AccountsLoaded && curr is AccountsLoaded) {
          return curr.deleteError != null &&
              curr.deleteError != prev.deleteError;
        }
        return false;
      },
      listener: (context, state) {
        if (state is AccountsLoaded && state.deleteError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.deleteError!),
              backgroundColor: context.colorScheme.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Accounts')),
        body: BlocBuilder<AccountsBloc, AccountsState>(
          builder:
              (context, state) => switch (state) {
                AccountsInitial() || AccountsLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
                AccountsLoaded() => _AccountsList(state: state),
                AccountsError(:final failure) => _ErrorView(failure: failure),
              },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.router.push(AccountCreateEditRoute()),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

// ── Account List ─────────────────────────────────────────────────────────────

class _AccountsList extends StatelessWidget {
  const _AccountsList({required this.state});

  final AccountsLoaded state;

  @override
  Widget build(BuildContext context) {
    if (state.accounts.isEmpty) {
      return _EmptyView();
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: state.accounts.length,
      itemBuilder: (context, index) {
        final account = state.accounts[index];
        return BlocSelector<AccountsBloc, AccountsState, AccountEntity?>(
          selector:
              (s) =>
                  s is AccountsLoaded
                      ? s.accounts.where((a) => a.id == account.id).firstOrNull
                      : null,
          builder: (context, a) {
            if (a == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AccountCard(account: a),
            );
          },
        );
      },
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.account});

  final AccountEntity account;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final color = _parseColor(account.colorHex, colorScheme.primary);

    return GestureDetector(
      onTap:
          () => context.router.push(
            AccountDetailRoute(accountId: account.id.toString()),
          ),
      onLongPress: () => _showDeleteDialog(context, account),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _resolveIcon(account.iconName),
                        color: color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  account.name,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (account.isDefault)
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
                          if (account.description != null &&
                              account.description!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              account.description!,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Balance',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    Text(
                      fmt.formatCurrency(account.balanceCents),
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color:
                            account.balanceCents >= 0
                                ? colorScheme.primary
                                : colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, AccountEntity account) {
    if (account.isDefault) {
      showDialog<void>(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text('Cannot Delete'),
              content: Text(
                '"${account.name}" is the default account and cannot be deleted.\n\nSet another account as default first.',
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
            title: const Text('Delete Account?'),
            content: Text(
              'Delete "${account.name}"? This cannot be undone.',
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
                  context.read<AccountsBloc>().add(
                    AccountsEvent.deleteRequested(account.id),
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

  IconData _resolveIcon(String name) {
    return switch (name) {
      'account_balance_wallet' => Icons.account_balance_wallet_rounded,
      'account_balance' => Icons.account_balance_rounded,
      'credit_card' => Icons.credit_card_rounded,
      'savings' => Icons.savings_rounded,
      'store' => Icons.store_rounded,
      'home' => Icons.home_rounded,
      'trending_up' => Icons.trending_up_rounded,
      'money' => Icons.attach_money_rounded,
      'paid' => Icons.paid_rounded,
      'payment' => Icons.payment_rounded,
      'currency_exchange' => Icons.currency_exchange_rounded,
      'currency_bitcoin' => Icons.currency_bitcoin_rounded,
      _ => Icons.account_balance_wallet_rounded,
    };
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
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: context.colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No accounts yet',
            style: context.textTheme.titleMedium?.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first account',
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
        'Failed to load accounts',
        style: context.textTheme.bodyMedium?.copyWith(
          color: context.colorScheme.error,
        ),
      ),
    );
  }
}
