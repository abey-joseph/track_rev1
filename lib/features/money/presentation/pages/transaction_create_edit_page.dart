import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:track/core/extensions/context_extensions.dart';
import 'package:track/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:track/features/auth/presentation/bloc/auth_state.dart';
import 'package:track/features/money/domain/entities/category_entity.dart';
import 'package:track/features/money/domain/entities/transaction_entity.dart';
import 'package:track/features/money/presentation/bloc/transaction_form_bloc.dart';
import 'package:track/features/money/presentation/bloc/transaction_form_event.dart';
import 'package:track/features/money/presentation/bloc/transaction_form_state.dart';
import 'package:track/features/money/presentation/widgets/account_picker_grid.dart';
import 'package:track/features/money/presentation/widgets/category_picker_grid.dart';
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
                selector:
                    (state) => (
                      state.isSubmitting,
                      state.amount.isNotEmpty && state.title.isNotEmpty,
                    ),
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
              _CategorySection(),
              SizedBox(height: 16),
              _AccountSection(),
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
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return BlocSelector<
      TransactionFormBloc,
      TransactionFormState,
      TransactionType
    >(
      selector: (state) => state.type,
      builder: (context, type) {
        final isIncome = type == TransactionType.income;
        final accentColor =
            isIncome ? const Color(0xFF4CAF50) : const Color(0xFFF44336);

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accentColor.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '\$',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w300,
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IntrinsicWidth(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 80),
                  child: TextFormField(
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
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
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

class _CategorySection extends StatelessWidget {
  const _CategorySection();

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final colorScheme = context.colorScheme;

    return BlocSelector<
      TransactionFormBloc,
      TransactionFormState,
      (List<CategoryEntity>, int?, TransactionType)
    >(
      selector:
          (state) => (
            TransactionFormBloc.filteredCategories(state),
            state.categoryId,
            state.type,
          ),
      builder: (context, data) {
        final (categories, selectedId, _) = data;
        if (categories.isEmpty) {
          return Text(
            'No categories available',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          );
        }
        return CategoryPickerGrid(
          categories: categories,
          selectedId: selectedId,
          onSelected:
              (id) => context.read<TransactionFormBloc>().add(
                TransactionFormEvent.categorySelected(categoryId: id),
              ),
        );
      },
    );
  }
}

class _AccountSection extends StatelessWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final colorScheme = context.colorScheme;

    return BlocSelector<
      TransactionFormBloc,
      TransactionFormState,
      (List<dynamic>, int?)
    >(
      selector: (state) => (state.availableAccounts, state.accountId),
      builder: (context, data) {
        final accounts = data.$1;
        final selectedId = data.$2;
        if (accounts.isEmpty) {
          return Text(
            'Loading accounts...',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          );
        }
        return AccountPickerGrid(
          accounts: accounts.cast(),
          selectedId: selectedId,
          onSelected:
              (id) => context.read<TransactionFormBloc>().add(
                TransactionFormEvent.accountSelected(accountId: id),
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
