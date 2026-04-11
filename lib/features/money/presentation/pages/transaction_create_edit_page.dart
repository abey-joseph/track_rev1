import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:track/core/extensions/context_extensions.dart';
import 'package:track/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:track/features/auth/presentation/bloc/auth_state.dart';
import 'package:track/features/money/domain/entities/account_entity.dart';
import 'package:track/features/money/domain/entities/category_entity.dart';
import 'package:track/features/money/domain/entities/currency_entity.dart';
import 'package:track/features/money/domain/entities/transaction_entity.dart';
import 'package:track/features/money/presentation/bloc/transaction_form_bloc.dart';
import 'package:track/features/money/presentation/bloc/transaction_form_event.dart';
import 'package:track/features/money/presentation/bloc/transaction_form_state.dart';
import 'package:track/features/money/presentation/utils/money_icon_resolver.dart';
import 'package:track/features/money/presentation/widgets/account_picker_sheet.dart';
import 'package:track/features/money/presentation/widgets/category_picker_sheet.dart';
import 'package:track/features/money/presentation/widgets/transaction_type_toggle.dart';
import 'package:track/injection.dart';

@RoutePage()
class TransactionCreateEditPage extends StatelessWidget {
  const TransactionCreateEditPage({super.key, this.transactionId});

  final String? transactionId;

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is Authenticated ? authState.user.uid : '';

    return BlocProvider(
      create:
          (_) =>
              getIt<TransactionFormBloc>()
                ..add(TransactionFormEvent.initialized(userId: userId)),
      child: _TransactionFormView(userId: userId),
    );
  }
}

