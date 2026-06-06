import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────
//  VIBRANT CANDY / WORKSHOP COLOR PALETTE
// ─────────────────────────────────────────────
class AppColors {
  AppColors._();

  // Backgrounds
  static const Color scaffoldBg = Color(0xFFF5F0E8); // warm parchment
  static const Color boardBg = Color(0xFFEDE8DC);
  static const Color gridLine = Color(0xFFD4CFC4);

  // Plate colors (bright, candy-transparent)
  static const Color plateCyan = Color(0xFF00D4FF);
  static const Color plateLime = Color(0xFF7FE620);
  static const Color plateYellow = Color(0xFFFFD600);
  static const Color plateRuby = Color(0xFFFF2D55);
  static const Color plateOrange = Color(0xFFFF6B00);
  static const Color platePurple = Color(0xFFAA44FF);

  static const List<Color> plateColors = [
    plateCyan,
    plateLime,
    plateYellow,
    plateRuby,
    plateOrange,
    platePurple,
  ];

  // Screw colors
  static const Color screwGold = Color(0xFFFFD166);
  static const Color screwSilver = Color(0xFFCDD9E5);
  static const Color screwRoseGold = Color(0xFFFFB4A2);

  // UI colors
  static const Color primaryAccent = Color(0xFF3D5AFE);
  static const Color levelBadge = Color(0xFFFF6B35);
  static const Color hintGlow = Color(0xFFFFD166);
  static const Color successGreen = Color(0xFF06D6A0);
  static const Color dangerRed = Color(0xFFEF476F);

  // Board frame
  static const Color walnutFrame = Color(0xFF6B3F2A);
  static const Color walnutFrameLight = Color(0xFF8B5A3C);
  static const Color steelBase = Color(0xFFC8D4DC);
  static const Color steelBaseDark = Color(0xFFAABBCC);

  // Hole colors
  static const Color holeEmpty = Color(0xFFB0BAC8);
  static const Color holeFilled = Color(0xFF7A8BA0);
}

// ─────────────────────────────────────────────
//  TEXT STYLES
// ─────────────────────────────────────────────
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get displayLarge => GoogleFonts.rajdhani(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.walnutFrame,
        letterSpacing: 1.5,
      );

  static TextStyle get levelLabel => GoogleFonts.rajdhani(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: 1.2,
      );

  static TextStyle get hintCounter => GoogleFonts.shareTechMono(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.hintGlow,
      );

  static TextStyle get movesCounter => GoogleFonts.shareTechMono(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.walnutFrame,
      );

  static TextStyle get bodyMedium => GoogleFonts.nunito(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.walnutFrame,
      );
}

// ─────────────────────────────────────────────
//  APP THEME
// ─────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryAccent,
          brightness: Brightness.light,
          surface: AppColors.scaffoldBg,
        ),
        scaffoldBackgroundColor: AppColors.scaffoldBg,
        textTheme: GoogleFonts.nunitoTextTheme(),
      );
}
