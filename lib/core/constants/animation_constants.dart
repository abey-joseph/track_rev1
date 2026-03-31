import 'package:flutter/animation.dart';

abstract class AnimationConstants {
  // Durations
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration defaultDuration = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 600);
  static const Duration staggerDelay = Duration(milliseconds: 50);

  // Curves
  static const Curve defaultCurve = Curves.easeInOutCubic;
  static const Curve enterCurve = Curves.easeOutCubic;
  static const Curve exitCurve = Curves.easeInCubic;
}
