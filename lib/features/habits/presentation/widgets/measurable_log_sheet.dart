import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:track/core/extensions/context_extensions.dart';
import 'package:track/features/habits/domain/entities/habit_entity.dart';

/// Result from [MeasurableLogSheet].
/// If [delete] is true the caller should remove the log.
/// Otherwise [value] holds the entered amount.
typedef MeasurableLogResult = ({double? value, bool delete});

/// Bottom sheet that lets the user enter a numeric value for a measurable habit.
class MeasurableLogSheet extends StatefulWidget {
  const MeasurableLogSheet({
    required this.habitName,
    required this.targetValue,
    this.targetUnit,
    this.targetType = HabitTargetType.min,
    this.currentValue,
    super.key,
  });

  final String habitName;
  final double targetValue;
  final String? targetUnit;
  final HabitTargetType targetType;

  /// Non-null when editing an existing log.
  final double? currentValue;

  @override
  State<MeasurableLogSheet> createState() => _MeasurableLogSheetState();
}

class _MeasurableLogSheetState extends State<MeasurableLogSheet> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  bool get _isEditing => widget.currentValue != null;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: _isEditing ? _formatNumber(widget.currentValue!) : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatNumber(double v) {
    return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final unit = widget.targetUnit ?? '';

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            widget.habitName,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),

          // Target info
          Text(
            'Target: ${widget.targetType == HabitTargetType.min ? 'at least' : 'at most'} ${_formatNumber(widget.targetValue)}${unit.isNotEmpty ? ' $unit' : ''}',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 20),

          // Input
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: InputDecoration(
                labelText: unit.isNotEmpty ? 'Amount ($unit)' : 'Amount',
                hintText: 'e.g. ${_formatNumber(widget.targetValue)}',
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter a value';
                final parsed = double.tryParse(v.trim());
                if (parsed == null || parsed < 0) return 'Enter a valid number';
                return null;
              },
              onFieldSubmitted: (_) => _onSave(),
            ),
          ),
          const SizedBox(height: 20),

          // Buttons
          Row(
            children: [
              if (_isEditing)
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pop<MeasurableLogResult>((value: null, delete: true));
                  },
                  child: Text(
                    'Delete',
                    style: TextStyle(color: colorScheme.error),
                  ),
                ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _onSave,
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;
    final value = double.parse(_controller.text.trim());
    Navigator.of(
      context,
    ).pop<MeasurableLogResult>((value: value, delete: false));
  }
}
