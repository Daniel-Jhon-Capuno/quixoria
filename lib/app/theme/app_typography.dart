import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  // Warm, friendly literary typography (Lora: rounded, soft, approachable serif)
  static TextStyle displayLarge = GoogleFonts.lora(
    fontSize: 30,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.2,
  );

  static TextStyle displayMedium = GoogleFonts.lora(
    fontSize: 25,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.1,
  );

  static TextStyle displaySmall = GoogleFonts.lora(
    fontSize: 21,
    fontWeight: FontWeight.w700,
  );

  static TextStyle titleLarge = GoogleFonts.lora(
    fontSize: 19,
    fontWeight: FontWeight.w700,
  );

  static TextStyle titleMedium = GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static TextStyle titleSmall = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  // Body text for reading and UI controls
  static TextStyle bodyLarge = GoogleFonts.lora(
    fontSize: 18.5,
    fontWeight: FontWeight.w500,
    height: 1.65,
  );

  static TextStyle bodyMedium = GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static TextStyle bodySmall = GoogleFonts.plusJakartaSans(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    height: 1.4,
  );

  static TextStyle labelLarge = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );

  static TextStyle labelMedium = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  static TextStyle labelSmall = GoogleFonts.plusJakartaSans(
    fontSize: 11,
    fontWeight: FontWeight.w600,
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
