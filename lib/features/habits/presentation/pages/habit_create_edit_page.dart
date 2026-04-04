import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:track/core/extensions/context_extensions.dart';
import 'package:track/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:track/features/auth/presentation/bloc/auth_state.dart';
import 'package:track/features/habits/domain/entities/habit_entity.dart';
import 'package:track/features/habits/presentation/bloc/habit_form_bloc.dart';
import 'package:track/features/habits/presentation/bloc/habit_form_event.dart';
import 'package:track/features/habits/presentation/bloc/habit_form_state.dart';
import 'package:track/features/habits/presentation/utils/habit_icon_resolver.dart';
import 'package:track/injection.dart';

// Available colors for habit selection
const _habitColors = <String>[
  '#4CAF50',
  '#2196F3',
  '#FF9800',
  '#E91E63',
  '#9C27B0',
  '#00BCD4',
  '#FF5722',
  '#607D8B',
  '#795548',
  '#F44336',
  '#3F51B5',
  '#009688',
  '#FFC107',
  '#8BC34A',
  '#673AB7',
];

// Subset of icons for the picker grid
const _habitIcons = <String>[
  'check_circle',
  'fitness_center',
  'book',
  'water_drop',
  'bedtime',
  'self_improvement',
  'directions_run',
  'restaurant',
  'code',
  'brush',
  'music_note',
  'school',
  'timer',
  'eco',
  'favorite',
  'spa',
  'language',
  'psychology',
  'savings',
  'coffee',
  'hiking',
  'pool',
  'pets',
  'work',
];

const _weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

@RoutePage()
class HabitCreateEditPage extends StatelessWidget {
  const HabitCreateEditPage({super.key, this.habitId});

  final String? habitId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<HabitFormBloc>(),
      child: _HabitFormView(habitId: habitId),
    );
  }
}

class _HabitFormView extends StatelessWidget {
  const _HabitFormView({this.habitId});

  final String? habitId;

  @override
  Widget build(BuildContext context) {
    final isEditing = habitId != null;
    final colorScheme = context.colorScheme;

    return BlocListener<HabitFormBloc, HabitFormState>(
      listenWhen:
          (prev, curr) =>
              prev.isSuccess != curr.isSuccess ||
              prev.errorMessage != curr.errorMessage,
      listener: (context, state) {
        if (state.isSuccess) {
          HapticFeedback.mediumImpact();
          context.showSnackBar('Habit created!');
          context.router.maybePop();
        }
        if (state.errorMessage != null) {
          context.showSnackBar(state.errorMessage!, isError: true);
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: Text(isEditing ? 'Edit Habit' : 'New Habit'),
          centerTitle: true,
          actions: [
            BlocBuilder<HabitFormBloc, HabitFormState>(
              buildWhen:
                  (prev, curr) =>
                      prev.isSubmitting != curr.isSubmitting ||
                      prev.name != curr.name,
              builder: (context, state) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilledButton(
                    onPressed:
                        state.isSubmitting || state.name.trim().isEmpty
                            ? null
                            : () => _submit(context),
                    child:
                        state.isSubmitting
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Text('Save'),
                  ),
                );
              },
            ),
          ],
        ),
        body: const SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HabitPreviewHeader(),
              SizedBox(height: 28),
              _NameField(),
              SizedBox(height: 20),
              _DescriptionField(),
              SizedBox(height: 28),
              _IconColorSection(),
              SizedBox(height: 28),
              _FrequencySection(),
              SizedBox(height: 28),
              _TargetSection(),
              SizedBox(height: 28),
              _ReminderSection(),
            ],
          ),
        ),
      ),
    );
  }

  void _submit(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is Authenticated ? authState.user.uid : '';
    context.read<HabitFormBloc>().add(HabitFormEvent.submitted(userId: userId));
  }
}

// ── Live preview header ─────────────────────────────────────────────────────

class _HabitPreviewHeader extends StatelessWidget {
  const _HabitPreviewHeader();

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return BlocBuilder<HabitFormBloc, HabitFormState>(
      buildWhen:
          (prev, curr) =>
              prev.name != curr.name ||
              prev.iconName != curr.iconName ||
              prev.colorHex != curr.colorHex,
      builder: (context, state) {
        final color = _parseColor(state.colorHex);
        final icon = resolveHabitIcon(state.iconName);
        final name = state.name.isEmpty ? 'Your Habit' : state.name;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.15),
                color.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(icon, size: 30, color: Colors.white),
              ),
              const SizedBox(height: 14),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  name,
                  key: ValueKey(name),
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Name field ──────────────────────────────────────────────────────────────

class _NameField extends StatelessWidget {
  const _NameField();

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      onChanged:
          (value) => context.read<HabitFormBloc>().add(
            HabitFormEvent.nameChanged(name: value),
          ),
      decoration: InputDecoration(
        labelText: 'Habit Name',
        hintText: 'e.g. Morning Run, Read 30 min...',
        prefixIcon: const Icon(Icons.edit_rounded),
        filled: true,
        fillColor: context.colorScheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: context.colorScheme.primary,
            width: 1.5,
          ),
        ),
      ),
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.sentences,
      maxLength: 100,
    );
  }
}

