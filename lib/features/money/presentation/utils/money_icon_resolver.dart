import 'package:flutter/material.dart';

/// Resolves a stored icon name string to a Material [IconData].
IconData resolveMoneyIcon(String iconName) {
  return _iconMap[iconName] ?? Icons.more_horiz;
}

const _iconMap = <String, IconData>{
  // Category icons
  'restaurant': Icons.restaurant,
  'directions_car': Icons.directions_car,
  'movie': Icons.movie,
  'shopping_bag': Icons.shopping_bag,
  'receipt_long': Icons.receipt_long,
  'favorite': Icons.favorite,
  'school': Icons.school,
  'more_horiz': Icons.more_horiz,
  'payments': Icons.payments,
  'work': Icons.work,
  'trending_up': Icons.trending_up,
  'card_giftcard': Icons.card_giftcard,

  // Account icons
  'account_balance_wallet': Icons.account_balance_wallet,
  'account_balance': Icons.account_balance,
  'credit_card': Icons.credit_card,
  'savings': Icons.savings,
};
