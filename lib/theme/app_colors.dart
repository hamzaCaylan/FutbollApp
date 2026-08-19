import 'package:flutter/material.dart';

/// Shared brand color palette - the single source of truth for colors used
/// across the app's theme, dark surfaces, and the pitch's drawing tools.
class AppColors {
  const AppColors._();

  // --- Brand -----------------------------------------------------------
  static const Color offWhite = Color(0xFFF5F5F5);
  static const Color charcoal = Color(0xFF2A2727);
  static const Color red = Color(0xFFD41314);
  static const Color taupe = Color(0xFFC7BEBE);

  // --- App surfaces ------------------------------------------------------
  /// The base app scaffold background (Dashboard/Players/Settings/Help).
  static const Color appBackground = Color(0xFF121212);

  /// The pitch screen's own scaffold background.
  static const Color pitchBackground = Color(0xFF11151A);

  /// The dashboard content area's background.
  static const Color dashboardBackground = Color(0xFF0B0F0D);

  /// The most common dark panel/rail/toolbar surface (left rail, side
  /// panels, top bar, toast, bench, waypoint bar, ball-path controls).
  static const Color panelDark = Color(0xFF0E1210);

  /// A slightly lighter dark surface used for secondary dashboard cards
  /// and the transfer list panel.
  static const Color surfaceDark = Color(0xFF161B18);
  static const Color cardDark = Color(0xFF1A1F1C);

  /// The light "Browse" panel background on the dashboard.
  static const Color lightPanel = Color(0xFFEDEDED);

  /// Fallback grass color behind the pitch image.
  static const Color pitchGrass = Color(0xFF2E7D32);

  /// Default home/away team ring colors.
  static const Color teamHomeDefault = Color(0xFF1A1A1A);
  static const Color teamAwayDefault = red;

  // --- Drawing tool palette ----------------------------------------------
  /// The color swatches offered by the pitch's drawing color picker, and
  /// [drawYellow] doubles as the default drawing color.
  static const Color drawYellow = Color(0xFFFFD54F);
  static const Color drawRed = Color(0xFFEF5350);
  static const Color drawBlue = Color(0xFF42A5F5);
  static const Color drawGreen = Color(0xFF66BB6A);
  static const Color drawWhite = Color(0xFFFFFFFF);
  static const Color drawOrange = Color(0xFFFF9800);

  static const List<Color> drawingPalette = [
    drawYellow,
    drawRed,
    drawBlue,
    drawGreen,
    drawWhite,
    drawOrange,
  ];

  // --- Heat map gradient ---------------------------------------------------
  static const Color heatmapCore = Color(0xFFE53935);
  static const Color heatmapMid = Color(0xFFFFA726);
  static const Color heatmapEdge = Color(0xFFFFEB3B);
}
