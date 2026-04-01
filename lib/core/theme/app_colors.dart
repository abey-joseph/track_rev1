import 'package:flutter/material.dart';

abstract class AppColors {
  // Primary seed color for Material 3 color scheme generation
  static const Color primarySeed = Color(0xFF31473A); // Dark forest green

  // Brand palette
  static const Color forestGreen = Color(0xFF31473A);
  static const Color olive = Color(0xFF7C8363);
  static const Color sage = Color(0xFFEDF4F2);

  // Semantic colors (used directly when ColorScheme isn't enough)
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
}
