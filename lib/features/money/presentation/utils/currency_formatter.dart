/// Formats an amount in cents to a display string.
///
/// Example: `formatCents(4250)` → `"42.50"`
String formatCents(int cents) {
  final isNegative = cents < 0;
  final abs = cents.abs();
  final dollars = abs ~/ 100;
  final remaining = abs % 100;
  final formatted = '$dollars.${remaining.toString().padLeft(2, '0')}';
  return isNegative ? '-$formatted' : formatted;
}

/// Formats cents with a currency symbol prefix.
///
/// Example: `formatCurrency(4250)` → `"\$42.50"`
String formatCurrency(int cents, {String symbol = r'$'}) {
  return '$symbol${formatCents(cents)}';
}
