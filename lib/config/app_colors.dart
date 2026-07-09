import 'package:flutter/material.dart';

abstract class AppColors {
  // ── Brand darks ───────────────────────────────────────────────────────────
  static const nearBlack  = Color(0xFF0D0B2D);
  static const dark       = Color(0xFF0A0F2C);

  // ── Brand accents ─────────────────────────────────────────────────────────
  static const accent     = Color(0xFF00D4FF);
  static const blue       = Color(0xFF3B82F6);
  static const purple     = Color(0xFFA855F7);
  static const deepPurple = Color(0xFF7C3AED);

  // ── Solid hero blue (flat background, no pattern) ───────────────────────────
  static const heroBlue = Color(0xFF2F5FF6);

  // ── Surfaces ──────────────────────────────────────────────────────────────
  static const surface    = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF6F8FC);
  static const surfaceSub = Color(0xFFF0F2FA);

  // ── Neutrals ──────────────────────────────────────────────────────────────
  static const gray      = Color(0xFF667085);
  static const grayLight = Color(0xFF9EA3B8);
  static const lightGray = Color(0xFFE7E9F3);
  static const bgGray    = Color(0xFFF6F8FC);
  static const nearWhite = Color(0xFFFDFDFD);

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const error   = Color(0xFFE53935);
  static const success = Color(0xFF26C860);
  static const warning = Color(0xFFFFB300);

  // ── Utility ───────────────────────────────────────────────────────────────
  static const gold = Color(0xFFFFC107);

  // ── Gradients ─────────────────────────────────────────────────────────────
  // Dégradé principal from the brand charte: cyan → purple
  static const brandGradient = LinearGradient(
    colors: [accent, purple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const darkGradient = LinearGradient(
    colors: [nearBlack, dark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const purpleGradient = LinearGradient(
    colors: [purple, deepPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const accentGlow = LinearGradient(
    colors: [accent, blue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
