import 'package:flutter/material.dart';

abstract class AppColors {
  // Primary seed color for Material 3 color scheme generation
  static const Color primarySeed = Color(0xFF6750A4);

  // Semantic colors (used directly when ColorScheme isn't enough)
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
}
