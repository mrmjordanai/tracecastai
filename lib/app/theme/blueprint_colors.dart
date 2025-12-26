import 'package:flutter/material.dart';

/// Blueprint Design System - Color Palette
///
/// TraceCast uses a "Blueprint" visual paradigm with steel blue backgrounds
/// and white foreground elements. This creates a distinctive, technical aesthetic
/// that evokes architectural blueprints and precision engineering.
class BlueprintColors {
  BlueprintColors._();

  // Primary palette (from PRD Section 4.2)
  /// Steel Blue canvas - primary background color
  static const Color primaryBackground = Color(0xFF4A90E2);

  /// White 100% - primary text and icon color
  static const Color primaryForeground = Color(0xFFFFFFFF);

  /// White 70% - secondary text, labels, captions
  static const Color secondaryForeground = Color(0xB3FFFFFF);

  /// White 40% - tertiary text, disabled states
  static const Color tertiaryForeground = Color(0x66FFFFFF);

  // Accent colors
  /// Safety Orange - CTAs, primary actions, Magic Button
  static const Color accentAction = Color(0xFFFF9F43);

  /// Darker Blue - surface overlays, depth layering
  static const Color surfaceOverlay = Color(0xFF357ABD);

  /// Lighter Blue - elevated surfaces, cards
  static const Color surfaceElevated = Color(0xFF5DADE2);

  // Semantic colors
  /// Soft Red - error states, destructive actions
  static const Color errorState = Color(0xFFFF6B6B);

  /// Emerald Green - success states, confirmations
  static const Color successState = Color(0xFF2ECC71);

  /// Amber - warning states, low confidence indicators
  static const Color warningState = Color(0xFFF39C12);

  // Shadows (luminance layering, not black)
  /// Deep Navy at 20% - shadows use darker blue, not black
  static const Color shadowColor = Color(0x331A2530);

  // Projector mode colors
  /// Pure Black - projector display background
  static const Color projectorBackground = Color(0xFF000000);

  /// Pure White - projector pattern lines
  static const Color projectorLine = Color(0xFFFFFFFF);

  // Additional utility colors
  /// Transparent
  static const Color transparent = Colors.transparent;

  /// Divider color - subtle white line
  static const Color divider = Color(0x33FFFFFF);

  /// Input background - slightly darker for text fields
  static const Color inputBackground = Color(0xFF3A7BC8);
}
