import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:track/core/extensions/context_extensions.dart';
import 'package:track/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:track/features/auth/presentation/bloc/auth_state.dart';
import 'package:track/features/money/domain/entities/category_entity.dart';
import 'package:track/features/money/domain/entities/recurring_transaction_entity.dart';
import 'package:track/features/money/domain/entities/transaction_entity.dart';
import 'package:track/features/money/presentation/bloc/recurring_transaction_form/recurring_transaction_form_bloc.dart';
import 'package:track/features/money/presentation/bloc/recurring_transaction_form/recurring_transaction_form_event.dart';
import 'package:track/features/money/presentation/bloc/recurring_transaction_form/recurring_transaction_form_state.dart';
import 'package:track/features/money/presentation/widgets/account_picker_grid.dart';
import 'package:track/features/money/presentation/widgets/category_picker_grid.dart';
import 'package:track/features/money/presentation/widgets/transaction_type_toggle.dart';
import 'package:track/injection.dart';

@RoutePage()
class RecurringTransactionCreateEditPage extends StatelessWidget {
  const RecurringTransactionCreateEditPage({
    super.key,
    this.existing,
  });

  final RecurringTransactionEntity? existing;

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is Authenticated ? authState.user.uid : '';

    return BlocProvider(
      create:
          (_) =>
              getIt<RecurringTransactionFormBloc>()..add(
                RecurringTransactionFormEvent.initialized(
                  userId: userId,
                  existing: existing,
                ),
              ),
      child: _RecurringFormView(userId: userId),
    );
  }
}

