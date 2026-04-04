import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:track/core/constants/animation_constants.dart';

class QuickAddFab extends StatefulWidget {
  const QuickAddFab({
    required this.onLogHabit,
    required this.onAddTransaction,
    super.key,
    this.showSpeedDial = true,
  });

  final VoidCallback onLogHabit;
  final VoidCallback onAddTransaction;

  /// When false, single tap triggers [onAddTransaction] directly (Money tab).
  final bool showSpeedDial;

  @override
  State<QuickAddFab> createState() => _QuickAddFabState();
}

class _QuickAddFabState extends State<QuickAddFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AnimationConstants.defaultDuration,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (!widget.showSpeedDial) {
      HapticFeedback.lightImpact();
      widget.onAddTransaction();
      return;
    }
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        HapticFeedback.lightImpact();
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _close() {
    if (_isOpen) {
      setState(() {
        _isOpen = false;
        _controller.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return OverflowBox(
      maxWidth: 300,
      maxHeight: 350,
      alignment: Alignment.bottomRight,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // Scrim
          if (_isOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _close,
                behavior: HitTestBehavior.opaque,
              ),
            ),

          // Speed-dial options
          if (widget.showSpeedDial)
            IgnorePointer(
              ignoring: !_isOpen,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  // Log Habit option
                  _SpeedDialOption(
                    controller: _controller,
                    index: 1,
                    icon: Icons.check_circle_outline,
                    label: 'Log Habit',
                    onTap: () {
                      _close();
                      widget.onLogHabit();
                    },
                  ),
                  // Add Transaction option
                  _SpeedDialOption(
                    controller: _controller,
                    index: 0,
                    icon: Icons.receipt_long_outlined,
                    label: 'Add Transaction',
                    onTap: () {
                      _close();
                      widget.onAddTransaction();
                    },
                  ),
                ],
              ),
            ),

          // Main FAB
          Positioned(
            bottom: 0,
            right: 0,
            child: FloatingActionButton(
              onPressed: _toggle,
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _controller.value * math.pi / 4,
                    child: const Icon(Icons.add, size: 28),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeedDialOption extends StatelessWidget {
  const _SpeedDialOption({
    required this.controller,
    required this.index,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final AnimationController controller;
  final int index;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final delay = index * 0.15;
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(delay, delay + 0.6, curve: AnimationConstants.enterCurve),
    );

    final bottomOffset = 64.0 + (index + 1) * 56.0;

    return Positioned(
      bottom: bottomOffset,
      right: 4,
      child: FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.5),
            end: Offset.zero,
          ).animate(animation),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(8),
                color: colorScheme.surfaceContainer,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Text(
                      label,
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FloatingActionButton.small(
                heroTag: 'speed_dial_$index',
                onPressed: onTap,
                backgroundColor: colorScheme.secondaryContainer,
                foregroundColor: colorScheme.onSecondaryContainer,
                child: Icon(icon),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
