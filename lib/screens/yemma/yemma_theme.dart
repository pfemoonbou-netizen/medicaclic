import 'package:flutter/material.dart';

class YemmaColors {
  // Thème clair rose/corail (maquette maternité)
  static const background = Color(0xFFFFF5F4);
  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFFF3D9D7);
  static const pink = Color(0xFFF4716A); // corail
  static const green = Color(0xFF3FB27F);
  static const orange = Color(0xFFF2994A);
  static const red = Color(0xFFFF5C5C);
  static const blue = Color(0xFF5B8DEF);
  static const textPrimary = Color(0xFF2E2A2B);
  static const textSecondary = Color(0xFF6B5E5E);
  static const textFaint = Color(0xFFA99C9C);

  static Color severityColor(int severity) {
    if (severity <= 4) return green;
    if (severity <= 7) return orange;
    return red;
  }
}
