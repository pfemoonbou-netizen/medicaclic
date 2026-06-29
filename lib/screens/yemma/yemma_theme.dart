import 'package:flutter/material.dart';

class YemmaColors {
  static const background = Color(0xFF0D1714);
  static const card = Color(0xFF132422);
  static const border = Color(0xFF1F3733);
  static const pink = Color(0xFFEC5A8D);
  static const green = Color(0xFF4CAF50);
  static const orange = Color(0xFFFFA726);
  static const red = Color(0xFFFF5C5C);
  static const blue = Color(0xFF5B8DEF);
  static const textPrimary = Colors.white;
  static const textSecondary = Colors.white60;
  static const textFaint = Colors.white38;

  static Color severityColor(int severity) {
    if (severity <= 4) return green;
    if (severity <= 7) return orange;
    return red;
  }
}
