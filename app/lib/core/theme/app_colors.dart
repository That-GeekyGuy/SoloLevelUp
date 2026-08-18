import 'package:flutter/material.dart';

/// SoloLevelUp's palette: a dark, "shadow monarch" aesthetic — deep navy
/// background, an electric indigo/violet gradient for anything that
/// represents growth or power (stat bars, streak flame, level-up), and a
/// hot amber/orange accent reserved for calls to action and the daily
/// quest highlight, echoing the reference product's sunrise quest art.
class AppColors {
  AppColors._();

  // Base surfaces
  static const Color voidBlack = Color(0xFF06070D);
  static const Color deepNavy = Color(0xFF0B0E1A);
  static const Color surface = Color(0xFF12162A);
  static const Color surfaceRaised = Color(0xFF1A2038);
  static const Color surfaceBorder = Color(0xFF2B3358);

  // Text
  static const Color textPrimary = Color(0xFFF3F4FA);
  static const Color textSecondary = Color(0xFFA8AFCC);
  static const Color textMuted = Color(0xFF6C7398);

  // Brand gradient — "Rise" glow
  static const Color risePrimary = Color(0xFF6C5CE7);
  static const Color riseSecondary = Color(0xFF00D2FF);
  static const List<Color> riseGradient = [risePrimary, riseSecondary];

  // Accent — quest / streak / call-to-action
  static const Color emberAccent = Color(0xFFFF7A3D);
  static const Color emberAccentDeep = Color(0xFFE64A19);

  // Semantic
  static const Color success = Color(0xFF2ED573);
  static const Color danger = Color(0xFFFF4D6D);
  static const Color warning = Color(0xFFFFC048);

  // Stat colors (Rise Rating tiles — one identity color per stat so the
  // dashboard reads at a glance)
  static const Color statWisdom = Color(0xFF4FD1C5);
  static const Color statStrength = Color(0xFFFF6B6B);
  static const Color statFocus = Color(0xFF60A5FA);
  static const Color statConfidence = Color(0xFFF6C453);
  static const Color statDiscipline = Color(0xFF9B8CFF);
  static const Color statOverall = emberAccent;

  static Color forStat(String key) {
    switch (key) {
      case 'wisdom':
        return statWisdom;
      case 'strength':
        return statStrength;
      case 'focus':
        return statFocus;
      case 'confidence':
        return statConfidence;
      case 'discipline':
        return statDiscipline;
      default:
        return statOverall;
    }
  }
}
