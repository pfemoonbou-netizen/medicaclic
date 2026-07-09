import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

// ── Spacing scale (4dp base grid) ────────────────────────────────────────────
abstract class AppSpacing {
  static const xs  = 4.0;
  static const sm  = 8.0;
  static const md  = 12.0;
  static const lg  = 16.0;
  static const xl  = 20.0;
  static const xxl = 24.0;
  static const x3l = 32.0;
  static const x4l = 40.0;
  static const x5l = 48.0;
  static const x6l = 64.0;
}

// ── Border radius ─────────────────────────────────────────────────────────────
abstract class AppRadius {
  static const xs   = Radius.circular(4);
  static const sm   = Radius.circular(8);
  static const md   = Radius.circular(12);
  static const lg   = Radius.circular(16);
  static const xl   = Radius.circular(20);
  static const xxl  = Radius.circular(24);
  static const x3l  = Radius.circular(32);
  static const full = Radius.circular(999);

  static const smAll   = BorderRadius.all(sm);
  static const mdAll   = BorderRadius.all(md);
  static const lgAll   = BorderRadius.all(lg);
  static const xlAll   = BorderRadius.all(xl);
  static const xxlAll  = BorderRadius.all(xxl);
  static const fullAll = BorderRadius.all(full);
}

// ── Shadow system ─────────────────────────────────────────────────────────────
abstract class AppShadows {
  static List<BoxShadow> get soft => [
    BoxShadow(
      color: AppColors.nearBlack.withValues(alpha: 0.05),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get card => [
    BoxShadow(
      color: AppColors.nearBlack.withValues(alpha: 0.07),
      blurRadius: 24,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: AppColors.nearBlack.withValues(alpha: 0.03),
      blurRadius: 6,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get strong => [
    BoxShadow(
      color: AppColors.nearBlack.withValues(alpha: 0.14),
      blurRadius: 32,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get accent => [
    BoxShadow(
      color: AppColors.accent.withValues(alpha: 0.32),
      blurRadius: 22,
      offset: const Offset(0, 6),
      spreadRadius: -2,
    ),
  ];

  static List<BoxShadow> get brand => [
    BoxShadow(
      color: AppColors.blue.withValues(alpha: 0.28),
      blurRadius: 20,
      offset: const Offset(0, 6),
      spreadRadius: -2,
    ),
  ];
}

// ── Typography scale ──────────────────────────────────────────────────────────
abstract class AppText {
  static TextStyle display({Color? color, FontWeight w = FontWeight.w900}) =>
      GoogleFonts.montserrat(
        fontSize: 40, fontWeight: w, height: 1.1,
        letterSpacing: -0.8,
        color: color ?? AppColors.nearBlack);

  static TextStyle h1({Color? color, FontWeight w = FontWeight.w800}) =>
      GoogleFonts.montserrat(
        fontSize: 32, fontWeight: w, height: 1.15,
        letterSpacing: -0.5,
        color: color ?? AppColors.nearBlack);

  static TextStyle h2({Color? color, FontWeight w = FontWeight.w800}) =>
      GoogleFonts.montserrat(
        fontSize: 26, fontWeight: w, height: 1.2,
        letterSpacing: -0.3,
        color: color ?? AppColors.nearBlack);

  static TextStyle h3({Color? color, FontWeight w = FontWeight.w700}) =>
      GoogleFonts.montserrat(
        fontSize: 20, fontWeight: w, height: 1.3,
        color: color ?? AppColors.nearBlack);

  static TextStyle title({Color? color, FontWeight w = FontWeight.w700}) =>
      GoogleFonts.montserrat(
        fontSize: 17, fontWeight: w, height: 1.35,
        color: color ?? AppColors.nearBlack);

  static TextStyle body({Color? color, FontWeight w = FontWeight.w400}) =>
      GoogleFonts.montserrat(
        fontSize: 14, fontWeight: w, height: 1.55,
        color: color ?? AppColors.nearBlack);

  static TextStyle bodyMd({Color? color, FontWeight w = FontWeight.w500}) =>
      GoogleFonts.montserrat(
        fontSize: 14, fontWeight: w, height: 1.5,
        color: color ?? AppColors.nearBlack);

  static TextStyle bodySmall({Color? color, FontWeight w = FontWeight.w400}) =>
      GoogleFonts.montserrat(
        fontSize: 13, fontWeight: w, height: 1.5,
        color: color ?? AppColors.nearBlack);

  static TextStyle label({Color? color, FontWeight w = FontWeight.w600}) =>
      GoogleFonts.montserrat(
        fontSize: 12, fontWeight: w, height: 1.4,
        color: color ?? AppColors.gray);

  static TextStyle caption({Color? color, FontWeight w = FontWeight.w400}) =>
      GoogleFonts.montserrat(
        fontSize: 11, fontWeight: w, height: 1.4,
        color: color ?? AppColors.grayLight);

  static TextStyle overline({Color? color, FontWeight w = FontWeight.w700}) =>
      GoogleFonts.montserrat(
        fontSize: 10, fontWeight: w, letterSpacing: 1.4,
        height: 1.4,
        color: color ?? AppColors.grayLight);

  static TextStyle button({Color? color}) =>
      GoogleFonts.montserrat(
        fontSize: 15, fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
        color: color ?? AppColors.nearBlack);
}

// ── Duration constants ────────────────────────────────────────────────────────
abstract class AppDuration {
  static const fast   = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 250);
  static const slow   = Duration(milliseconds: 400);
  static const page   = Duration(milliseconds: 300);
}
