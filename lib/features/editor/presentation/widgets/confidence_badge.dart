import 'package:flutter/material.dart';

import '../../../../app/theme/blueprint_colors.dart';

/// Confidence level thresholds
enum ConfidenceLevel {
  high, // ≥80%
  medium, // 50-79%
  low, // <50%
}

/// Returns the confidence level based on a confidence score (0.0 - 1.0)
ConfidenceLevel getConfidenceLevel(double confidence) {
  if (confidence >= 0.80) return ConfidenceLevel.high;
  if (confidence >= 0.50) return ConfidenceLevel.medium;
  return ConfidenceLevel.low;
}

/// A badge showing confidence level with icon and color
class ConfidenceBadge extends StatelessWidget {
  /// Confidence value from 0.0 to 1.0
  final double confidence;

  /// Whether to show the percentage text
  final bool showPercentage;

  /// Size of the badge (small, medium, large)
  final ConfidenceBadgeSize size;

  const ConfidenceBadge({
    super.key,
    required this.confidence,
    this.showPercentage = true,
    this.size = ConfidenceBadgeSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    final level = getConfidenceLevel(confidence);
    final color = _getColor(level);
    final icon = _getIcon(level);
    final iconSize = _getIconSize();
    final fontSize = _getFontSize();
    final padding = _getPadding();

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius:
            BorderRadius.circular(size == ConfidenceBadgeSize.small ? 4 : 8),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: iconSize,
          ),
          if (showPercentage) ...[
            SizedBox(width: size == ConfidenceBadgeSize.small ? 2 : 4),
            Text(
              '${(confidence * 100).round()}%',
              style: TextStyle(
                color: color,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getColor(ConfidenceLevel level) {
    switch (level) {
      case ConfidenceLevel.high:
        return BlueprintColors.successState;
      case ConfidenceLevel.medium:
        return BlueprintColors.accentAction;
      case ConfidenceLevel.low:
        return BlueprintColors.errorState;
    }
  }

  IconData _getIcon(ConfidenceLevel level) {
    switch (level) {
      case ConfidenceLevel.high:
        return Icons.check_circle;
      case ConfidenceLevel.medium:
        return Icons.warning_amber_rounded;
      case ConfidenceLevel.low:
        return Icons.cancel;
    }
  }

  double _getIconSize() {
    switch (size) {
      case ConfidenceBadgeSize.small:
        return 12;
      case ConfidenceBadgeSize.medium:
        return 16;
      case ConfidenceBadgeSize.large:
        return 20;
    }
  }

  double _getFontSize() {
    switch (size) {
      case ConfidenceBadgeSize.small:
        return 10;
      case ConfidenceBadgeSize.medium:
        return 12;
      case ConfidenceBadgeSize.large:
        return 14;
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ConfidenceBadgeSize.small:
        return const EdgeInsets.symmetric(horizontal: 4, vertical: 2);
      case ConfidenceBadgeSize.medium:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      case ConfidenceBadgeSize.large:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
    }
  }
}

enum ConfidenceBadgeSize {
  small,
  medium,
  large,
}

/// A compact inline confidence indicator (just the icon)
class ConfidenceIndicator extends StatelessWidget {
  final double confidence;
  final double size;

  const ConfidenceIndicator({
    super.key,
    required this.confidence,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    final level = getConfidenceLevel(confidence);

    return Icon(
      _getIcon(level),
      color: _getColor(level),
      size: size,
    );
  }

  Color _getColor(ConfidenceLevel level) {
    switch (level) {
      case ConfidenceLevel.high:
        return BlueprintColors.successState;
      case ConfidenceLevel.medium:
        return BlueprintColors.accentAction;
      case ConfidenceLevel.low:
        return BlueprintColors.errorState;
    }
  }

  IconData _getIcon(ConfidenceLevel level) {
    switch (level) {
      case ConfidenceLevel.high:
        return Icons.check_circle;
      case ConfidenceLevel.medium:
        return Icons.warning_amber_rounded;
      case ConfidenceLevel.low:
        return Icons.cancel;
    }
  }
}

/// Overall quality summary widget
class QualitySummary extends StatelessWidget {
  final double overallConfidence;
  final int highConfidenceCount;
  final int mediumConfidenceCount;
  final int lowConfidenceCount;

  const QualitySummary({
    super.key,
    required this.overallConfidence,
    required this.highConfidenceCount,
    required this.mediumConfidenceCount,
    required this.lowConfidenceCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BlueprintColors.surfaceOverlay,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ConfidenceBadge(
                confidence: overallConfidence,
                size: ConfidenceBadgeSize.large,
              ),
              const SizedBox(width: 12),
              Text(
                'Overall Quality',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: BlueprintColors.primaryForeground,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildCountItem(
                Icons.check_circle,
                BlueprintColors.successState,
                highConfidenceCount,
                'High',
              ),
              const SizedBox(width: 16),
              _buildCountItem(
                Icons.warning_amber_rounded,
                BlueprintColors.accentAction,
                mediumConfidenceCount,
                'Medium',
              ),
              const SizedBox(width: 16),
              _buildCountItem(
                Icons.cancel,
                BlueprintColors.errorState,
                lowConfidenceCount,
                'Low',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountItem(
    IconData icon,
    Color color,
    int count,
    String label,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
