import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BeatCheckColors {
  static const Color black = Color(0xFF0B0B0B);
  static const Color white = Color(0xFFFFFFFF);
  static const Color acidGreen = Color(0xFFC7FF00);
  static const Color warmGray = Color(0xFFCFCFCF);
  static const Color darkGray = Color(0xFF1A1A1A);
}

class BeatCheckMetrics {
  static const double borderWidth = 4;
  static const double cornerRadius = 4;
  static const Offset shadowOffset = Offset(8, 8);
}

class BeatCheckTheme {
  static ThemeData get theme {
    final baseTextTheme = GoogleFonts.spaceGroteskTextTheme(
      ThemeData.dark().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: BeatCheckColors.black,
      colorScheme: const ColorScheme.dark().copyWith(
        primary: BeatCheckColors.acidGreen,
        secondary: BeatCheckColors.white,
        surface: BeatCheckColors.white,
        onPrimary: BeatCheckColors.black,
        onSecondary: BeatCheckColors.black,
        onSurface: BeatCheckColors.black,
      ),
      textTheme: baseTextTheme.copyWith(
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: BeatCheckColors.warmGray,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: BeatCheckColors.warmGray,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: BeatCheckColors.warmGray,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
