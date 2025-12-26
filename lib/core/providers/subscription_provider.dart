import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../constants/subscription_constants.dart';

/// Subscription tier levels
enum SubscriptionTier {
  free,
  monthly,
  annual,
}

/// Subscription state
class SubscriptionState {
  final SubscriptionTier tier;
  final bool isActive;
  final DateTime? expirationDate;
  final bool isLoading;
  final String? error;

  const SubscriptionState({
    this.tier = SubscriptionTier.free,
    this.isActive = false,
    this.expirationDate,
    this.isLoading = false,
    this.error,
  });

  bool get isPremium => tier != SubscriptionTier.free && isActive;

  SubscriptionState copyWith({
    SubscriptionTier? tier,
    bool? isActive,
    DateTime? expirationDate,
    bool? isLoading,
    String? error,
  }) {
    return SubscriptionState(
      tier: tier ?? this.tier,
      isActive: isActive ?? this.isActive,
      expirationDate: expirationDate ?? this.expirationDate,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Subscription notifier - manages subscription state with RevenueCat
class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  SubscriptionNotifier() : super(const SubscriptionState());

  /// Initialize and check current subscription status
  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final entitlement =
          customerInfo.entitlements.all[SubscriptionProducts.entitlementId];
      final isActive = entitlement?.isActive ?? false;
      final tier = _determineTier(customerInfo);

      DateTime? expirationDate;
      if (entitlement?.expirationDate != null) {
        expirationDate = DateTime.tryParse(entitlement!.expirationDate!);
      }

      state = state.copyWith(
        tier: tier,
        isActive: isActive,
        expirationDate: expirationDate,
        isLoading: false,
      );
    } catch (e) {
      // If RevenueCat fails, default to free tier
      state = state.copyWith(
        tier: SubscriptionTier.free,
        isActive: false,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Determine subscription tier from customer info
  SubscriptionTier _determineTier(CustomerInfo customerInfo) {
    final entitlement =
        customerInfo.entitlements.all[SubscriptionProducts.entitlementId];
    if (entitlement == null || !entitlement.isActive) {
      return SubscriptionTier.free;
    }

    // Check which product is active
    final productId = entitlement.productIdentifier;
    if (productId == SubscriptionProducts.annualId) {
      return SubscriptionTier.annual;
    } else if (productId == SubscriptionProducts.monthlyId) {
      return SubscriptionTier.monthly;
    }

    return SubscriptionTier.free;
  }

  /// Purchase a subscription
  Future<bool> purchase(SubscriptionTier tier) async {
    if (tier == SubscriptionTier.free) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Get offerings
      final offerings = await Purchases.getOfferings();
      if (offerings.current == null) {
        throw Exception('No offerings available');
      }

      // Find the appropriate package
      Package? package;
      final productId = tier == SubscriptionTier.annual
          ? SubscriptionProducts.annualId
          : SubscriptionProducts.monthlyId;

      for (final pkg in offerings.current!.availablePackages) {
        if (pkg.storeProduct.identifier == productId) {
          package = pkg;
          break;
        }
      }

      if (package == null) {
        throw Exception('Package not found for tier: $tier');
      }

      // Make purchase
      // ignore: deprecated_member_use
      final purchaseResult = await Purchases.purchasePackage(package);
      final customerInfo = purchaseResult.customerInfo;

      // Update state based on result
      final entitlement =
          customerInfo.entitlements.all[SubscriptionProducts.entitlementId];
      final isActive = entitlement?.isActive ?? false;

      DateTime? expirationDate;
      if (entitlement?.expirationDate != null) {
        expirationDate = DateTime.tryParse(entitlement!.expirationDate!);
      }

      state = state.copyWith(
        tier: isActive ? tier : SubscriptionTier.free,
        isActive: isActive,
        expirationDate: expirationDate,
        isLoading: false,
      );

      return isActive;
    } on PlatformException catch (e) {
      // Handle specific RevenueCat errors
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      String errorMessage;
      switch (errorCode) {
        case PurchasesErrorCode.purchaseCancelledError:
          errorMessage = 'Purchase was cancelled';
          break;
        case PurchasesErrorCode.purchaseNotAllowedError:
          errorMessage = 'Purchases not allowed on this device';
          break;
        case PurchasesErrorCode.paymentPendingError:
          errorMessage = 'Payment is pending';
          break;
        default:
          errorMessage = 'Purchase failed: ${e.message}';
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Restore previous purchases
  Future<bool> restorePurchases() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final customerInfo = await Purchases.restorePurchases();

      final entitlement =
          customerInfo.entitlements.all[SubscriptionProducts.entitlementId];
      final isActive = entitlement?.isActive ?? false;
      final tier = _determineTier(customerInfo);

      DateTime? expirationDate;
      if (entitlement?.expirationDate != null) {
        expirationDate = DateTime.tryParse(entitlement!.expirationDate!);
      }

      state = state.copyWith(
        tier: tier,
        isActive: isActive,
        expirationDate: expirationDate,
        isLoading: false,
      );

      return isActive;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

/// Subscription provider
final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  return SubscriptionNotifier();
});

/// Convenience provider for checking premium status
final isPremiumProvider = Provider<bool>((ref) {
  return ref.watch(subscriptionProvider).isPremium;
});
