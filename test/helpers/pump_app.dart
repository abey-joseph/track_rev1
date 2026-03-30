import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:track/core/theme/app_theme.dart';

extension PumpApp on WidgetTester {
  Future<void> pumpApp(Widget widget) {
    return pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: widget,
      ),
    );
  }
}
