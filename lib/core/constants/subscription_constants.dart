/// RevenueCat product and entitlement identifiers.
///
/// These must match exactly what's configured in RevenueCat dashboard.
class SubscriptionProducts {
  SubscriptionProducts._();

  /// Monthly subscription product ID
  static const String monthlyId = 'tracecast_monthly_399';

  /// Annual subscription product ID (includes 3-day free trial)
  static const String annualId = 'tracecast_annual_2999';

  /// Entitlement identifier for pro features
  static const String entitlementId = 'pro';

  /// All product IDs for RevenueCat offerings
  static const List<String> allProductIds = [monthlyId, annualId];
}

/// Subscription pricing for display purposes.
///
/// Actual pricing comes from RevenueCat but these are fallbacks.
class SubscriptionPricing {
  SubscriptionPricing._();

  static const double monthlyPriceUSD = 3.99;
  static const double annualPriceUSD = 29.99;
  static const int trialDays = 3; // Only for annual
}
