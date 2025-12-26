# TraceCast: Claude Code Quickstart

**Last Updated:** December 23, 2025

This document is specifically for Claude Code (or any AI coding assistant) to get started quickly on the TraceCast project.

---

## 📖 Read Documentation in This Order

1. **[TraceCast_PRD_v1.md](./TraceCast_PRD_v1.md)** — Full requirements, design system, architecture (read sections 1-8 thoroughly)
2. **[TraceCast_Appendix_AI_Prompt_Engineering.md](./TraceCast_Appendix_AI_Prompt_Engineering.md)** — AI vectorization implementation details
3. **[TraceCast_Appendix_Computer_Vision.md](./TraceCast_Appendix_Computer_Vision.md)** — ArUco detection, scale calibration
4. **[TraceCast_Firestore_Schema.md](./TraceCast_Firestore_Schema.md)** — Canonical database structure
5. **[TraceCast_Roadmap.md](./TraceCast_Roadmap.md)** — Phase-by-phase implementation tasks
6. **[TraceCast_Screen_Mockups.md](./TraceCast_Screen_Mockups.md)** — Reference during implementation

---

## 🚫 Known Blockers (Must Resolve First)

| Blocker | Status | Action |
|---------|--------|--------|
| OpenRouter API Key | ⏳ Pending | User must create account + add billing at https://openrouter.ai |
| RevenueCat Products | ⏳ Pending | User must create `tracecast_monthly_399` and `tracecast_annual_2999` in dashboard |
| Test Pattern Images | ⏳ Pending | User must provide or source at least 1 real pattern image for Phase 1 |
| Firebase Project | ✅ Ready | User has existing Firebase account |
| Apple Developer | ✅ Ready | Account exists |
| Google Play | ✅ Ready | Account exists |

---

## ⛔ Anti-Patterns to Avoid

> [!CAUTION]
> These constraints are critical. Violating them will cause bugs, security issues, or wasted time.

- **DO NOT** use iOS Simulator for camera/external display testing — it doesn't work
- **DO NOT** hardcode OpenRouter model IDs — use Remote Config for hot-swapping
- **DO NOT** skip response validation on AI outputs — LLMs return malformed JSON
- **DO NOT** store the OpenRouter API key client-side — it goes in Cloud Functions only
- **DO NOT** implement multi-piece detection in MVP — deferred to P2
- **DO NOT** show fake progress percentages — use real backend stages
- **DO NOT** block on notification permission denial — it's non-blocking

---

## ⚡ First Session Goals

Your first coding session should accomplish:

1. **Create Flutter project** with correct folder structure
2. **Set up Firebase** with FlutterFire CLI
3. **Implement Blueprint theme** (colors, typography)
4. **Get camera preview working on a PHYSICAL device**

---

## 🎯 Phase 0 Definition of Done

Phase 0 is complete when:

- [ ] All Phase 0 checkboxes in Roadmap are checked
- [ ] App builds and runs on iOS physical device
- [ ] App builds and runs on Android physical device  
- [ ] Camera preview displays correctly
- [ ] Blueprint theme visually matches mockups
- [ ] Navigation shell works (can tap between placeholder screens)
- [ ] `ScrubberInput` widget works with both gesture and tap-to-type

> **What is `ScrubberInput`?**
> A horizontal slider for numeric values (mm/inches) that ALSO supports tap-to-type via numeric keypad. Both interaction modes are required for accessibility. See PRD Section 4.6.

---

## 🔧 Critical Implementation Notes

### OpenRouter Model IDs (Verified December 2025)

```typescript
// Primary (lowest cost, fastest) — stored in Remote Config
"google/gemini-2.0-flash-exp"

// Fallback chain (also in Remote Config)
"google/gemini-1.5-flash"
"anthropic/claude-sonnet-4-20250514"
```

> **Important:** Model IDs change. If you get "Model not found" errors, visit https://openrouter.ai/models and update Remote Config—not code.

### opencv_dart Package

The CV Appendix specifies `opencv_dart: ^1.0.0`. This package has limited adoption.

**Backup Plan if opencv_dart fails:**
1. Use platform channels to native OpenCV
2. iOS: OpenCV Swift package via SPM
3. Android: OpenCV-android-sdk via Gradle

The native code templates are already in `TraceCast_Appendix_Computer_Vision.md` Section 6.

### Cloud Function Cold Starts

Firebase Functions have 3-8 second cold starts. The Analysis Animation (Screen 20) MUST handle variable latency:

- Animation should loop gracefully
- Never show fake "95% complete" if still waiting
- Use real backend progress stages

Consider requesting minimum instances in production to eliminate cold starts.

### Subscription Gating Pattern

Check entitlements at every protected action, not just app launch:

```dart
// Guard pattern for protected routes/actions
Future<void> performProtectedAction() async {
  final subscription = ref.read(subscriptionProvider);
  final isActive = await subscription.hasActiveEntitlement(SubscriptionProducts.entitlementId);
  
  if (!isActive) {
    context.push('/paywall');
    return;
  }
  
  // Proceed with action
}
```

Protected actions include:
- Starting a new scan
- Exporting to PDF/SVG
- Accessing projector mode

### RevenueCat Product IDs