// ── Description field ───────────────────────────────────────────────────────

class _DescriptionField extends StatelessWidget {
  const _DescriptionField();

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      onChanged:
          (value) => context.read<HabitFormBloc>().add(
            HabitFormEvent.descriptionChanged(description: value),
          ),
      decoration: InputDecoration(
        labelText: 'Description (optional)',
        hintText: 'Why is this habit important to you?',
        prefixIcon: const Icon(Icons.notes_rounded),
        filled: true,
        fillColor: context.colorScheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: context.colorScheme.primary,
            width: 1.5,
          ),
        ),
      ),
      maxLines: 2,
      textCapitalization: TextCapitalization.sentences,
    );
  }
}

// ── Icon & Color Picker ─────────────────────────────────────────────────────

class _IconColorSection extends StatelessWidget {
  const _IconColorSection();

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final colorScheme = context.colorScheme;

    return BlocBuilder<HabitFormBloc, HabitFormState>(
      buildWhen:
          (prev, curr) =>
              prev.iconName != curr.iconName || prev.colorHex != curr.colorHex,
      builder: (context, state) {
        final selectedColor = _parseColor(state.colorHex);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(
              title: 'Appearance',
              icon: Icons.palette_outlined,
            ),
            const SizedBox(height: 12),
            // Color picker
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Color',
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children:
                        _habitColors.map((hex) {
                          final color = _parseColor(hex);
                          final isSelected = hex == state.colorHex;
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              context.read<HabitFormBloc>().add(
                                HabitFormEvent.colorChanged(colorHex: hex),
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border:
                                    isSelected
                                        ? Border.all(
                                          color: colorScheme.onSurface,
                                          width: 2.5,
                                        )
                                        : null,
                                boxShadow:
                                    isSelected
                                        ? [
                                          BoxShadow(
                                            color: color.withValues(alpha: 0.4),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                        : null,
                              ),
                              child:
                                  isSelected
                                      ? const Icon(
                                        Icons.check_rounded,
                                        size: 18,
                                        color: Colors.white,
                                      )
                                      : null,
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Icon picker
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Icon',
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        _habitIcons.map((iconName) {
                          final icon = resolveHabitIcon(iconName);
                          final isSelected = iconName == state.iconName;
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              context.read<HabitFormBloc>().add(
                                HabitFormEvent.iconChanged(iconName: iconName),
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? selectedColor
                                        : colorScheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                icon,
                                size: 22,
                                color:
                                    isSelected
                                        ? Colors.white
                                        : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Frequency Section ───────────────────────────────────────────────────────

class _FrequencySection extends StatelessWidget {
  const _FrequencySection();

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return BlocBuilder<HabitFormBloc, HabitFormState>(
      buildWhen:
          (prev, curr) =>
              prev.frequencyType != curr.frequencyType ||
              prev.frequencyDays != curr.frequencyDays ||
              prev.colorHex != curr.colorHex,
      builder: (context, state) {
        final accentColor = _parseColor(state.colorHex);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(
              title: 'Frequency',
              icon: Icons.calendar_today_outlined,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Segmented button for frequency type
                  SegmentedButton<HabitFrequency>(
                    segments: const [
                      ButtonSegment(
                        value: HabitFrequency.daily,
                        label: Text('Daily'),
                        icon: Icon(Icons.repeat_rounded, size: 18),
                      ),
                      ButtonSegment(
                        value: HabitFrequency.weekly,
                        label: Text('Weekly'),
                        icon: Icon(Icons.view_week_rounded, size: 18),
                      ),
                      ButtonSegment(
                        value: HabitFrequency.custom,
                        label: Text('Custom'),
                        icon: Icon(Icons.tune_rounded, size: 18),
                      ),
                    ],
                    selected: {state.frequencyType},
                    onSelectionChanged: (selected) {
                      HapticFeedback.selectionClick();
                      context.read<HabitFormBloc>().add(
                        HabitFormEvent.frequencyChanged(
                          frequency: selected.first,
                        ),
                      );
                    },
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  // Day selector for custom frequency
                  if (state.frequencyType == HabitFrequency.custom) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Select days',
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(7, (i) {
                        final weekday = i + 1; // 1=Mon, 7=Sun
                        final isSelected = state.frequencyDays.contains(
                          weekday,
                        );
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            context.read<HabitFormBloc>().add(
                              HabitFormEvent.dayToggled(weekday: weekday),
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color:
                                  isSelected ? accentColor : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    isSelected
                                        ? accentColor
                                        : colorScheme.outline.withValues(
                                          alpha: 0.3,
                                        ),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _weekdayLabels[i],
                                style: textTheme.labelLarge?.copyWith(
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : colorScheme.onSurfaceVariant,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
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
            ),
          ],
        );
      },
    );
  }
}

// ── Target Section ──────────────────────────────────────────────────────────

class _TargetSection extends StatelessWidget {
  const _TargetSection();

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return BlocBuilder<HabitFormBloc, HabitFormState>(
      buildWhen:
          (prev, curr) =>
              prev.targetValue != curr.targetValue ||
              prev.targetUnit != curr.targetUnit ||
              prev.targetType != curr.targetType,
      builder: (context, state) {
        final isQuantitative = state.targetValue > 1.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(title: 'Goal', icon: Icons.flag_outlined),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Toggle between simple/quantitative
                  Row(
                    children: [
                      Expanded(
                        child: _GoalTypeChip(
                          label: 'Yes / No',
                          subtitle: 'Just check it off',
                          icon: Icons.check_circle_outline_rounded,
                          isSelected: !isQuantitative,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            context.read<HabitFormBloc>().add(
                              const HabitFormEvent.targetValueChanged(
                                targetValue: 1,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _GoalTypeChip(
                          label: 'Measurable',
                          subtitle: 'Track a quantity',
                          icon: Icons.bar_chart_rounded,
                          isSelected: isQuantitative,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            if (!isQuantitative) {
                              context.read<HabitFormBloc>().add(
                                const HabitFormEvent.targetValueChanged(
                                  targetValue: 10,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  if (isQuantitative) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _GoalTypeChip(
                            label: 'At least',
                            subtitle: 'Minimum target',
                            icon: Icons.arrow_upward_rounded,
                            isSelected:
                                state.targetType == HabitTargetType.min,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              context.read<HabitFormBloc>().add(
                                const HabitFormEvent.targetTypeChanged(
                                  targetType: HabitTargetType.min,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _GoalTypeChip(
                            label: 'At most',
                            subtitle: 'Maximum target',
                            icon: Icons.arrow_downward_rounded,
                            isSelected:
                                state.targetType == HabitTargetType.max,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              context.read<HabitFormBloc>().add(
                                const HabitFormEvent.targetTypeChanged(
                                  targetType: HabitTargetType.max,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: state.targetValue.toStringAsFixed(
                              state.targetValue ==
                                      state.targetValue.roundToDouble()
                                  ? 0
                                  : 1,
                            ),
                            onChanged: (value) {
                              final parsed = double.tryParse(value);
                              if (parsed != null && parsed > 0) {
                                context.read<HabitFormBloc>().add(
                                  HabitFormEvent.targetValueChanged(
                                    targetValue: parsed,
                                  ),
                                );
                              }
                            },
                            decoration: InputDecoration(
                              labelText: 'Target',
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHigh,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textAlign: TextAlign.center,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            initialValue: state.targetUnit,
                            onChanged:
                                (value) => context.read<HabitFormBloc>().add(
                                  HabitFormEvent.targetUnitChanged(
                                    targetUnit: value,
                                  ),
                                ),
                            decoration: InputDecoration(
                              labelText: 'Unit',
                              hintText: 'e.g. min, glasses, pages',
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHigh,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GoalTypeChip extends StatelessWidget {
  const _GoalTypeChip({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
          border:
              isSelected
                  ? Border.all(color: colorScheme.primary, width: 1.5)
                  : Border.all(color: Colors.transparent),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 26,
              color:
                  isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reminder Section ────────────────────────────────────────────────────────

class _ReminderSection extends StatelessWidget {
  const _ReminderSection();

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return BlocBuilder<HabitFormBloc, HabitFormState>(
      buildWhen:
          (prev, curr) =>
              prev.reminderEnabled != curr.reminderEnabled ||
              prev.reminderTime != curr.reminderTime,
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(
              title: 'Reminder',
              icon: Icons.notifications_outlined,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text('Daily Reminder', style: textTheme.bodyLarge),
                    subtitle: Text(
                      state.reminderEnabled
                          ? 'Reminds you at ${state.reminderTime}'
                          : 'Get notified to stay on track',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    value: state.reminderEnabled,
                    onChanged: (_) {
                      HapticFeedback.selectionClick();
                      context.read<HabitFormBloc>().add(
                        const HabitFormEvent.reminderToggled(),
                      );
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  if (state.reminderEnabled) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _pickTime(context, state.reminderTime),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(12),
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
                                state.reminderTime,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickTime(BuildContext context, String currentTime) async {
    final parts = currentTime.split(':');
    final hour = int.tryParse(parts[0]) ?? 8;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
    );

    if (picked != null && context.mounted) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      context.read<HabitFormBloc>().add(
        HabitFormEvent.reminderTimeChanged(reminderTime: formatted),
      );
    }
  }
}

// ── Shared section header ───────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final colorScheme = context.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

// ── Helpers ─────────────────────────────────────────────────────────────────

Color _parseColor(String hex) {
  final buffer = StringBuffer();
  final cleaned = hex.startsWith('#') ? hex.substring(1) : hex;
  if (cleaned.length == 6) buffer.write('FF');
  buffer.write(cleaned);
  return Color(int.parse(buffer.toString(), radix: 16));
}
