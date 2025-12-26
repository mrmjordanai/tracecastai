import 'package:flutter/material.dart';
import 'blueprint_colors.dart';

/// Blueprint Design System - Typography
///
/// Typography for white text on blue backgrounds requires special handling:
/// - Weight reduction: Reduce weights by one step to prevent blooming
/// - Letter spacing: Increase by 1-2% to maintain legibility
/// - Contrast: Use opacity variations for hierarchy
class BlueprintTypography {
  BlueprintTypography._();

  // Display styles (large headlines)
  static const TextStyle displayLarge = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w600, // Semi-Bold (was Bold)
    color: BlueprintColors.primaryForeground,
    letterSpacing: 0.5, // +1% tracking
    height: 1.2,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w500, // Medium (was Semi-Bold)
    color: BlueprintColors.primaryForeground,
    letterSpacing: 0.4,
    height: 1.2,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w500,
    color: BlueprintColors.primaryForeground,
    letterSpacing: 0.3,
    height: 1.3,
  );

  // Headline styles
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w500, // Medium (was Semi-Bold)
    color: BlueprintColors.primaryForeground,
    letterSpacing: 0.25,
    height: 1.3,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: BlueprintColors.primaryForeground,
    letterSpacing: 0.2,
    height: 1.4,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: BlueprintColors.primaryForeground,
    letterSpacing: 0.15,
    height: 1.4,
  );

  // Title styles
  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: BlueprintColors.primaryForeground,
    letterSpacing: 0.15,
    height: 1.4,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: BlueprintColors.primaryForeground,
    letterSpacing: 0.15,
    height: 1.5,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: BlueprintColors.primaryForeground,
    letterSpacing: 0.1,
    height: 1.5,
  );

  // Body styles
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400, // Regular
    color: BlueprintColors.primaryForeground,
    letterSpacing: 0.15,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: BlueprintColors.primaryForeground,
    letterSpacing: 0.1,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: BlueprintColors.secondaryForeground,
    letterSpacing: 0.1,
    height: 1.5,
  );

  // Label styles
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: BlueprintColors.primaryForeground,
    letterSpacing: 0.1,
    height: 1.4,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: BlueprintColors.primaryForeground,
    letterSpacing: 0.1,
    height: 1.4,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: BlueprintColors.secondaryForeground,
    letterSpacing: 0.1,
    height: 1.4,
  );

  // Caption style
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w300, // Light (was Regular)
    color: BlueprintColors.secondaryForeground,
    letterSpacing: 0.1,
    height: 1.4,
  );

  // Button style (inverted for white buttons on blue)
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: BlueprintColors.primaryBackground,
    letterSpacing: 0.5,
    height: 1.2,
  );

  // Button style for outlined/text buttons (white text)
  static const TextStyle buttonOutlined = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: BlueprintColors.primaryForeground,
    letterSpacing: 0.5,
    height: 1.2,
  );
}
