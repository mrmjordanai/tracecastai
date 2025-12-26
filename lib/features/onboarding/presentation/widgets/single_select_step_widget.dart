import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/blueprint_colors.dart';
import '../../../../core/providers/onboarding_provider.dart';

/// SingleSelectStepWidget - Tappable option cards
/// Used for: project_type, library_size, projector_status, grid_mat_status, units
class SingleSelectStepWidget extends StatelessWidget {
  final OnboardingStepDefinition step;
  final dynamic currentValue;
  final void Function(String value) onSelect;
  final VoidCallback onContinue;
  final VoidCallback? onBack;
  final bool autoAdvance;

  const SingleSelectStepWidget({
    super.key,
    required this.step,
    this.currentValue,
    required this.onSelect,
    required this.onContinue,
    this.onBack,
    this.autoAdvance = true,
  });

  @override
  Widget build(BuildContext context) {
    final options = step.options ?? [];
    final selectedId = currentValue?.toString();

    return SafeArea(
      child: Column(
        children: [
          // Header with back button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (onBack != null)
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                const Spacer(),
              ],
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                Text(
                  step.title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (step.subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    step.subtitle!,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Options list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final option = options[index];
                final id = option['id'] as String;
                final label = option['label'] as String;
                final iconName = option['icon'] as String?;
                final isSelected = selectedId == id;

                return _OptionCard(
                  id: id,
                  label: label,
                  iconName: iconName,
                  isSelected: isSelected,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onSelect(id);
                    if (autoAdvance) {
                      // Small delay for visual feedback
                      Future.delayed(const Duration(milliseconds: 200), () {
                        onContinue();
                      });
                    }
                  },
                );
              },
            ),
          ),

          // Continue button (only if not auto-advance)
          if (!autoAdvance && selectedId != null) ...[
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BlueprintColors.primaryForeground,
                    foregroundColor: BlueprintColors.primaryBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String id;
  final String label;
  final String? iconName;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.id,
    required this.label,
    this.iconName,
    required this.isSelected,
    required this.onTap,
  });

  IconData _getIcon() {
    switch (iconName) {
      case 'content_cut':
        return Icons.content_cut;
      case 'grid_view':
        return Icons.grid_view;
      case 'format_shapes':
        return Icons.format_shapes;
      case 'build':
        return Icons.build;
      default:
        return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? BlueprintColors.primaryForeground
          : BlueprintColors.surfaceOverlay,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            children: [
              if (iconName != null) ...[
                Icon(
                  _getIcon(),
                  size: 28,
                  color: isSelected
                      ? BlueprintColors.primaryBackground
                      : BlueprintColors.primaryForeground,
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? BlueprintColors.primaryBackground
                        : BlueprintColors.primaryForeground,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: BlueprintColors.primaryBackground,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
