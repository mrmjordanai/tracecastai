import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'blueprint_colors.dart';
import 'blueprint_typography.dart';

/// Blueprint Design System - Theme
///
/// Complete ThemeData configuration for TraceCast.
/// Steel blue backgrounds with white foreground elements.
class BlueprintTheme {
  BlueprintTheme._();

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color scheme
      colorScheme: const ColorScheme.dark(
        primary: BlueprintColors.primaryForeground,
        onPrimary: BlueprintColors.primaryBackground,
        secondary: BlueprintColors.accentAction,
        onSecondary: BlueprintColors.primaryForeground,
        surface: BlueprintColors.primaryBackground,
        onSurface: BlueprintColors.primaryForeground,
        error: BlueprintColors.errorState,
        onError: BlueprintColors.primaryForeground,
      ),

      // Scaffold background
      scaffoldBackgroundColor: BlueprintColors.primaryBackground,

      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: BlueprintColors.primaryBackground,
        foregroundColor: BlueprintColors.primaryForeground,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: BlueprintTypography.headlineMedium,
        iconTheme: IconThemeData(
          color: BlueprintColors.primaryForeground,
        ),
      ),

      // Text theme
      textTheme: const TextTheme(
        displayLarge: BlueprintTypography.displayLarge,
        displayMedium: BlueprintTypography.displayMedium,
        displaySmall: BlueprintTypography.displaySmall,
        headlineLarge: BlueprintTypography.headlineLarge,
        headlineMedium: BlueprintTypography.headlineMedium,
        headlineSmall: BlueprintTypography.headlineSmall,
        titleLarge: BlueprintTypography.titleLarge,
        titleMedium: BlueprintTypography.titleMedium,
        titleSmall: BlueprintTypography.titleSmall,
        bodyLarge: BlueprintTypography.bodyLarge,
        bodyMedium: BlueprintTypography.bodyMedium,
        bodySmall: BlueprintTypography.bodySmall,
        labelLarge: BlueprintTypography.labelLarge,
        labelMedium: BlueprintTypography.labelMedium,
        labelSmall: BlueprintTypography.labelSmall,
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: BlueprintColors.surfaceElevated,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(8),
      ),

      // Elevated button theme (primary action - white button)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BlueprintColors.primaryForeground,
          foregroundColor: BlueprintColors.primaryBackground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: BlueprintTypography.button,
        ),
      ),

      // Outlined button theme (secondary action)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: BlueprintColors.primaryForeground,
          side: const BorderSide(color: BlueprintColors.primaryForeground),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: BlueprintTypography.buttonOutlined,
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: BlueprintColors.primaryForeground,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: BlueprintTypography.buttonOutlined,
        ),
      ),

      // Floating action button theme (Magic Button style)
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: BlueprintColors.primaryForeground,
        foregroundColor: BlueprintColors.primaryBackground,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BlueprintColors.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: BlueprintColors.primaryForeground,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: BlueprintColors.errorState,
            width: 2,
          ),
        ),
        labelStyle: BlueprintTypography.bodyMedium,
        hintStyle: BlueprintTypography.bodyMedium.copyWith(
          color: BlueprintColors.tertiaryForeground,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        color: BlueprintColors.primaryForeground,
        size: 24,
      ),

      // Divider theme
      dividerTheme: const DividerThemeData(
        color: BlueprintColors.divider,
        thickness: 1,
        space: 1,
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: BlueprintColors.surfaceOverlay,
        selectedItemColor: BlueprintColors.primaryForeground,
        unselectedItemColor: BlueprintColors.tertiaryForeground,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: BlueprintTypography.labelSmall,
        unselectedLabelStyle: BlueprintTypography.labelSmall,
      ),

      // Navigation bar theme (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: BlueprintColors.surfaceOverlay,
        indicatorColor:
            BlueprintColors.primaryForeground.withValues(alpha: 0.2),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: BlueprintColors.primaryForeground,
            );
          }
          return const IconThemeData(
            color: BlueprintColors.tertiaryForeground,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return BlueprintTypography.labelSmall;
          }
          return BlueprintTypography.labelSmall.copyWith(
            color: BlueprintColors.tertiaryForeground,
          );
        }),
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: BlueprintColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: BlueprintTypography.headlineSmall,
        contentTextStyle: BlueprintTypography.bodyMedium,
      ),

      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: BlueprintColors.surfaceOverlay,
        contentTextStyle: BlueprintTypography.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: BlueprintColors.surfaceElevated,
        labelStyle: BlueprintTypography.labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide.none,
      ),

      // Progress indicator theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: BlueprintColors.primaryForeground,
        linearTrackColor: BlueprintColors.surfaceOverlay,
        circularTrackColor: BlueprintColors.surfaceOverlay,
      ),

      // Slider theme
      sliderTheme: SliderThemeData(
        activeTrackColor: BlueprintColors.primaryForeground,
        inactiveTrackColor: BlueprintColors.surfaceOverlay,
        thumbColor: BlueprintColors.primaryForeground,
        overlayColor: BlueprintColors.primaryForeground.withValues(alpha: 0.2),
        valueIndicatorColor: BlueprintColors.primaryForeground,
        valueIndicatorTextStyle: BlueprintTypography.labelMedium.copyWith(
          color: BlueprintColors.primaryBackground,
        ),
      ),

      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return BlueprintColors.primaryForeground;
          }
          return BlueprintColors.tertiaryForeground;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return BlueprintColors.surfaceElevated;
          }
          return BlueprintColors.surfaceOverlay;
        }),
      ),

      // Checkbox theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return BlueprintColors.primaryForeground;
          }
          return BlueprintColors.transparent;
        }),
        checkColor: WidgetStateProperty.all(BlueprintColors.primaryBackground),
        side: const BorderSide(
          color: BlueprintColors.primaryForeground,
          width: 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // Radio theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return BlueprintColors.primaryForeground;
          }
          return BlueprintColors.tertiaryForeground;
        }),
      ),
    );
  }
}