class _TransactionFormView extends StatelessWidget {
  const _TransactionFormView({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return BlocListener<TransactionFormBloc, TransactionFormState>(
      listenWhen:
          (prev, curr) =>
              prev.isSuccess != curr.isSuccess ||
              prev.errorMessage != curr.errorMessage,
      listener: (context, state) {
        if (state.isSuccess) {
          HapticFeedback.mediumImpact();
          context.showSnackBar('Transaction saved');
          context.router.maybePop();
        } else if (state.errorMessage != null) {
          context.showSnackBar(state.errorMessage!, isError: true);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('New Transaction'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: BlocSelector<
                TransactionFormBloc,
                TransactionFormState,
                (bool, bool)
              >(
                selector: (state) {
                  final hasBase =
                      state.amount.isNotEmpty && state.title.isNotEmpty;
                  final hasTarget =
                      state.type == TransactionType.transfer
                          ? state.toAccountId != null
                          : state.categoryId != null;
                  return (state.isSubmitting, hasBase && hasTarget);
                },
                builder: (context, data) {
                  final (isSubmitting, canSave) = data;
                  return FilledButton(
                    onPressed:
                        canSave && !isSubmitting
                            ? () => context.read<TransactionFormBloc>().add(
                              TransactionFormEvent.submitted(userId: userId),
                            )
                            : null,
                    child:
                        isSubmitting
                            ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                            : const Text('Save'),
                  );
                },
              ),
            ),
          ],
        ),
        body: const SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TypeToggleSection(),
              SizedBox(height: 12),
              _AmountField(),
              SizedBox(height: 10),
              _TitleField(),
              SizedBox(height: 16),
              _CategoryAccountRow(),
              SizedBox(height: 8),
              _ToAccountSection(),
              SizedBox(height: 16),
              _DateSection(),
              SizedBox(height: 16),
              _NoteField(),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeToggleSection extends StatelessWidget {
  const _TypeToggleSection();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      TransactionFormBloc,
      TransactionFormState,
      TransactionType
    >(
      selector: (state) => state.type,
      builder: (context, type) {
        return Center(
          child: TransactionTypeToggle(
            selected: type,
            onChanged:
                (t) => context.read<TransactionFormBloc>().add(
                  TransactionFormEvent.typeChanged(type: t),
                ),
          ),
        );
      },
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField();

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;

    return BlocSelector<
      TransactionFormBloc,
      TransactionFormState,
      (TransactionType, List<CurrencyEntity>, String)
    >(
      selector:
          (state) => (
            state.type,
            state.availableCurrencies,
            state.selectedCurrencyCode,
          ),
      builder: (context, data) {
        final (type, currencies, selectedCode) = data;
        final accentColor = switch (type) {
          TransactionType.income => const Color(0xFF4CAF50),
          TransactionType.transfer => const Color(0xFF2196F3),
          _ => const Color(0xFFF44336),
        };

        final selected =
            currencies.isNotEmpty
                ? currencies.firstWhere(
                  (c) => c.code == selectedCode,
                  orElse: () => currencies.first,
                )
                : null;
        final symbol = selected?.symbol ?? r'$';
        final code = selected?.code ?? selectedCode;

        return Container(
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accentColor.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              // Currency selector (fixed size, tappable)
              GestureDetector(
                onTap:
                    currencies.isEmpty
                        ? null
                        : () {
                          FocusScope.of(context).unfocus();
                          showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder:
                                (_) => _CurrencyPickerSheet(
                                  currencies: currencies,
                                  selectedCode: selectedCode,
                                  onSelected:
                                      (c) => context
                                          .read<TransactionFormBloc>()
                                          .add(
                                            TransactionFormEvent.currencySelected(
                                              currencyCode: c,
                                            ),
                                          ),
                                ),
                          );
                        },
                child: Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        symbol,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                      Text(
                        code,
                        style: textTheme.labelSmall?.copyWith(
                          color: accentColor.withValues(alpha: 0.8),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Amount field (flexible)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: TextFormField(
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    style: textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                    textAlign: TextAlign.end,
                    decoration: InputDecoration(
                      fillColor: Colors.transparent,
                      hintText: '0.00',
                      hintStyle: textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: accentColor.withValues(alpha: 0.25),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    onChanged:
                        (v) => context.read<TransactionFormBloc>().add(
                          TransactionFormEvent.amountChanged(amount: v),
                        ),
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

class _TitleField extends StatelessWidget {
  const _TitleField();

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return TextFormField(
      textCapitalization: TextCapitalization.sentences,
      maxLength: 100,
      decoration: InputDecoration(
        labelText: 'Title',
        hintText: 'e.g. Lunch, Salary, Uber...',
        prefixIcon: const Icon(Icons.edit_rounded),
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        counterText: '',
      ),
      onChanged:
          (v) => context.read<TransactionFormBloc>().add(
            TransactionFormEvent.titleChanged(title: v),
          ),
    );
  }
}

class _CategoryAccountRow extends StatelessWidget {
  const _CategoryAccountRow();

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return BlocSelector<
      TransactionFormBloc,
      TransactionFormState,
      (
        TransactionType,
        List<CategoryEntity>,
        int?,
        CategoryEntity?,
        List<AccountEntity>,
        int?,
        AccountEntity?,
      )
    >(
      selector: (state) {
        final categories = TransactionFormBloc.filteredCategories(state);
        final selectedCatId = state.categoryId;
        final selectedCat =
            selectedCatId != null
                ? categories.where((c) => c.id == selectedCatId).firstOrNull
                : null;
        final accounts = state.availableAccounts;
        final selectedAccId = state.accountId;
        final selectedAcc =
            selectedAccId != null
                ? accounts.where((a) => a.id == selectedAccId).firstOrNull
                : null;
        return (
          state.type,
          categories,
          selectedCatId,
          selectedCat,
          accounts,
          selectedAccId,
          selectedAcc,
        );
      },
      builder: (context, data) {
        final (
          type,
          categories,
          selectedCatId,
          selectedCat,
          accounts,
          selectedAccId,
          selectedAcc,
        ) = data;
        final isTransfer = type == TransactionType.transfer;

        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              // Category half — hidden for transfers
              if (!isTransfer) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder:
                            (_) => CategoryPickerSheet(
                              categories: categories,
                              selectedId: selectedCatId,
                              onSelected:
                                  (id) =>
                                      context.read<TransactionFormBloc>().add(
                                        TransactionFormEvent.categorySelected(
                                          categoryId: id,
                                        ),
                                      ),
                            ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.grid_view_rounded,
                            size: 20,
                            color:
                                selectedCat != null
                                    ? colorScheme.primary
                                    : colorScheme.onSurface.withValues(
                                      alpha: 0.4,
                                    ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child:
                                selectedCat == null
                                    ? Text(
                                      'Category',
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurface.withValues(
                                          alpha: 0.4,
                                        ),
                                      ),
                                    )
                                    : _CategoryChip(category: selectedCat),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Vertical divider
                Container(
                  width: 1,
                  height: 24,
                  color: colorScheme.onSurface.withValues(alpha: 0.12),
                ),
              ],
              // Account half
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder:
                          (_) => AccountPickerSheet(
                            accounts: accounts,
                            selectedId: selectedAccId,
                            onSelected:
                                (id) => context.read<TransactionFormBloc>().add(
                                  TransactionFormEvent.accountSelected(
                                    accountId: id,
                                  ),
                                ),
                          ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 20,
                          color:
                              selectedAcc != null
                                  ? colorScheme.primary
                                  : colorScheme.onSurface.withValues(
                                    alpha: 0.4,
                                  ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child:
                              selectedAcc == null
                                  ? Text(
                                    isTransfer ? 'From account' : 'Account',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                  )
                                  : _AccountChip(
                                    account: selectedAcc,
                                    prefix: isTransfer ? 'From: ' : null,
                                  ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                      ],
                    ),
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

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});

  final CategoryEntity category;

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(category.colorHex);
    final textTheme = context.textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          child: Icon(
            resolveMoneyIcon(category.iconName),
            size: 14,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            category.name,
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
            softWrap: false,
            overflow: TextOverflow.fade,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}

class _AccountChip extends StatelessWidget {
  const _AccountChip({required this.account, this.prefix});

  final AccountEntity account;
  final String? prefix;

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(account.colorHex);
    final textTheme = context.textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          child: Icon(
            resolveMoneyIcon(account.iconName),
            size: 14,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        if (prefix != null)
          Text(
            prefix!,
            style: textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        Flexible(
          child: Text(
            account.name,
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
            softWrap: false,
            overflow: TextOverflow.fade,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}

class _ToAccountSection extends StatelessWidget {
  const _ToAccountSection();

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return BlocSelector<
      TransactionFormBloc,
      TransactionFormState,
      (List<AccountEntity>, int?, int?, AccountEntity?)
    >(
      selector: (state) {
        if (state.type != TransactionType.transfer) {
          return (const [], null, null, null);
        }
        // Exclude the from-account
        final filtered =
            state.availableAccounts
                .where((a) => a.id != state.accountId)
                .toList();
        final selectedId = state.toAccountId;
        final selected =
            selectedId != null
                ? filtered.where((a) => a.id == selectedId).firstOrNull
                : null;
        return (filtered, selectedId, state.accountId, selected);
      },
      builder: (context, data) {
        final (accounts, selectedId, _, selectedAccount) = data;

        if (accounts.isEmpty) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder:
                  (_) => AccountPickerSheet(
                    accounts: accounts,
                    selectedId: selectedId,
                    onSelected:
                        (id) => context.read<TransactionFormBloc>().add(
                          TransactionFormEvent.toAccountSelected(accountId: id),
                        ),
                  ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.swap_horiz_rounded,
                  size: 22,
                  color:
                      selectedAccount != null
                          ? const Color(0xFF2196F3)
                          : colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child:
                      selectedAccount == null
                          ? Text(
                            'To account',
                            style: textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.4,
                              ),
                            ),
                          )
                          : _AccountChip(
                            account: selectedAccount,
                            prefix: 'To: ',
                          ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CurrencyPickerSheet extends StatelessWidget {
  const _CurrencyPickerSheet({
    required this.currencies,
    required this.selectedCode,
    required this.onSelected,
  });

  final List<CurrencyEntity> currencies;
  final String selectedCode;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return DraggableScrollableSheet(
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Select Currency',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: currencies.length,
                  itemBuilder: (_, index) {
                    final currency = currencies[index];
                    final isSelected = currency.code == selectedCode;
                    return GestureDetector(
                      onTap: () {
                        onSelected(currency.code);
                        Navigator.pop(context);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? colorScheme.primaryContainer
                                  : colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              isSelected
                                  ? Border.all(
                                    color: colorScheme.primary,
                                    width: 1.5,
                                  )
                                  : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              currency.symbol,
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color:
                                    isSelected
                                        ? colorScheme.primary
                                        : colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currency.code,
                              style: textTheme.labelSmall?.copyWith(
                                color:
                                    isSelected
                                        ? colorScheme.primary
                                        : colorScheme.onSurface.withValues(
                                          alpha: 0.6,
                                        ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DateSection extends StatelessWidget {
  const _DateSection();

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final colorScheme = context.colorScheme;

    return BlocSelector<TransactionFormBloc, TransactionFormState, DateTime?>(
      selector: (state) => state.date,
      builder: (context, date) {
        final displayDate = date ?? DateTime.now();
        final formatted =
            '${_months[displayDate.month - 1]} ${displayDate.day}, ${displayDate.year}';

        return GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: displayDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 1)),
            );
            if (picked != null && context.mounted) {
              context.read<TransactionFormBloc>().add(
                TransactionFormEvent.dateChanged(date: picked),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 22,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  formatted,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
}

class _NoteField extends StatelessWidget {
  const _NoteField();

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return TextFormField(
      maxLines: 2,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: 'Note (optional)',
        hintText: 'Add a note...',
        prefixIcon: const Padding(
          padding: EdgeInsets.only(bottom: 24),
          child: Icon(Icons.notes_rounded),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
      onChanged:
          (v) => context.read<TransactionFormBloc>().add(
            TransactionFormEvent.noteChanged(note: v),
          ),
    );
  }
}

Color _parseColor(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}
