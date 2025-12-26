import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/theme/blueprint_colors.dart';
import '../../../../core/providers/onboarding_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/subscription_constants.dart';

/// PaywallStepWidget - Subscription paywall screen
/// Screen 15: Trial timeline, plan selection, purchase flow
class PaywallStepWidget extends StatefulWidget {
  final OnboardingStepDefinition step;
  final Map<String, dynamic> answers;
  final Future<bool> Function(String planId) onPurchase;
  final Future<bool> Function() onRestore;
  final VoidCallback? onBack;

  const PaywallStepWidget({
    super.key,
    required this.step,
    required this.answers,
    required this.onPurchase,
    required this.onRestore,
    this.onBack,
  });

  @override
  State<PaywallStepWidget> createState() => _PaywallStepWidgetState();
}

class _PaywallStepWidgetState extends State<PaywallStepWidget> {
  String _selectedPlan = 'annual'; // Annual selected by default
  bool _isLoading = false;
  String? _error;

  String get _personalizedHeadline {
    final painPoints = widget.answers['pain_points'] as List<dynamic>?;
    if (painPoints != null && painPoints.isNotEmpty) {
      final firstPain = painPoints.first as String;
      switch (firstPain) {
        case 'taping':
          return 'Skip the taping—scan and project in minutes';
        case 'accuracy':
          return 'Guaranteed accurate scale with every scan';
        case 'storage':
          return 'Digitize your patterns, free up space';
        default:
          return 'Unlock the full TraceCast experience';
      }
    }
    return 'Unlock the full TraceCast experience';
  }

  Future<void> _handlePurchase() async {
    if (_isLoading) return;

    HapticFeedback.mediumImpact();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final productId = _selectedPlan == 'annual'
          ? SubscriptionProducts.annualId
          : SubscriptionProducts.monthlyId;

      final success = await widget.onPurchase(productId);
      if (!success && mounted) {
        setState(() {
          _error = 'Purchase was cancelled or failed. Please try again.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'An error occurred. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRestore() async {
    if (_isLoading) return;

    HapticFeedback.selectionClick();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final success = await widget.onRestore();
      if (!success && mounted) {
        setState(() {
          _error = 'No previous purchases found.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not restore purchases. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Title
              Text(
                'Unlock TraceCast',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Personalized headline
              Text(
                _personalizedHeadline,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Trial timeline
              _buildTrialTimeline(),

              const SizedBox(height: 32),

              // Plan cards
              _PlanCard(
                planId: 'annual',
                title: 'Yearly',
                price:
                    '\$${SubscriptionPricing.annualPriceUSD.toStringAsFixed(2)}',
                period: '/year',
                badge: 'Best Value',
                features: [
                  '${SubscriptionPricing.trialDays}-Day Free Trial',
                  'Then \$${(SubscriptionPricing.annualPriceUSD / 12).toStringAsFixed(2)}/month',
                  'Save 37%',
                ],
                isSelected: _selectedPlan == 'annual',
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedPlan = 'annual');
                },
              ),

              const SizedBox(height: 12),

              _PlanCard(
                planId: 'monthly',
                title: 'Monthly',
                price:
                    '\$${SubscriptionPricing.monthlyPriceUSD.toStringAsFixed(2)}',
                period: '/month',
                features: ['Billed today'],
                isSelected: _selectedPlan == 'monthly',
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedPlan = 'monthly');
                },
              ),

              const SizedBox(height: 24),

              // Error message
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: BlueprintColors.errorState.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: BlueprintColors.errorState,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Purchase button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handlePurchase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BlueprintColors.accentAction,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    disabledBackgroundColor:
                        BlueprintColors.accentAction.withValues(alpha: 0.5),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text(
                          _selectedPlan == 'annual'
                              ? 'Start Free Trial'
                              : 'Subscribe Now',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Restore purchases
              TextButton(
                onPressed: _isLoading ? null : _handleRestore,
                child: Text(
                  'Restore Purchases',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Terms and Privacy
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => _launchUrl(AppConstants.termsUrl),
                    child: Text(
                      'Terms',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    '•',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _launchUrl(AppConstants.privacyUrl),
                    child: Text(
                      'Privacy',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrialTimeline() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BlueprintColors.surfaceOverlay,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TRIAL TIMELINE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _TimelineNode(
                  label: 'Today', sublabel: 'Full\nAccess', isFirst: true),
              Expanded(child: _TimelineLine()),
              _TimelineNode(label: 'Day 2', sublabel: 'Reminder'),
              Expanded(child: _TimelineLine()),
              _TimelineNode(
                  label: 'Day 3', sublabel: 'Trial\nEnds', isLast: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimelineNode extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool isFirst;
  final bool isLast;

  const _TimelineNode({
    required this.label,
    required this.sublabel,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFirst ? Colors.white : Colors.white.withValues(alpha: 0.5),
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          sublabel,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _TimelineLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.white.withValues(alpha: 0.3),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String planId;
  final String title;
  final String price;
  final String period;
  final String? badge;
  final List<String> features;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.planId,
    required this.title,
    required this.price,
    required this.period,
    this.badge,
    required this.features,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? Colors.white : BlueprintColors.surfaceOverlay,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? BlueprintColors.accentAction
                  : Colors.white.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: BlueprintColors.accentAction,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),

              if (badge != null) const SizedBox(height: 12),

              // Title and price row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color: isSelected
                          ? BlueprintColors.primaryBackground
                          : Colors.white,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        price,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? BlueprintColors.primaryBackground
                              : Colors.white,
                        ),
                      ),
                      Text(
                        period,
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelected
                              ? BlueprintColors.primaryBackground
                                  .withValues(alpha: 0.7)
                              : Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Features
              ...features.map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check,
                          size: 16,
                          color: isSelected
                              ? BlueprintColors.successState
                              : Colors.white.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          feature,
                          style: TextStyle(
                            fontSize: 13,
                            color: isSelected
                                ? BlueprintColors.primaryBackground
                                    .withValues(alpha: 0.8)
                                : Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
