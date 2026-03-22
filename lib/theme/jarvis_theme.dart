import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class JarvisTheme {
  // Core Palette — Iron Man / Arc Reactor inspired
  static const Color bgDeep = Color(0xFF020B18);
  static const Color bgCard = Color(0xFF071A2E);
  static const Color bgSurface = Color(0xFF0D2137);
  static const Color arcBlue = Color(0xFF00D4FF);
  static const Color arcBlueDim = Color(0xFF0087A8);
  static const Color arcGlow = Color(0xFF00F5FF);
  static const Color goldAccent = Color(0xFFFFB300);
  static const Color redAlert = Color(0xFFFF3D3D);
  static const Color textPrimary = Color(0xFFE8F4FD);
  static const Color textSecondary = Color(0xFF7FB3CC);
  static const Color textDim = Color(0xFF3A6278);
  static const Color divider = Color(0xFF0F2D42);

  static ThemeData get theme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bgDeep,
        colorScheme: const ColorScheme.dark(
          primary: arcBlue,
          secondary: goldAccent,
          surface: bgCard,
          error: redAlert,
        ),
        textTheme: GoogleFonts.rajdhaniTextTheme(
          const TextTheme(
            displayLarge: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: textPrimary,
              letterSpacing: 4,
            ),
            titleLarge: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: arcBlue,
              letterSpacing: 2,
            ),
            bodyLarge: TextStyle(
              fontSize: 16,
              color: textPrimary,
              letterSpacing: 0.5,
            ),
            bodyMedium: TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
          ),
        ),
        useMaterial3: true,
      );
}
