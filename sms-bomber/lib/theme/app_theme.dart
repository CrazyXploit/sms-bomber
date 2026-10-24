import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const bg = Color(0xFF0B0E14);
  static const bgAlt = Color(0xFF11151E);
  static const surface = Color(0xFF161B26);
  static const surfaceHi = Color(0xFF1E2432);
  static const accent = Color(0xFF00E5FF);
  static const accentDim = Color(0xFF00A8BC);
  static const danger = Color(0xFFFF2D6F);
  static const violet = Color(0xFF7C6BFF);
  static const text = Color(0xFFE8EDF5);
  static const textDim = Color(0xFF8A93A6);
  static const success = Color(0xFF33E38A);
  static const border = Color(0xFF232A38);
}

class AppTheme {
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      textTheme: textTheme,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.accent,
        secondary: AppColors.violet,
        error: AppColors.danger,
        surface: AppColors.surface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceHi,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.4),
        ),
        labelStyle: const TextStyle(color: AppColors.textDim, fontSize: 13),
        hintStyle: const TextStyle(color: AppColors.textDim),
      ),
    );
  }
}