# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**TraceCast: Scan-to-Projector** is a Flutter mobile app that transforms physical patterns (sewing, quilting, stencils) into projector-ready digital overlays. Users capture patterns with their phone camera, AI extracts clean vectors, and the app projects at true scale via AirPlay/Cast.

- **Platforms:** iOS and Android (single Flutter codebase)
- **Business Model:** Subscription-only ($3.99/mo or $29.99/yr)
- **State Management:** Riverpod with code generation
- **Dart SDK:** >=3.2.0 <4.0.0 (use FVM for Flutter 3.19.0)

## Documentation Reading Order

1. `docs/TraceCast_PRD_v1.md` - Full requirements and architecture (read sections 1-8)
2. `docs/TraceCast_Appendix_AI_Prompt_Engineering.md` - AI vectorization implementation
3. `docs/TraceCast_Appendix_Computer_Vision.md` - ArUco detection and scale calibration
4. `docs/TraceCast_Firestore_Schema.md` - Database structure
5. `docs/TraceCast_Roadmap.md` - Phase-by-phase implementation tasks

## Development Commands

```bash
# Install dependencies
flutter pub get

# Generate Riverpod code (run after adding @riverpod annotations)
dart run build_runner build --delete-conflicting-outputs

# Watch mode for code generation during development
dart run build_runner watch --delete-conflicting-outputs

# Run tests
flutter test

# Analyze code for issues
flutter analyze

# Run on physical device (required for camera/external display)
flutter run -d <device_id>

# Firebase setup (first time)
flutterfire configure

# Start Firebase emulators
firebase emulators:start
```

### Cloud Functions (`functions/` directory)

```bash
cd functions

# Install dependencies
npm install

# Build TypeScript
npm run build

# Deploy to Firebase
npm run deploy

# Run locally with emulator
npm run serve

# View logs
npm run logs

# Lint TypeScript
npm run lint
```

## Architecture

### Tech Stack
- **Frontend:** Flutter/Dart with Riverpod state management
- **Backend:** Firebase (Firestore, Storage, Cloud Functions)
- **AI:** OpenRouter API for vision model routing (Gemini 2.0 Flash primary)
- **IAP:** RevenueCat
- **CV:** opencv_dart for ArUco marker detection

### Project Structure
```
lib/
├── app/                    # App initialization, router, theme
│   └── theme/             # Blueprint design system (blue background, white text)
├── core/
│   ├── providers/         # Riverpod providers
│   ├── services/          # Firebase, API client, analytics
│   ├── models/            # Project, Piece, Path data models
│   └── constants/         # Subscription IDs, design tokens
├── features/
│   ├── onboarding/        # 16-screen onboarding flow
│   ├── capture/           # Camera + reference detection
│   ├── verification/      # AI result review
│   ├── editor/            # Quick fix vector editing
│   ├── projector/         # Cast display + phone remote
│   └── library/           # Project management
├── shared/widgets/        # Reusable components
└── platform_channels/     # AirPlay/Cast native code
```

### Key Providers (in `lib/core/providers/`)
- `project_providers.dart` - Project list and state
- `capture_providers.dart` - Camera/capture flow state
- `vectorization_provider.dart` - AI processing state
- `subscription_provider.dart` - RevenueCat subscription status
- `external_display_provider.dart` - Connected display info
- `pending_uploads_provider.dart` - Offline queue
- `editor_state_provider.dart` - Vector editor state
- `calibration_provider.dart` - Projector calibration

## Design System: Blueprint Theme

All UI uses the "Blueprint" paradigm - steel blue background with white elements:

```dart
primaryBackground: Color(0xFF4A90E2)  // Steel Blue canvas
primaryForeground: Color(0xFFFFFFFF)  // White text/icons
accentAction: Color(0xFFFF9F43)       // Orange CTAs
surfaceOverlay: Color(0xFF357ABD)     // Darker blue for depth
```

**Typography:** Reduce weights by one step and add +1-2% letter spacing for white-on-blue.

## Critical Constraints

### DO NOT
- Use iOS Simulator for camera/external display testing (physical device required)
- Hardcode OpenRouter model IDs (use Remote Config for hot-swapping)
- Skip response validation on AI outputs (LLMs return malformed JSON)
- Store OpenRouter API key client-side (Cloud Functions only)
- Implement multi-piece detection in MVP (deferred to P2)
- Show fake progress percentages (use real backend stages)

### MUST
- Call `Purchases.configure()` before ANY entitlement check
- Check subscription at protected actions, not just app launch
- Use `ScrubberInput` widget with tap-to-type fallback for accessibility
- Handle Cloud Function cold starts (3-8 seconds) in loading animations
- Test ArUco detection on physical devices before committing to opencv_dart

## AI Vectorization

The vectorization Cloud Function is in `functions/src/vectorize.ts`.

### OpenRouter Model Chain (with fallbacks)
1. `google/gemini-2.0-flash-exp` (primary, 20s timeout)
2. `google/gemini-1.5-flash` (fallback, 20s timeout)
3. `anthropic/claude-3-5-haiku-20241022` (25s timeout)
4. `openai/gpt-4o-mini` (25s timeout)

### Key Implementation Notes
- Temperature: 0.1 (low for consistent JSON output)
- All coordinates returned in pixels, transformed to mm in Cloud Function
- Scale factor comes from reference detection (ArUco/grid/credit card)
- Response validation is mandatory before trusting AI output
- Images auto-downscaled to max 1536px for faster AI processing
- Minimum confidence threshold: 20%

## RevenueCat Configuration

```dart
class SubscriptionProducts {
  static const monthlyId = 'tracecast_monthly_399';
  static const annualId = 'tracecast_annual_2999';
  static const entitlementId = 'pro';
}
```

## Current Development Status

See `docs/TraceCast_Roadmap.md` for detailed phase tracking.

**Build Phases:**
- Phase 0: Foundation (theme, navigation, services)
- Phase 1: Core Loop (camera → AI → projector)
- Phase 2: Accuracy & Calibration
- Phase 3: Onboarding & Monetization
- Phase 4: Editor & Refinement
- Phase 5: Library & Export
- Phase 6: Polish & Launch

## Known Blockers

- OpenRouter API Key required for AI vectorization
- RevenueCat products must be configured: `tracecast_monthly_399`, `tracecast_annual_2999`
- Test pattern images needed for Phase 1 validation (at least 1 real sewing pattern)

## Environment Setup

Copy `.env.example` to `.env` and fill in:
```
OPENROUTER_API_KEY=sk-or-xxxxxxxx
REVENUECAT_PUBLIC_KEY_IOS=appl_xxxxxxxx
REVENUECAT_PUBLIC_KEY_ANDROID=goog_xxxxxxxx
```

For Cloud Functions, set the OpenRouter key via Firebase config:
```bash
firebase functions:config:set openrouter.api_key="sk-or-xxxxxxxx"
```

## External Display Architecture

TraceCast uses true external display output (not mirroring):
- Phone shows Blueprint UI with controls
- Projector shows black background with white pattern lines
- Platform channels required for iOS (UIScreen/UIWindow) and Android (Presentation API)

See `docs/TraceCast_Appendix_AI_Prompt_Engineering.md` Section 7 for complete implementation.

## Key Entry Points

- `lib/main.dart` - App bootstrap, Firebase/RevenueCat initialization
- `lib/app/app.dart` - Root widget with Riverpod and theme
- `lib/app/router.dart` - GoRouter navigation configuration
- `lib/app/theme/blueprint_theme.dart` - Theme data and tokens
- `functions/src/index.ts` - Cloud Functions entry point
- `functions/src/vectorize.ts` - AI vectorization logic