```dart
// lib/core/constants/subscription_constants.dart
class SubscriptionProducts {
  static const monthlyId = 'tracecast_monthly_399';
  static const annualId = 'tracecast_annual_2999';
  static const entitlementId = 'pro';  // RevenueCat entitlement identifier
}
```

---

## 📁 Expected Folder Structure

```
tracecast/
├── .fvmrc                          # {"flutterSdkVersion": "3.19.0"}
├── .env.example
├── .env                            # Copy from .env.example (gitignored)
├── lib/
│   ├── main.dart
│   ├── app/
│   │   ├── app.dart
│   │   ├── router.dart
│   │   └── theme/
│   │       ├── blueprint_theme.dart
│   │       ├── blueprint_colors.dart
│   │       └── blueprint_typography.dart
│   ├── core/
│   │   ├── providers/
│   │   ├── services/
│   │   ├── models/
│   │   ├── guards/                 # subscription_guard.dart
│   │   └── constants/              # subscription_constants.dart
│   ├── features/
│   │   ├── onboarding/
│   │   ├── capture/
│   │   ├── verification/
│   │   ├── editor/
│   │   ├── projector/
│   │   └── library/
│   ├── shared/
│   │   └── widgets/                # ScrubberInput lives here
│   └── platform_channels/
├── functions/
│   └── src/
├── test/
├── ios/
├── android/
├── assets/
│   ├── reference_sheets/
│   └── test_images/
│       └── README.md               # Document image sources and licenses
├── pubspec.yaml
├── firebase.json
├── firestore.rules
└── storage.rules
```

---

## 🔐 Environment Setup

### `.env.example` (commit this file)

```bash
# .env.example
# Copy to .env and fill in your values. DO NOT commit .env to git.

# OpenRouter API (required for AI vectorization)
# ⚠️ This key is for Cloud Functions ONLY — never expose client-side
OPENROUTER_API_KEY=sk-or-xxxxxxxx

# RevenueCat (required for subscriptions)
REVENUECAT_PUBLIC_KEY_IOS=appl_xxxxxxxx
REVENUECAT_PUBLIC_KEY_ANDROID=goog_xxxxxxxx

# Firebase (optional — usually configured via google-services files)
FIREBASE_PROJECT_ID=tracecast-prod
```

### `.fvmrc` (commit this file)

```json
{
  "flutterSdkVersion": "3.19.0"
}
```

---

## 🧪 Test Assets

> [!WARNING]
> **Phase 1 is BLOCKED until you have at least 1 real pattern image.** You cannot test AI vectorization with placeholder squares.

For testing vectorization, you need pattern images. Legal sources:

1. **Create originals** — Draw simple pattern shapes
2. **Creative Commons** — Search for CC-licensed sewing patterns
3. **Public domain** — Vintage patterns (pre-1928 copyright from archive.org)
4. **User-provided** — Ask the project owner for test images

Store in `/assets/test_images/`:
- `pattern_simple_square.jpg` — Basic shape for initial testing (can be hand-drawn)
- `pattern_sewing_bodice.jpg` — Real sewing pattern **(required for Phase 1 validation)**
- `pattern_quilting_hexagon.jpg` — Quilting template
- `reference_sheet_a4.jpg` — Printed ArUco reference

Document sources in `/assets/test_images/README.md`.

---

## ✅ Quick Verification Commands

```bash
# Verify Flutter version (must be 3.19.x)
flutter --version
# If wrong version, install FVM and run: fvm use 3.19.0

# Check Flutter setup
flutter doctor -v

# Generate Riverpod code
dart run build_runner build --delete-conflicting-outputs

# Verify Firebase connection
firebase projects:list

# Run on device (NOT simulator for camera)
flutter run -d <device_id>

# Verify OpenRouter API key (replace YOUR_KEY)
curl -H "Authorization: Bearer YOUR_KEY" https://openrouter.ai/api/v1/models | head -20
```

---

## 🆘 Common Issues

| Issue | Solution |
|-------|----------|
| "Model not found" from OpenRouter | Check https://openrouter.ai/models for current IDs |
| Camera permission denied | Check Info.plist (iOS) and AndroidManifest.xml |
| External display not working | Use PHYSICAL device + HDMI adapter, not simulator |
| Riverpod code not generating | Run `dart run build_runner build` |
| Firebase not connecting | Run `flutterfire configure` again |
| RevenueCat returning null entitlements | Call `Purchases.configure()` in main.dart before runApp |
| Flutter version mismatch | Use FVM: `fvm use 3.19.0` |

---

## ❓ Current Unknowns (Blocked on User)

| Question | Status | Impact |
|----------|--------|--------|
| IP/Copyright disclaimers | **Needs decision** | Affects paywall copy text |
| Test image licensing | **Blocked** | Cannot validate AI until resolved |
| Default projector line color | **Needs decision** | White is assumed, confirm with user |

### Deferred Decisions (Not Blocking)

| Decision | Status | Notes |
|----------|--------|-------|
| Projector calibration profiles | Deferred to Phase 6 | MVP uses session-only storage |
| Multi-piece detection | Deferred to P2 | MVP processes one piece per scan |
| Social sharing | Deferred to P2 | No sharing in MVP |
