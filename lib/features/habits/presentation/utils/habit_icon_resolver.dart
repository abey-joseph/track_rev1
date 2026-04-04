import 'package:flutter/material.dart';

/// Resolves a stored icon name string to a Material [IconData].
IconData resolveHabitIcon(String iconName) {
  return _iconMap[iconName] ?? Icons.check_circle;
}

const _iconMap = <String, IconData>{
  'check_circle': Icons.check_circle,
  'fitness_center': Icons.fitness_center,
  'book': Icons.book,
  'water_drop': Icons.water_drop,
  'bedtime': Icons.bedtime,
  'self_improvement': Icons.self_improvement,
  'directions_run': Icons.directions_run,
  'restaurant': Icons.restaurant,
  'code': Icons.code,
  'brush': Icons.brush,
  'music_note': Icons.music_note,
  'school': Icons.school,
  'smoking_rooms': Icons.smoking_rooms,
  'local_pharmacy': Icons.local_pharmacy,
  'pets': Icons.pets,
  'cleaning_services': Icons.cleaning_services,
  'shopping_cart': Icons.shopping_cart,
  'phone_android': Icons.phone_android,
  'timer': Icons.timer,
  'eco': Icons.eco,
  'favorite': Icons.favorite,
  'spa': Icons.spa,
  'language': Icons.language,
  'psychology': Icons.psychology,
  'savings': Icons.savings,
  'work': Icons.work,
  'coffee': Icons.coffee,
  'lunch_dining': Icons.lunch_dining,
  'hiking': Icons.hiking,
  'pool': Icons.pool,
};
