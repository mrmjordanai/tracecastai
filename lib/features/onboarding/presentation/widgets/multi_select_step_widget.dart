import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/blueprint_colors.dart';
import '../../../../core/providers/onboarding_provider.dart';

/// MultiSelectStepWidget - Checkbox cards with validation
/// Used for: pain_points screen
class MultiSelectStepWidget extends StatefulWidget {
  final OnboardingStepDefinition step;
  final List<dynamic> currentValues;
  final void Function(List<String> values) onSelect;
  final VoidCallback onContinue;
  final VoidCallback? onBack;

  const MultiSelectStepWidget({
    super.key,
    required this.step,
    required this.currentValues,
    required this.onSelect,
    required this.onContinue,
    this.onBack,
  });

  @override
  State<MultiSelectStepWidget> createState() => _MultiSelectStepWidgetState();
}

class _MultiSelectStepWidgetState extends State<MultiSelectStepWidget> {
  late Set<String> _selectedValues;

  @override
  void initState() {
    super.initState();
    _selectedValues = widget.currentValues.map((e) => e.toString()).toSet();
  }

  void _toggleValue(String value) {
    setState(() {
      if (_selectedValues.contains(value)) {
        _selectedValues.remove(value);
      } else {
        _selectedValues.add(value);
      }
    });
    widget.onSelect(_selectedValues.toList());
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.step.options ?? [];
    final canContinue = _selectedValues.isNotEmpty;

    return SafeArea(
      child: Column(
        children: [
          // Header with back button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (widget.onBack != null)
                  IconButton(
                    onPressed: widget.onBack,
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
                  widget.step.title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Select all that apply',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

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
                final isSelected = _selectedValues.contains(id);

                return _CheckboxCard(
                  id: id,
                  label: label,
                  isSelected: isSelected,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _toggleValue(id);
                  },
                );
              },
            ),
          ),

          // Continue button
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: canContinue ? widget.onContinue : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canContinue
                      ? BlueprintColors.primaryForeground
                      : BlueprintColors.tertiaryForeground,
                  foregroundColor: BlueprintColors.primaryBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckboxCard extends StatelessWidget {
  final String id;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CheckboxCard({
    required this.id,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? BlueprintColors.surfaceElevated
          : BlueprintColors.surfaceOverlay,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              // Checkbox
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected
                      ? BlueprintColors.primaryForeground
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? BlueprintColors.primaryForeground
                        : BlueprintColors.secondaryForeground,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        size: 18,
                        color: BlueprintColors.primaryBackground,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: BlueprintColors.primaryForeground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
