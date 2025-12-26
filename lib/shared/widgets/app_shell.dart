import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/blueprint_colors.dart';
import 'pending_uploads_indicator.dart';

/// App Shell with bottom navigation
///
/// Provides the main navigation structure with Home, Scan, and Settings tabs.
/// The Scan button is styled as the "Magic Button" - larger and prominent.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.child,
  });

  final Widget child;

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/settings')) return 2;
    if (location.startsWith('/scan')) return 1;
    return 0; // home
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.goNamed('home');
        break;
      case 1:
        context.goNamed('scan');
        break;
      case 2:
        context.goNamed('settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: BlueprintColors.surfaceOverlay,
          boxShadow: [
            BoxShadow(
              color: BlueprintColors.shadowColor,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Home tab
                _NavItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  label: 'Home',
                  isSelected: selectedIndex == 0,
                  onTap: () => _onItemTapped(context, 0),
                ),

                // Scan tab (Magic Button style) with pending uploads badge
                PendingUploadsBadge(
                  child: _MagicScanButton(
                    isSelected: selectedIndex == 1,
                    onTap: () => _onItemTapped(context, 1),
                  ),
                ),

                // Settings tab
                _NavItem(
                  icon: Icons.settings_outlined,
                  selectedIcon: Icons.settings,
                  label: 'Settings',
                  isSelected: selectedIndex == 2,
                  onTap: () => _onItemTapped(context, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected
                  ? BlueprintColors.primaryForeground
                  : BlueprintColors.tertiaryForeground,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                color: isSelected
                    ? BlueprintColors.primaryForeground
                    : BlueprintColors.tertiaryForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Magic Button style scan button
///
/// Larger, white button that breaks the tab bar visually.
/// This is the primary call-to-action in the app.
class _MagicScanButton extends StatelessWidget {
  const _MagicScanButton({
    required this.isSelected,
    required this.onTap,
  });

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: BlueprintColors.primaryForeground,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: BlueprintColors.shadowColor,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          Icons.camera_alt,
          color: BlueprintColors.primaryBackground,
          size: 28,
        ),
      ),
    );
  }
}
