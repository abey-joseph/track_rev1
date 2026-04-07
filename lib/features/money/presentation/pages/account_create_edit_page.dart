import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:track/core/extensions/context_extensions.dart';
import 'package:track/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:track/features/auth/presentation/bloc/auth_state.dart';
import 'package:track/features/money/domain/entities/account_entity.dart';
import 'package:track/features/money/domain/entities/currency_entity.dart';
import 'package:track/features/money/presentation/bloc/account_form/account_form_bloc.dart';
import 'package:track/features/money/presentation/bloc/account_form/account_form_event.dart';
import 'package:track/features/money/presentation/bloc/account_form/account_form_state.dart';
import 'package:track/injection.dart';

const _accountColors = [
  '#4CAF50',
  '#2196F3',
  '#E91E63',
  '#FF9800',
  '#9C27B0',
  '#00BCD4',
  '#F44336',
  '#3F51B5',
  '#607D8B',
  '#795548',
  '#FF5722',
  '#FFC107',
];

const _accountIcons = [
  'account_balance_wallet',
  'account_balance',
  'credit_card',
  'savings',
  'store',
  'home',
  'trending_up',
  'money',
  'paid',
  'payment',
  'currency_exchange',
  'currency_bitcoin',
];

@RoutePage()
class AccountCreateEditPage extends StatelessWidget {
  const AccountCreateEditPage({super.key, this.account});

  /// Provide an existing [AccountEntity] to open in edit mode.
  final AccountEntity? account;

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is Authenticated ? authState.user.uid : '';

    return BlocProvider(
      create:
          (_) =>
              getIt<AccountFormBloc>()..add(
                AccountFormEvent.initialized(
                  userId: userId,
                  account: account,
                ),
              ),
      child: const _AccountFormView(),
    );
  }
}

class _AccountFormView extends StatelessWidget {
  const _AccountFormView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AccountFormBloc, AccountFormState>(
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
          title: BlocSelector<AccountFormBloc, AccountFormState, bool>(
            selector: (s) => s.isEditMode,
            builder:
                (_, isEdit) => Text(isEdit ? 'Edit Account' : 'Add Account'),
          ),
          actions: [
            BlocSelector<
              AccountFormBloc,
              AccountFormState,
              (bool, bool, String)
            >(
              selector: (s) => (s.isSubmitting, s.name.trim().isEmpty, s.name),
              builder: (context, data) {
                final (isSubmitting, isEmpty, _) = data;
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
                          : () => context.read<AccountFormBloc>().add(
                            const AccountFormEvent.submitted(),
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
              _DescriptionField(),
              _CurrencySection(),
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
      AccountFormBloc,
      AccountFormState,
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
                    _resolveIcon(iconName),
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
                  name.trim().isEmpty ? 'Account Name' : name.trim(),
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
    final currentName = context.read<AccountFormBloc>().state.name;
    _controller = TextEditingController(text: currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Name',
            style: context.textTheme.labelLarge?.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            maxLength: 100,
            onChanged:
                (v) => context.read<AccountFormBloc>().add(
                  AccountFormEvent.nameChanged(v),
                ),
            decoration: const InputDecoration(
              hintText: 'e.g. Cash, Savings…',
              counterText: '',
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── Description Field ─────────────────────────────────────────────────────────

class _DescriptionField extends StatefulWidget {
  const _DescriptionField();

  @override
  State<_DescriptionField> createState() => _DescriptionFieldState();
}

class _DescriptionFieldState extends State<_DescriptionField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final current = context.read<AccountFormBloc>().state.description;
    _controller = TextEditingController(text: current);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description (optional)',
            style: context.textTheme.labelLarge?.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            maxLines: 2,
            maxLength: 200,
            onChanged:
                (v) => context.read<AccountFormBloc>().add(
                  AccountFormEvent.descriptionChanged(v),
                ),
            decoration: const InputDecoration(
              hintText: 'Optional notes about this account',
              counterText: '',
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── Currency Section ──────────────────────────────────────────────────────────

class _CurrencySection extends StatelessWidget {
  const _CurrencySection();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      AccountFormBloc,
      AccountFormState,
      (List<CurrencyEntity>, String)
    >(
      selector: (s) => (s.availableCurrencies, s.currencyCode),
      builder: (context, data) {
        final (currencies, selectedCode) = data;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Currency',
                style: context.textTheme.labelLarge?.copyWith(
                  color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              if (currencies.isEmpty)
                const CircularProgressIndicator()
              else
                DropdownButtonFormField<String>(
                  value:
                      currencies.any((c) => c.code == selectedCode)
                          ? selectedCode
                          : null,
                  decoration: const InputDecoration(),
                  items:
                      currencies
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.code,
                              child: Text(
                                '${c.code} — ${c.name} (${c.symbol})',
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      context.read<AccountFormBloc>().add(
                        AccountFormEvent.currencyChanged(v),
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
    return BlocSelector<AccountFormBloc, AccountFormState, String>(
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
                    _accountColors.map((hex) {
                      final color = _parseColor(
                        hex,
                        context.colorScheme.primary,
                      );
                      final isSelected = hex == selectedColor;
                      return GestureDetector(
                        onTap:
                            () => context.read<AccountFormBloc>().add(
                              AccountFormEvent.colorChanged(hex),
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
    return BlocSelector<AccountFormBloc, AccountFormState, (String, String)>(
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
                    _accountIcons.map((icon) {
                      final isSelected = icon == selectedIcon;
                      return GestureDetector(
                        onTap:
                            () => context.read<AccountFormBloc>().add(
                              AccountFormEvent.iconChanged(icon),
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
                            _resolveIcon(icon),
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
