import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:track/core/extensions/context_extensions.dart';
import 'package:track/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:track/features/auth/presentation/bloc/auth_state.dart';
import 'package:track/features/money/domain/entities/currency_entity.dart';
import 'package:track/features/money/presentation/bloc/currency_form/currency_form_bloc.dart';
import 'package:track/features/money/presentation/bloc/currency_form/currency_form_event.dart';
import 'package:track/features/money/presentation/bloc/currency_form/currency_form_state.dart';
import 'package:track/injection.dart';

@RoutePage()
class CurrencyCreateEditPage extends StatelessWidget {
  const CurrencyCreateEditPage({
    super.key,
    this.currency,
    this.defaultCurrencyCode,
  });

  /// Provide an existing [CurrencyEntity] to open in edit mode.
  final CurrencyEntity? currency;

  /// ISO code of the user's current default currency (e.g. 'USD').
  final String? defaultCurrencyCode;

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is Authenticated ? authState.user.uid : '';

    return BlocProvider(
      create:
          (_) =>
              getIt<CurrencyFormBloc>()..add(
                CurrencyFormEvent.initialized(
                  userId: userId,
                  currency: currency,
                  defaultCurrencyCode: defaultCurrencyCode,
                ),
              ),
      child: const _CurrencyFormView(),
    );
  }
}

class _CurrencyFormView extends StatelessWidget {
  const _CurrencyFormView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<CurrencyFormBloc, CurrencyFormState>(
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
          title: BlocSelector<CurrencyFormBloc, CurrencyFormState, bool>(
            selector: (s) => s.isEditMode,
            builder:
                (_, isEdit) => Text(isEdit ? 'Edit Currency' : 'Add Currency'),
          ),
          actions: [
            BlocSelector<CurrencyFormBloc, CurrencyFormState, (bool, bool)>(
              selector:
                  (s) => (
                    s.isSubmitting,
                    s.name.trim().isEmpty ||
                        s.code.trim().isEmpty ||
                        s.symbol.trim().isEmpty,
                  ),
              builder: (context, data) {
                final (isSubmitting, isInvalid) = data;
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
                      isInvalid
                          ? null
                          : () => context.read<CurrencyFormBloc>().add(
                            const CurrencyFormEvent.submitted(),
                          ),
                  child: const Text('Save'),
                );
              },
            ),
          ],
        ),
        body: const SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _NameField(),
              SizedBox(height: 20),
              _CodeField(),
              SizedBox(height: 20),
              _SymbolField(),
              SizedBox(height: 20),
              _ExchangeRateSection(),
            ],
          ),
        ),
      ),
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
    _controller = TextEditingController(
      text: context.read<CurrencyFormBloc>().state.name,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Currency Name',
          style: context.textTheme.labelLarge?.copyWith(
            color: context.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          maxLength: 100,
          onChanged:
              (v) => context.read<CurrencyFormBloc>().add(
                CurrencyFormEvent.nameChanged(v),
              ),
          decoration: const InputDecoration(
            hintText: 'e.g. US Dollar, Euro…',
            counterText: '',
          ),
        ),
      ],
    );
  }
}

// ── Code Field ────────────────────────────────────────────────────────────────

class _CodeField extends StatefulWidget {
  const _CodeField();

  @override
  State<_CodeField> createState() => _CodeFieldState();
}

class _CodeFieldState extends State<_CodeField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<CurrencyFormBloc>().state.code,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = context.select<CurrencyFormBloc, bool>(
      (b) => b.state.isEditMode,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Currency Code (ISO 4217)',
          style: context.textTheme.labelLarge?.copyWith(
            color: context.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          maxLength: 10,
          // Code should not change on edit since it's referenced by accounts
          enabled: !isEdit,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[A-Za-z]')),
          ],
          onChanged:
              (v) => context.read<CurrencyFormBloc>().add(
                CurrencyFormEvent.codeChanged(v),
              ),
          decoration: InputDecoration(
            hintText: 'e.g. USD, EUR, GBP',
            counterText: '',
            helperText:
                isEdit
                    ? 'Currency code cannot be changed after creation'
                    : null,
          ),
        ),
      ],
    );
  }
}

// ── Symbol Field ──────────────────────────────────────────────────────────────

class _SymbolField extends StatefulWidget {
  const _SymbolField();

  @override
  State<_SymbolField> createState() => _SymbolFieldState();
}

class _SymbolFieldState extends State<_SymbolField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<CurrencyFormBloc>().state.symbol,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Symbol',
          style: context.textTheme.labelLarge?.copyWith(
            color: context.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          maxLength: 10,
          onChanged:
              (v) => context.read<CurrencyFormBloc>().add(
                CurrencyFormEvent.symbolChanged(v),
              ),
          decoration: const InputDecoration(
            hintText: r'e.g. $, €, £',
            counterText: '',
          ),
        ),
      ],
    );
  }
}

// ── Exchange Rate Section ─────────────────────────────────────────────────────

class _ExchangeRateSection extends StatefulWidget {
  const _ExchangeRateSection();

  @override
  State<_ExchangeRateSection> createState() => _ExchangeRateSectionState();
}

class _ExchangeRateSectionState extends State<_ExchangeRateSection> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<CurrencyFormBloc>().state.exchangeRateText,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CurrencyFormBloc, CurrencyFormState, (bool, String?)>(
      selector: (s) => (s.isDefault, s.defaultCurrencyCode),
      builder: (context, data) {
        final (isDefault, defaultCode) = data;

        if (isDefault) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This is the default currency. Its exchange rate is fixed at 1.00.',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurface.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final label =
            defaultCode != null
                ? 'Exchange Rate (1 $defaultCode = ? this currency)'
                : 'Exchange Rate vs Default Currency';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: context.textTheme.labelLarge?.copyWith(
                color: context.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              onChanged:
                  (v) => context.read<CurrencyFormBloc>().add(
                    CurrencyFormEvent.exchangeRateChanged(v),
                  ),
              decoration: const InputDecoration(
                hintText: 'e.g. 82.5',
                helperText:
                    'How many units of this currency equal 1 of the default',
              ),
            ),
          ],
        );
      },
    );
  }
}
