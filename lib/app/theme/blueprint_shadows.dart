import 'package:flutter/material.dart';
import 'blueprint_colors.dart';

/// Blueprint Design System - Shadows
///
/// Uses luminance layering instead of black shadows.
/// Darker blues create depth while maintaining the blueprint aesthetic.
class BlueprintShadows {
  BlueprintShadows._();

  /// Elevation 1 - Subtle shadow for cards and buttons
  static List<BoxShadow> get elevation1 => [
        BoxShadow(
          color: BlueprintColors.shadowColor,
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  /// Elevation 2 - Medium shadow for floating elements
  static List<BoxShadow> get elevation2 => [
        BoxShadow(
          color: BlueprintColors.shadowColor,
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  /// Elevation 3 - Strong shadow for modals and dialogs
  static List<BoxShadow> get elevation3 => [
        BoxShadow(
          color: BlueprintColors.shadowColor,
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];

  /// Elevation 4 - Maximum shadow for overlays
  static List<BoxShadow> get elevation4 => [
        BoxShadow(
          color: BlueprintColors.shadowColor.withValues(alpha: 0.4),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ];

  /// Inner shadow for pressed states
  static List<BoxShadow> get innerShadow => [
        BoxShadow(
          color: BlueprintColors.surfaceOverlay.withValues(alpha: 0.5),
          blurRadius: 4,
          offset: const Offset(0, 2),
          spreadRadius: -2,
        ),
      ];

  /// Glow effect for focused elements (accent color)
  static List<BoxShadow> get accentGlow => [
        BoxShadow(
          color: BlueprintColors.accentAction.withValues(alpha: 0.4),
          blurRadius: 12,
          spreadRadius: 2,
        ),
      ];

  /// Success glow for confirmation states
  static List<BoxShadow> get successGlow => [
        BoxShadow(
          color: BlueprintColors.successState.withValues(alpha: 0.4),
          blurRadius: 12,
          spreadRadius: 2,
        ),
      ];

  /// Error glow for error states
  static List<BoxShadow> get errorGlow => [
        BoxShadow(
          color: BlueprintColors.errorState.withValues(alpha: 0.4),
          blurRadius: 12,
          spreadRadius: 2,
        ),
      ];
}
