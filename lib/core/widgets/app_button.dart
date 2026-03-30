import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    required this.onPressed,
    required this.label,
    super.key,
    this.isLoading = false,
    this.icon,
    this.variant = AppButtonVariant.filled,
  });

  final VoidCallback? onPressed;
  final String label;
  final bool isLoading;
  final IconData? icon;
  final AppButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final child =
        isLoading
            ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
            : Text(label);

    return switch (variant) {
      AppButtonVariant.filled =>
        icon != null
            ? FilledButton.icon(
              onPressed: isLoading ? null : onPressed,
              icon: Icon(icon),
              label: child,
            )
            : FilledButton(
              onPressed: isLoading ? null : onPressed,
              child: child,
            ),
      AppButtonVariant.outlined =>
        icon != null
            ? OutlinedButton.icon(
              onPressed: isLoading ? null : onPressed,
              icon: Icon(icon),
              label: child,
            )
            : OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              child: child,
            ),
      AppButtonVariant.text =>
        icon != null
            ? TextButton.icon(
              onPressed: isLoading ? null : onPressed,
              icon: Icon(icon),
              label: child,
            )
            : TextButton(onPressed: isLoading ? null : onPressed, child: child),
    };
  }
}

enum AppButtonVariant { filled, outlined, text }
