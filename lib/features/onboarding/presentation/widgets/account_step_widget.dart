import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/blueprint_colors.dart';
import '../../../../core/providers/onboarding_provider.dart';

/// AccountStepWidget - Account creation/sign-in screen
/// Screen 14: Apple, Google, and Email authentication options
class AccountStepWidget extends StatefulWidget {
  final OnboardingStepDefinition step;
  final Future<bool> Function(String provider) onSignIn;
  final VoidCallback? onBack;

  const AccountStepWidget({
    super.key,
    required this.step,
    required this.onSignIn,
    this.onBack,
  });

  @override
  State<AccountStepWidget> createState() => _AccountStepWidgetState();
}

class _AccountStepWidgetState extends State<AccountStepWidget> {
  bool _isLoading = false;
  String? _loadingProvider;
  String? _error;

  Future<void> _handleSignIn(String provider) async {
    if (_isLoading) return;

    HapticFeedback.mediumImpact();

    setState(() {
      _isLoading = true;
      _loadingProvider = provider;
      _error = null;
    });

    try {
      final success = await widget.onSignIn(provider);
      if (!success && mounted) {
        setState(() {
          _error = 'Sign in was cancelled or failed. Please try again.';
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
          _loadingProvider = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    tooltip: 'Go back',
                  ),
                const Spacer(),
              ],
            ),
          ),

          const Spacer(flex: 2),

          // Title and subtitle
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
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (widget.step.subtitle != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    widget.step.subtitle!,
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

          const SizedBox(height: 48),

          // Error message
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
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

          const SizedBox(height: 24),

          // Sign in buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                // Sign in with Apple
                _SignInButton(
                  provider: 'apple',
                  label: 'Sign in with Apple',
                  icon: Icons.apple,
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  isLoading: _loadingProvider == 'apple',
                  isDisabled: _isLoading,
                  onTap: () => _handleSignIn('apple'),
                ),

                const SizedBox(height: 12),

                // Sign in with Google
                _SignInButton(
                  provider: 'google',
                  label: 'Sign in with Google',
                  icon: Icons.g_mobiledata,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  isLoading: _loadingProvider == 'google',
                  isDisabled: _isLoading,
                  onTap: () => _handleSignIn('google'),
                ),

                const SizedBox(height: 12),

                // Continue with Email
                _SignInButton(
                  provider: 'email',
                  label: 'Continue with Email',
                  icon: Icons.email_outlined,
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  borderColor: Colors.white.withValues(alpha: 0.5),
                  isLoading: _loadingProvider == 'email',
                  isDisabled: _isLoading,
                  onTap: () => _handleSignIn('email'),
                ),
              ],
            ),
          ),

          const Spacer(flex: 3),

          // Legal text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'By continuing, you agree to our Terms of Service and Privacy Policy',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SignInButton extends StatelessWidget {
  final String provider;
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onTap;

  const _SignInButton({
    required this.provider,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderColor,
    required this.isLoading,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: isDisabled && !isLoading
            ? backgroundColor.withValues(alpha: 0.5)
            : backgroundColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: borderColor != null
                  ? Border.all(color: borderColor!, width: 1)
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(foregroundColor),
                    ),
                  )
                else
                  Icon(icon, color: foregroundColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: foregroundColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