class _RecurringFormView extends StatelessWidget {
  const _RecurringFormView({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return BlocListener<
      RecurringTransactionFormBloc,
      RecurringTransactionFormState
    >(
      listenWhen:
          (prev, curr) =>
              prev.isSuccess != curr.isSuccess ||
              prev.errorMessage != curr.errorMessage,
      listener: (context, state) {
        if (state.isSuccess) {
          HapticFeedback.mediumImpact();
          context.showSnackBar('Recurring transaction saved');
          context.router.maybePop();
        } else if (state.errorMessage != null) {
          context.showSnackBar(state.errorMessage!, isError: true);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: BlocSelector<
            RecurringTransactionFormBloc,
            RecurringTransactionFormState,
            bool
          >(
            selector: (state) => state.isEditMode,
            builder:
                (context, isEdit) => Text(
                  isEdit ? 'Edit Recurring' : 'New Recurring',
                ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: BlocSelector<
                RecurringTransactionFormBloc,
                RecurringTransactionFormState,
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
                            ? () => context
                                .read<RecurringTransactionFormBloc>()
                                .add(
                                  RecurringTransactionFormEvent.submitted(
                                    userId: userId,
                                  ),
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
              _NoteField(),
              SizedBox(height: 20),
              _RecurrenceSection(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Transaction Fields (mirroring TransactionCreateEditPage) ────────────────

class _TypeToggleSection extends StatelessWidget {
  const _TypeToggleSection();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      RecurringTransactionFormBloc,
      RecurringTransactionFormState,
      TransactionType
    >(
      selector: (state) => state.type,
      builder:
          (context, type) => Center(
            child: TransactionTypeToggle(
              selected: type,
              onChanged:
                  (t) => context.read<RecurringTransactionFormBloc>().add(
                    RecurringTransactionFormEvent.typeChanged(type: t),
                  ),
            ),
          ),
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
      RecurringTransactionFormBloc,
      RecurringTransactionFormState,
      (TransactionType, String)
    >(
      selector: (state) => (state.type, state.amount),
      builder: (context, data) {
        final (type, initialAmount) = data;
        final isIncome = type == TransactionType.income;
        final accentColor =
            isIncome ? const Color(0xFF4CAF50) : const Color(0xFFF44336);

        return Container(
          padding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 20,
          ),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  r'$',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w300,
                    color: colorScheme.onSurface.withValues(
                      alpha: 0.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IntrinsicWidth(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 80),
                  child: _AmountInput(
                    accentColor: accentColor,
                    initialValue: initialAmount,
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

class _AmountInput extends StatefulWidget {
  const _AmountInput({
    required this.accentColor,
    required this.initialValue,
  });

  final Color accentColor;
  final String initialValue;

  @override
  State<_AmountInput> createState() => _AmountInputState();
}

class _AmountInputState extends State<_AmountInput> {
  late final TextEditingController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized && widget.initialValue.isNotEmpty) {
      _controller.text = widget.initialValue;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;

    return TextFormField(
      controller: _controller,
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
        color: widget.accentColor,
      ),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        hintText: '0.00',
        hintStyle: textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: widget.accentColor.withValues(alpha: 0.25),
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        isDense: true,
      ),
      onChanged:
          (v) => context.read<RecurringTransactionFormBloc>().add(
            RecurringTransactionFormEvent.amountChanged(
              amount: v,
            ),
          ),
    );
  }
}

class _TitleField extends StatelessWidget {
  const _TitleField();

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return BlocSelector<
      RecurringTransactionFormBloc,
      RecurringTransactionFormState,
      String
    >(
      selector: (state) => state.title,
      builder:
          (context, initialTitle) => _InitialValueField(
            initialValue: initialTitle,
            maxLength: 100,
            decoration: InputDecoration(
              labelText: 'Title',
              hintText: 'e.g. Rent, Salary, Netflix...',
              prefixIcon: const Icon(Icons.edit_rounded),
              filled: true,
              fillColor: colorScheme.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: colorScheme.primary,
                  width: 1.5,
                ),
              ),
              counterText: '',
            ),
            onChanged:
                (v) => context.read<RecurringTransactionFormBloc>().add(
                  RecurringTransactionFormEvent.titleChanged(title: v),
                ),
          ),
    );
  }
}

class _InitialValueField extends StatefulWidget {
  const _InitialValueField({
    required this.initialValue,
    required this.decoration,
    required this.onChanged,
    this.maxLength,
    this.maxLines = 1,
  });

  final String initialValue;
  final InputDecoration decoration;
  final ValueChanged<String> onChanged;
  final int? maxLength;
  final int maxLines;

  @override
  State<_InitialValueField> createState() => _InitialValueFieldState();
}

class _InitialValueFieldState extends State<_InitialValueField> {
  late final TextEditingController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized && widget.initialValue.isNotEmpty) {
      _controller.text = widget.initialValue;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      maxLength: widget.maxLength,
      maxLines: widget.maxLines,
      textCapitalization: TextCapitalization.sentences,
      decoration: widget.decoration,
      onChanged: widget.onChanged,
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
      RecurringTransactionFormBloc,
      RecurringTransactionFormState,
      (List<CategoryEntity>, int?, TransactionType)
    >(
      selector:
          (state) => (
            RecurringTransactionFormBloc.filteredCategories(state),
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
              (id) => context.read<RecurringTransactionFormBloc>().add(
                RecurringTransactionFormEvent.categorySelected(
                  categoryId: id,
                ),
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
      RecurringTransactionFormBloc,
      RecurringTransactionFormState,
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
              (id) => context.read<RecurringTransactionFormBloc>().add(
                RecurringTransactionFormEvent.accountSelected(
                  accountId: id,
                ),
              ),
        );
      },
    );
  }
}

class _NoteField extends StatelessWidget {
  const _NoteField();

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return BlocSelector<
      RecurringTransactionFormBloc,
      RecurringTransactionFormState,
      String
    >(
      selector: (state) => state.note,
      builder:
          (context, initialNote) => _InitialValueField(
            initialValue: initialNote,
            maxLines: 2,
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
                borderSide: BorderSide(
                  color: colorScheme.primary,
                  width: 1.5,
                ),
              ),
            ),
            onChanged:
                (v) => context.read<RecurringTransactionFormBloc>().add(
                  RecurringTransactionFormEvent.noteChanged(note: v),
                ),
          ),
    );
  }
}

// ── Recurrence Section ──────────────────────────────────────────────────────

class _RecurrenceSection extends StatelessWidget {
  const _RecurrenceSection();

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recurrence',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          const _ScheduleTypeSelector(),
          const SizedBox(height: 16),
          const _StartDateRow(),
          const _ConditionalScheduleControls(),
          const _MonthLengthWarning(),
        ],
      ),
    );
  }
}

class _ScheduleTypeSelector extends StatelessWidget {
  const _ScheduleTypeSelector();

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return BlocSelector<
      RecurringTransactionFormBloc,
      RecurringTransactionFormState,
      RecurringScheduleType
    >(
      selector: (state) => state.scheduleType,
      builder:
          (context, selected) => Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                RecurringScheduleType.values.map((type) {
                  final isSelected = type == selected;
                  return ChoiceChip(
                    label: Text(_scheduleLabel(type)),
                    selected: isSelected,
                    onSelected:
                        (_) => context.read<RecurringTransactionFormBloc>().add(
                          RecurringTransactionFormEvent.scheduleTypeChanged(
                            scheduleType: type,
                          ),
                        ),
                    selectedColor: colorScheme.primaryContainer,
                  );
                }).toList(),
          ),
    );
  }

