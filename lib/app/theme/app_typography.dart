import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  // Duolingo-inspired rounded, plump, friendly typography (Nunito) with clear visual hierarchy:
  // Display (w900) -> Title (w800/w700) -> Body (w600) -> Label (w800)
  static TextStyle displayLarge = GoogleFonts.nunito(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.4,
    height: 1.18,
  );

  static TextStyle displayMedium = GoogleFonts.nunito(
    fontSize: 26,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.3,
    height: 1.22,
  );

  static TextStyle displaySmall = GoogleFonts.nunito(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
    height: 1.25,
  );

  static TextStyle titleLarge = GoogleFonts.nunito(
    fontSize: 19,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.1,
    height: 1.28,
  );

  static TextStyle titleMedium = GoogleFonts.nunito(
    fontSize: 16.5,
    fontWeight: FontWeight.w800,
    height: 1.32,
  );

  static TextStyle titleSmall = GoogleFonts.nunito(
    fontSize: 14.5,
    fontWeight: FontWeight.w700,
    height: 1.35,
  );

  // Healthy, easy-to-read body text (w600 so UI never looks thin or spindly)
  static TextStyle bodyLarge = GoogleFonts.nunito(
    fontSize: 17.5,
    fontWeight: FontWeight.w600,
    height: 1.55,
  );

  static TextStyle bodyMedium = GoogleFonts.nunito(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.45,
  );

  static TextStyle bodySmall = GoogleFonts.nunito(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.38,
  );

  static TextStyle labelLarge = GoogleFonts.nunito(
    fontSize: 14.5,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.25,
  );

  static TextStyle labelMedium = GoogleFonts.nunito(
    fontSize: 12.5,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.3,
  );

  static TextStyle labelSmall = GoogleFonts.nunito(
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.4,
  );

  static TextStyle quote = GoogleFonts.lora(
    fontSize: 16.5,
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.w500,
    height: 1.55,
  );

  // Accessible Dyslexia-Friendly Typography (Lexend scale)
  static TextStyle dyslexicHeading = GoogleFonts.lexend(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
    height: 1.4,
  );

  static TextStyle dyslexicBody = GoogleFonts.lexend(
    fontSize: 17,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.8,
    wordSpacing: 2.0,
    height: 1.8,
  );

  static TextStyle getReadingBodyStyle({
    required bool isDyslexic,
    required double fontSize,
    Color? color,
    FontWeight? fontWeight,
  }) {
    if (isDyslexic) {
      return GoogleFonts.lexend(
        fontSize: fontSize,
        fontWeight: fontWeight ?? FontWeight.w400,
        color: color ?? AppColors.inkDark,
        letterSpacing: 0.8,
        wordSpacing: 2.0,
        height: 1.85,
      );
    }
    return GoogleFonts.lora(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.w500,
      color: color ?? AppColors.inkDark,
      letterSpacing: 0.15,
      wordSpacing: 1.2,
      height: 1.75,
    );
  }
}
