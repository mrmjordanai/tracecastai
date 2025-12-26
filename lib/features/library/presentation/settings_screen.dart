import 'package:flutter/material.dart';

import '../../../app/theme/blueprint_colors.dart';

/// Settings Screen
///
/// App configuration, account management, and preferences.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Account section
            _SectionHeader(title: 'Account'),
            _SettingsTile(
              icon: Icons.person_outline,
              title: 'Profile',
              subtitle: 'Manage your account',
              onTap: () {
                // TODO: Navigate to profile
              },
            ),
            _SettingsTile(
              icon: Icons.star_outline,
              title: 'Subscription',
              subtitle: 'Free trial active',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: BlueprintColors.accentAction,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'PRO',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: BlueprintColors.primaryForeground,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              onTap: () {
                // TODO: Navigate to subscription
              },
            ),

            const SizedBox(height: 24),

            // Preferences section
            _SectionHeader(title: 'Preferences'),
            _SettingsTile(
              icon: Icons.straighten,
              title: 'Units',
              subtitle: 'Inches',
              onTap: () {
                // TODO: Show units picker
              },
            ),
            _SettingsTile(
              icon: Icons.line_weight,
              title: 'Default Line Width',
              subtitle: '1.2 mm',
              onTap: () {
                // TODO: Show line width picker
              },
            ),
            _SettingsTile(
              icon: Icons.vibration,
              title: 'Haptic Feedback',
              trailing: Switch(
                value: true,
                onChanged: (value) {
                  // TODO: Toggle haptic feedback
                },
              ),
              onTap: () {},
            ),

            const SizedBox(height: 24),

            // Projector section
            _SectionHeader(title: 'Projector'),
            _SettingsTile(
              icon: Icons.cast,
              title: 'Calibration Profiles',
              subtitle: 'No profiles saved',
              onTap: () {
                // TODO: Navigate to calibration profiles
              },
            ),
            _SettingsTile(
              icon: Icons.color_lens_outlined,
              title: 'Default Projector Color',
              subtitle: 'White',
              onTap: () {
                // TODO: Show color picker
              },
            ),

            const SizedBox(height: 24),

            // Support section
            _SectionHeader(title: 'Support'),
            _SettingsTile(
              icon: Icons.help_outline,
              title: 'Help & FAQ',
              onTap: () {
                // TODO: Navigate to help
              },
            ),
            _SettingsTile(
              icon: Icons.email_outlined,
              title: 'Contact Support',
              onTap: () {
                // TODO: Open email
              },
            ),
            _SettingsTile(
              icon: Icons.info_outline,
              title: 'About TraceCast',
              subtitle: 'Version 1.0.0',
              onTap: () {
                // TODO: Show about dialog
              },
            ),

            const SizedBox(height: 24),

            // Sign out button
            Center(
              child: TextButton(
                onPressed: () {
                  // TODO: Sign out
                },
                child: Text(
                  'Sign Out',
                  style: TextStyle(
                    color: BlueprintColors.errorState,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: BlueprintColors.secondaryForeground,
            ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final semanticLabel = subtitle != null ? '$title, $subtitle' : title;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: BlueprintColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: BlueprintColors.primaryForeground,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                ExcludeSemantics(child: trailing!)
              else
                ExcludeSemantics(
                  child: Icon(
                    Icons.chevron_right,
                    color: BlueprintColors.tertiaryForeground,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