  String _scheduleLabel(RecurringScheduleType type) => switch (type) {
    RecurringScheduleType.daily => 'Daily',
    RecurringScheduleType.weekly => 'Weekly',
    RecurringScheduleType.monthlyFixed => 'Monthly',
    RecurringScheduleType.monthlyMultiple => 'Monthly ×N',
    RecurringScheduleType.once => 'Once',
  };
}

class _StartDateRow extends StatelessWidget {
  const _StartDateRow();

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final colorScheme = context.colorScheme;

    return BlocSelector<
      RecurringTransactionFormBloc,
      RecurringTransactionFormState,
      (DateTime?, RecurringScheduleType)
    >(
      selector: (state) => (state.startDate, state.scheduleType),
      builder: (context, data) {
        final (date, scheduleType) = data;
        final displayDate = date ?? DateTime.now();
        final label =
            scheduleType == RecurringScheduleType.once
                ? 'Scheduled Date'
                : 'Start Date';
        final formatted =
            '${_months[displayDate.month - 1]} '
            '${displayDate.day}, ${displayDate.year}';

        return GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: displayDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(
                const Duration(days: 365 * 5),
              ),
            );
            if (picked != null && context.mounted) {
              context.read<RecurringTransactionFormBloc>().add(
                RecurringTransactionFormEvent.startDateChanged(
                  date: picked,
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 22,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    Text(
                      formatted,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
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

class _ConditionalScheduleControls extends StatelessWidget {
  const _ConditionalScheduleControls();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      RecurringTransactionFormBloc,
      RecurringTransactionFormState,
      RecurringScheduleType
    >(
      selector: (state) => state.scheduleType,
      builder:
          (context, type) => switch (type) {
            RecurringScheduleType.weekly => const _WeekdayChips(),
            RecurringScheduleType.monthlyFixed => const _MonthDayPicker(),
            RecurringScheduleType.monthlyMultiple =>
              const _MonthMultiplePicker(),
            _ => const SizedBox.shrink(),
          },
    );
  }
}

class _WeekdayChips extends StatelessWidget {
  const _WeekdayChips();

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return BlocSelector<
      RecurringTransactionFormBloc,
      RecurringTransactionFormState,
      List<int>
    >(
      selector: (state) => state.weekdays,
      builder:
          (context, selected) => Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (index) {
                final day = index + 1;
                final isSelected = selected.contains(day);
                return GestureDetector(
                  onTap: () {
                    final updated = List<int>.from(selected);
                    if (isSelected) {
                      updated.remove(day);
                    } else {
                      updated.add(day);
                    }
                    context.read<RecurringTransactionFormBloc>().add(
                      RecurringTransactionFormEvent.weekdaysChanged(
                        weekdays: updated,
                      ),
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          isSelected
                              ? colorScheme.primary
                              : colorScheme.surface,
                      border: Border.all(
                        color:
                            isSelected
                                ? colorScheme.primary
                                : colorScheme.outline.withValues(
                                  alpha: 0.3,
                                ),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _dayLabels[index],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color:
                            isSelected
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
    );
  }
}

class _MonthDayPicker extends StatelessWidget {
  const _MonthDayPicker();

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return BlocSelector<
      RecurringTransactionFormBloc,
      RecurringTransactionFormState,
      int?
    >(
      selector: (state) => state.monthDay,
      builder:
          (context, selected) => Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                Text(
                  'Day of month:',
                  style: context.textTheme.bodyMedium,
                ),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: selected,
                  hint: const Text('Select'),
                  items: List.generate(
                    31,
                    (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text('${i + 1}'),
                    ),
                  ),
                  onChanged: (v) {
                    if (v != null) {
                      context.read<RecurringTransactionFormBloc>().add(
                        RecurringTransactionFormEvent.monthDayChanged(
                          day: v,
                        ),
                      );
                    }
                  },
                  underline: Container(
                    height: 1,
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

class _MonthMultiplePicker extends StatelessWidget {
  const _MonthMultiplePicker();

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return BlocSelector<
      RecurringTransactionFormBloc,
      RecurringTransactionFormState,
      (int?, List<int>)
    >(
      selector: (state) => (state.timesPerMonth, state.monthDays),
      builder: (context, data) {
        final (timesPerMonth, selectedDays) = data;

        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Times per month:', style: textTheme.bodyMedium),
                  const SizedBox(width: 12),
                  DropdownButton<int>(
                    value: timesPerMonth,
                    hint: const Text('Select'),
                    items: List.generate(
                      10,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text('${i + 1}'),
                      ),
                    ),
                    onChanged: (v) {
                      if (v != null) {
                        context.read<RecurringTransactionFormBloc>().add(
                          RecurringTransactionFormEvent.timesPerMonthChanged(
                            count: v,
                          ),
                        );
                      }
                    },
                    underline: Container(
                      height: 1,
                      color: colorScheme.outline.withValues(
                        alpha: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
              if (timesPerMonth != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Select $timesPerMonth day(s):',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(
                      alpha: 0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(31, (i) {
                    final day = i + 1;
                    final isSelected = selectedDays.contains(day);
                    final isFull =
                        selectedDays.length >= timesPerMonth && !isSelected;
                    return GestureDetector(
                      onTap:
                          isFull
                              ? null
                              : () {
                                final updated = List<int>.from(selectedDays);
                                if (isSelected) {
                                  updated.remove(day);
                                } else {
                                  updated.add(day);
                                }
                                context.read<RecurringTransactionFormBloc>().add(
                                  RecurringTransactionFormEvent.monthDaysChanged(
                                    days: updated,
                                  ),
                                );
                              },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              isSelected
                                  ? colorScheme.primary
                                  : isFull
                                  ? colorScheme.surface.withValues(
                                    alpha: 0.5,
                                  )
                                  : colorScheme.surface,
                          border: Border.all(
                            color:
                                isSelected
                                    ? colorScheme.primary
                                    : colorScheme.outline.withValues(
                                      alpha: isFull ? 0.1 : 0.3,
                                    ),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color:
                                isSelected
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurface.withValues(
                                      alpha: isFull ? 0.3 : 0.7,
                                    ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MonthLengthWarning extends StatelessWidget {
  const _MonthLengthWarning();

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return BlocSelector<
      RecurringTransactionFormBloc,
      RecurringTransactionFormState,
      bool
    >(
      selector: (state) {
        if (state.scheduleType == RecurringScheduleType.monthlyFixed) {
          return (state.monthDay ?? 0) > 28;
        }
        if (state.scheduleType == RecurringScheduleType.monthlyMultiple) {
          return state.monthDays.any((d) => d > 28);
        }
        return false;
      },
      builder: (context, showWarning) {
        if (!showWarning) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.amber.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Some months don't have this many days — "
                    'the transaction will be created on the '
                    'last day of those months instead.',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
