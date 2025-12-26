import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme/blueprint_theme.dart';
import 'router.dart';

/// TraceCast Application Root
///
/// The main MaterialApp configuration using the Blueprint theme
/// and GoRouter for navigation.
class TraceCastApp extends ConsumerWidget {
  const TraceCastApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'TraceCast',
      debugShowCheckedModeBanner: false,

      // Blueprint Theme
      theme: BlueprintTheme.theme,

      // GoRouter configuration
      routerConfig: router,

      // Builder for global overlays and error handling
      builder: (context, child) {
        return MediaQuery(
          // Prevent text scaling from breaking layouts
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
