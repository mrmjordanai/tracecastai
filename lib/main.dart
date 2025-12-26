import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'firebase_options.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style for Blueprint theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF357ABD), // surfaceOverlay
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Hive for offline queue
  await Hive.initFlutter();

  // TODO: Uncomment after running `flutterfire configure`
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configure RevenueCat - CRITICAL: Must be configured BEFORE runApp
  await Purchases.setLogLevel(LogLevel.debug); // Remove in production

  final apiKey = Platform.isIOS
      ? const String.fromEnvironment('REVENUECAT_PUBLIC_KEY_IOS')
      : const String.fromEnvironment('REVENUECAT_PUBLIC_KEY_ANDROID');

  if (apiKey.isNotEmpty) {
    await Purchases.configure(PurchasesConfiguration(apiKey));
  } else {
    debugPrint('WARNING: RevenueCat API key not configured. Subscriptions will not work.');
  }

  runApp(
    const ProviderScope(
      child: TraceCastApp(),
    ),
  );
}
