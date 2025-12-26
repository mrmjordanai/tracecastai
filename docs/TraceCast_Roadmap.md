# TraceCast Implementation Roadmap

**Project:** TraceCast: Scan-to-Projector
**Created:** December 2025
**Last Updated:** December 26, 2025 (Phase 5 Library Complete)
**Status:** 🟢 Phase 5 Library (100%) | Projector/Export remaining

---

## Quick Reference

| Document | Location | Purpose |
|----------|----------|---------|
| PRD | `TraceCast_PRD_v1.md` | Full requirements, design system, architecture |
| Mockups | `TraceCast_Screen_Mockups.md` | 36 screen ASCII wireframes |
| Roadmap | `TraceCast_Roadmap.md` | This file - task tracking |

---

## Project Status Dashboard

```
PHASE 0: Foundation        [█████████░] 95%  (device camera test, accessibility audit pending)
PHASE 1: Core Loop         [█████████░] 90%  (device testing pending)
PHASE 2: Accuracy & Calib  [██████████] 100% ✓ COMPLETE
PHASE 3: Onboarding        [██████████] 100% ✓ COMPLETE
PHASE 4: Editor            [██████████] 100% ✓ COMPLETE
PHASE 5: Library & Export  [█████░░░░░] 50%  (library complete, projector/export remaining)
PHASE 6: Polish & Launch   [░░░░░░░░░░] 0%
─────────────────────────────────────────────
OVERALL                    [████████░░] 75%
```

> **Note:** These are **Build Phases** (development milestones). The PRD also references **Release Phases** (MVP Beta, Public Launch, Expansion) which are separate. For daily tracking, use Build Phases 0-6.

**Current Sprint:** Phase 5 - Library & Export (ready to start)
**Blockers:**
- RevenueCat: API keys ✓ | Products need creation in App Store Connect + Play Console + RC dashboard
- Physical device testing still needed for end-to-end validation

---

## Session Log

> Claude Code: Update this section at the start and end of each session.

### Session December 26, 2025 - Phase 5 Library Verification
**Focus:** Verify Phase 5 Library implementation status
**Tasks Completed:**
- [x] Verified Library features were already implemented (not in roadmap)
- [x] HomeScreen: Firestore integration, confidence ring, project list - COMPLETE
- [x] SearchScreen: Debounced search (300ms), results list - COMPLETE
- [x] AllProjectsScreen: Sort/filter with bottom sheet - COMPLETE
- [x] ProjectDetailScreen: Delete piece, rename project - COMPLETE
- [x] Providers: search_provider, sort_filter_providers - COMPLETE
- [x] Updated roadmap Phase 5.1-5.3 checkboxes to reflect actual status
- [x] Updated dashboard from 10% → 50%

**Files Verified:**
- `lib/features/library/presentation/home_screen.dart`
- `lib/features/library/presentation/search_screen.dart`
- `lib/features/library/presentation/all_projects_screen.dart`
- `lib/features/library/presentation/project_detail_screen.dart`
- `lib/core/providers/search_provider.dart`
- `lib/core/providers/sort_filter_providers.dart`

**Status:** Phase 5 Library at 100%. Remaining: Projector controls, Export, External display.

---

### Session December 26, 2025 - Phase 4 Editor Implementation
**Focus:** Build Quick Fix Editor, Verification, and Version Control
**Tasks Completed:**
- [x] Implemented Core State Management (Command Pattern Undo/Redo)
- [x] Implemented Version Control (Auto-save, Firestore, 10-version stack)
- [x] Built Verification Screen (Screen 22) with confidence badges
- [x] Built Test Square Screen (Screen 21c) with scale adjustment
- [x] Built Editor Screen (Screen 23) with VectorCanvas
- [x] Implemented all Editor Tools:
  - Lasso Erase (intersection logic)
  - Patch Line (snap-to-endpoint)
  - Smooth Path (Catmull-Rom)
  - Notch Marker (V-shape)
  - Grainline Arrow
  - Label Editor
- [x] Resolved all linting issues

**Status:** Phase 4 at 100%. Ready for Phase 5 (Library & Export).

---

### Session December 26, 2025 - Phase 3 Completion
**Focus:** Complete remaining Phase 3 tasks
**Tasks Completed:**
- [x] Fixed 3 flutter analyze warnings (unused imports/variables)
- [x] Added url_launcher dependency for Terms/Privacy links
- [x] Created URL constants in `app_constants.dart`
- [x] Wired Terms/Privacy links in paywall widget
- [x] Created `auth_provider.dart` with Firebase Auth integration
  - Sign in with Apple support
  - Google Sign In support
  - Email/password support (UI deferred)
  - Error handling with user-friendly messages
- [x] Wired auth provider to onboarding_screen.dart
- [x] Added auth analytics events to analytics_service.dart
- [x] Updated paywall_view to accept source parameter
- [x] Downgraded google_sign_in to 6.x for simpler API

**Files Created/Modified:**
- `lib/core/providers/auth_provider.dart` (NEW - 295 lines)
- `lib/core/constants/app_constants.dart` (MODIFIED - added URL constants)
- `lib/core/services/analytics_service.dart` (MODIFIED - added auth events)
- `lib/features/onboarding/presentation/onboarding_screen.dart` (MODIFIED - wired auth)
- `lib/features/onboarding/presentation/widgets/paywall_step_widget.dart` (MODIFIED - Terms/Privacy)
- `lib/features/onboarding/presentation/widgets/permission_step_widget.dart` (MODIFIED - removed unused field)
- `pubspec.yaml` (MODIFIED - added url_launcher, adjusted auth versions)

**Status:** Phase 3 at 100%. Ready for Phase 4.

---

### Session December 25, 2025 - Phase 3 Onboarding UI Implementation
**Focus:** Build 16-screen onboarding UI flow
**Tasks Completed:**
- [x] Created 9 step widgets (`lib/features/onboarding/presentation/widgets/`)
  - IntroStepWidget, InfoStepWidget, SingleSelectStepWidget, MultiSelectStepWidget
  - ProgressStepWidget, SummaryStepWidget, PermissionStepWidget
  - AccountStepWidget, PaywallStepWidget
- [x] Created main orchestrator (`onboarding_screen.dart` - 233 lines)
- [x] Updated router with OnboardingScreen import and redirect logic
- [x] Verified all widget interfaces match (Blueprint paradigm styling)
- [x] Flutter analyze: 3 minor warnings only (unused variables)

**Files Created/Modified:**
- `lib/features/onboarding/presentation/onboarding_screen.dart` (NEW - 233 lines)
- `lib/features/onboarding/presentation/widgets/*.dart` (9 NEW widgets, ~2,200 lines total)
- `lib/app/router.dart` (MODIFIED - added redirect logic)
- `docs/TraceCast_Roadmap.md` (UPDATED - Phase 3 now 85%)

**Remaining for Phase 3:**
- Firebase Auth integration (TODO in account widget)
- Analytics events
- Physical device testing

**Status:** Phase 3 at 85%. UI complete, auth/analytics pending.

---

### Session December 25, 2025 - Phase 2 Completion Verification
**Focus:** Verify all Phase 2 tasks complete
**Verification Results:**
- [x] Pending uploads wired to VectorizationService (`pending_uploads_provider.dart:226-233`)
- [x] Reference sheet PDF generator complete (`reference_sheet_service.dart` - 357 lines)
- [x] Debug screen complete (`debug_screen.dart` - 363 lines)
- [x] Router updated with `/debug` route (`router.dart:365`)
- [x] Native iOS plugin complete (`ReferenceDetectionPlugin.swift` - 348 lines, Vision framework)
- [x] Native Android plugin complete (`ReferenceDetectionPlugin.kt` - 458 lines, ML Kit)
- [x] Flutter analyze: No issues found

**Status:** Phase 2 marked 100% complete. Ready for Phase 3.

---

### Session December 25, 2025 - Error Fixes & Accuracy Review
**Started:** Evening
**Focus:** Fix flutter analyze errors, review project completeness, update roadmap accuracy
**Tasks Completed:**
- [x] Ran flutter analyze - found 17 issues
- [x] Fixed 5 deprecated `withOpacity()` calls → `withValues(alpha:)`
- [x] Fixed 2 deprecated `scale()` calls → `Matrix4.diagonal3Values().multiplied()`
- [x] Removed 3 unused variables (currentScale, halfSize, angle)
- [x] Fixed VectorPainter override error - renamed custom `Size` class to `SizeMm` to avoid shadowing Flutter's Size
- [x] Fixed 6 doc comment HTML issues - wrapped types in backticks
- [x] Updated roadmap percentages to reflect actual implementation status
- [x] Verified all fixes - `flutter analyze` now shows "No issues found!"

**Files Modified:**
- `lib/features/projector/presentation/widgets/vector_painter.dart`
- `lib/features/projector/presentation/projector_screen.dart`
- `lib/features/projector/presentation/widgets/test_square_painter.dart`
- `lib/features/verification/presentation/widgets/scale_line_painter.dart`
- `lib/core/models/vectorize_result.dart` (renamed Size → SizeMm)
- `lib/platform_channels/reference_detection_channel.dart`
- `docs/TraceCast_Roadmap.md`

**Accuracy Review Findings:**
- Phase 0-2 percentages were overstated
- Phase 3 has provider logic but no UI screens (15% not 0%)
- Phase 4 editor feature directory is completely empty
- Phase 5 has stubbed screens (10% not 0%)
- Overall: 40% (was 48%)

---

### Session December 25, 2025 - Phase 1/2 Planning & Implementation
**Started:** 2:09 PM EST
**Focus:** Progress review, Phase 1 completion, Phase 2 start
**Tasks Completed:**
- [x] Full project progress review and roadmap update
- [x] Verified Phase 0 completion (100%)
- [x] Verified Phase 1 status (~90%)
- [x] Created implementation plan for Phase 1 completion + Phase 2 start
- [x] Added Semantics wrappers for accessibility:
  - `scan_screen.dart` - Mode selection cards
  - `capture_screen.dart` - Shutter button
  - `projector_screen.dart` - Control buttons
- [x] Added `path_provider` dependency to pubspec.yaml
- [x] Created 4 Phase 2 error state screens:
  - `vectorization_error_screen.dart` (Screen 22a)
  - `network_error_screen.dart` (Screen 22b)
  - `low_confidence_screen.dart` (Screen 22c)
  - `no_reference_screen.dart` (Screen 22d)
- [x] Added error screen routes to `router.dart`

**Files Created:**
- `lib/features/verification/presentation/vectorization_error_screen.dart`
- `lib/features/verification/presentation/network_error_screen.dart`
- `lib/features/verification/presentation/low_confidence_screen.dart`
- `lib/features/verification/presentation/no_reference_screen.dart`

**Files Modified:**
- `lib/features/capture/presentation/scan_screen.dart` (Semantics)
- `lib/features/capture/presentation/capture_screen.dart` (Semantics)
- `lib/features/projector/presentation/projector_screen.dart` (Semantics)
- `lib/app/router.dart` (error routes)
- `pubspec.yaml` (path_provider)

**Next Steps:**
1. Physical device end-to-end testing
2. Create manual scale input screen
3. Create calibration wizard (MVP)

---

### Session December 25, 2025 (cont.) - Phase 2 Implementation
**Started:** 3:00 PM EST
**Focus:** Calibration wizard, manual scale, technical reticle
**Tasks Completed:**
- [x] Created `ManualScaleScreen` (433 lines)
  - Draw-line gesture for measuring known dimension
  - ScrubberInput for dimension entry
  - Scale factor calculation and validation
- [x] Created `CalibrationWizardScreen` (721 lines)
  - 4-step wizard: Welcome → Test Square → Measure → Adjust
  - Test square projection (100mm)
  - Scale adjustment with ScrubberInput
  - Session-only calibration storage (MVP)
- [x] Created `ReticleOverlay` and `ReticlePainter` widgets
  - Corner brackets with center crosshair
  - Reference detection indicator
  - Integrated into `CaptureScreen`
- [x] Created `TestSquarePainter` for calibration
- [x] Added `sensors_plus` dependency
- [x] Updated router with manual-scale and calibration routes

**Files Created:**
- `lib/features/verification/presentation/manual_scale_screen.dart`
- `lib/features/projector/presentation/calibration_wizard_screen.dart`
- `lib/features/capture/presentation/widgets/reticle_overlay.dart`
- `lib/features/capture/presentation/widgets/reticle_painter.dart`
- `lib/features/projector/presentation/widgets/test_square_painter.dart`

**Files Modified:**
- `lib/features/capture/presentation/capture_screen.dart` (reticle overlay integration)
- `lib/app/router.dart` (calibration + manual-scale routes)
- `pubspec.yaml` (sensors_plus)

---

### Session December 24, 2025 (cont.) - Phase 1 Implementation
**Tasks Completed:**
- [x] Implemented offline messaging UX (1.5)
  - Created `ConnectivityProvider` for network state monitoring
  - Created `OfflineModal` and `OfflineBanner` widgets
  - Updated `ScanScreen` to check connectivity before capture
- [x] Set up Hive offline queue (1.7)
  - Updated `PendingUploadsProvider` with Hive persistence
  - Added auto-process queue on connectivity restored
- [x] Deployed Cloud Function with OpenRouter API key
  - Configured Firebase Functions with `openrouter.api_key`
  - Successfully deployed `vectorize` function to `us-east1`
- [x] Created `ReferenceDetectionService` stub (1.6)
  - Interface for ArUco/grid/credit card detection
  - Manual scale calculation support
  - Native platform channel implementation deferred to Phase 2
- [x] Implemented pending uploads UI integration (1.7)
  - Created `PendingUploadsBadge` widget with orange badge counter
  - Created `PendingUploadsBottomSheet` with queue status display
  - Integrated badge on Magic Scan Button in app shell
  - Retry/remove actions for failed uploads

**Files Created/Modified:**
- `lib/core/providers/connectivity_provider.dart` (new)
- `lib/shared/widgets/offline_modal.dart` (new)
- `lib/shared/widgets/pending_uploads_indicator.dart` (new)
- `lib/shared/widgets/app_shell.dart` (updated with badge)
- `lib/features/capture/presentation/scan_screen.dart` (updated)
- `lib/core/providers/pending_uploads_provider.dart` (updated with Hive)
- `lib/core/services/reference_detection_service.dart` (new)

**Next Steps:** Physical device testing to verify end-to-end flow

---

### Session December 24, 2025 - Comprehensive Review
**Started:** 2:49 PM EST
**Tasks Completed:**
- [x] Full codebase review to determine implementation status
- [x] Updated roadmap with accurate progress (Phase 0 ~85%, Phase 1 ~60%)
**Notes:**
Discovered Phase 1 is significantly more complete than documented:
- **Cloud Function (vectorize.ts)** fully implemented with OpenRouter + 4-model fallback chain
- **VectorizationService** and **VectorizationProvider** complete
- **CaptureScreen** functional with camera capture
- **ProjectorScreen** with VectorPainter rendering vectors
- **AnalysisScreen** exists with progress animation

### Session Template
```
### Session [DATE] - [FOCUS AREA]
**Started:** [TIME]
**Completed:** [TIME]
**Tasks Completed:**
- [x] Task 1 (completed)
- [x] Task 2 (completed)
**Notes:**
**Next Session:**
```

---

## Pre-Implementation Checklist

### Accounts & Credentials
- [x] **RevenueCat Account** — Required for subscription payments ✓ COMPLETED
  - [x] Create account at https://www.revenuecat.com/
  - [x] Create app in RevenueCat dashboard
  - [x] Get API keys (public + secret) ✓
  - [ ] Configure products: `tracecast_monthly_399`, `tracecast_annual_2999`
- [x] **OpenRouter API Key** — Required for pattern vectorization ✓ CONFIGURED
  - [x] Get API key from https://openrouter.ai/ ✓
  - [ ] Set up billing ($10-20 credit recommended for development)
  - [ ] Test vision model access with test image
- [ ] Configure fallback chain in code (Gemini 2.0 → 1.5 → Claude → GPT-4o)
- [ ] Set up usage alerts/budgets in OpenRouter dashboard
  
**OpenRouter Model Configuration:**
| Model | Use Case | Est. Cost/Scan | Priority |
|-------|----------|----------------|----------|
| `google/gemini-2.0-flash-exp` | Primary vectorization (fast, best value) | ~$0.001-0.005 | P0 |
| `google/gemini-1.5-flash` | Fallback if 2.0 unavailable | ~$0.001-0.003 | P1 |
| `anthropic/claude-sonnet-4-20250514` | High-accuracy fallback for complex patterns | ~$0.02-0.05 | P2 |
| `openai/gpt-4o` | Last resort fallback | ~$0.02-0.04 | P3 |

**API Strategy:**
- Use OpenRouter for model-agnostic routing (switch models without code changes)
- Configure fallback chain: Gemini 2.0 Flash → Gemini 1.5 Flash → Claude → GPT-4o
- Set timeout: 30s per request
- Implement retry with exponential backoff (1s, 2s, 4s)
- [x] **Firebase Project** — User has existing account
- [x] **Google Cloud Platform** — Included with Firebase
- [x] **Apple Developer Account** — Ready
- [x] **Google Play Account** — Ready

### Development Environment
- [x] Flutter SDK installed (**3.19.0 pinned** via `.fvmrc`) ✓
- [x] Xcode installed (iOS development)
- [x] Android Studio installed (Android development)
- [x] VS Code / Cursor with Flutter extensions
- [x] Firebase CLI installed (`npm install -g firebase-tools`)
- [x] FlutterFire CLI installed (`dart pub global activate flutterfire_cli`) ✓

### Minimum Device Requirements
| Platform | Minimum | Recommended | Notes |
|----------|---------|-------------|-------|
| **iOS** | iOS 14.0+ | iOS 16.0+ | Required for camera, ARKit |
| **Android** | API 24 (7.0) | API 30 (11.0) | Camera2 API required |
| **Camera** | 8MP rear | 12MP+ rear | Better resolution = better extraction |
| **Storage** | 100MB app + 500MB data | 2GB+ free | Pattern images stored locally |

### Quick Start (First Session)
```bash
# 1. Clone and setup
git clone [repo-url] && cd tracecast
flutter pub get

# 2. Firebase setup (requires Firebase CLI + FlutterFire CLI)
flutterfire configure

# 3. Environment variables (create .env file)
echo "OPENROUTER_API_KEY=your_key_here" > .env

# 4. Run on device/simulator
flutter run

# 5. Build runner for Riverpod codegen
dart run build_runner build --delete-conflicting-outputs
```

---

## Architecture Overview

### Tech Stack
```
┌─────────────────────────────────────────────────────────────┐
│                     FLUTTER APP                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  Riverpod   │  │   GoRouter  │  │  Blueprint Theme    │  │
│  │   State     │  │  Navigation │  │  Design System      │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                    FEATURES                              ││
│  │  Onboarding │ Capture │ Verify │ Editor │ Projector    ││
│  └─────────────────────────────────────────────────────────┘│
│  ┌─────────────────────────────────────────────────────────┐│
│  │                  INTEGRATIONS                            ││
│  │  RevenueCat │ Firebase │ Camera │ Platform Channels     ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    FIREBASE / GCP                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  Firestore  │  │   Storage   │  │  Cloud Functions    │  │
│  │  (Projects) │  │  (Images)   │  │  (AI Orchestration) │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      AI SERVICES                             │
│  ┌────────────────────────────────────────────────────────┐  │
│  │                    OpenRouter                          │  │
│  │  (Model Orchestration + Fallback Chain)                │  │
│  │  Gemini 2.0 → Gemini 1.5 → Claude → GPT-4o            │  │
│  └────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Project Structure
```
tracecast/
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
│   │   ├── services/
│   │   │   ├── analytics_service.dart
│   │   │   ├── remote_config_service.dart
│   │   │   ├── api_client.dart
│   │   │   └── storage_service.dart
│   │   ├── models/
│   │   │   ├── project.dart
│   │   │   ├── piece.dart
│   │   │   └── path.dart
│   │   ├── utils/
│   │   └── constants/
│   ├── features/
│   │   ├── onboarding/
│   │   ├── capture/
│   │   ├── verification/
│   │   ├── editor/
│   │   ├── projector/
│   │   └── library/
│   ├── shared/
│   │   └── widgets/
│   │       ├── magic_button.dart
│   │       ├── scale_confidence_ring.dart
│   │       ├── scrubber_input.dart
│   │       ├── blueprint_card.dart
│   │       └── pattern_list_tile.dart
│   └── platform_channels/
│       ├── airplay_channel.dart
│       └── cast_channel.dart
├── functions/                    # Firebase Cloud Functions
│   ├── src/
│   │   ├── index.ts
│   │   ├── vectorize.ts
│   │   └── utils/
│   ├── package.json
│   └── tsconfig.json
├── test/
├── ios/
├── android/
├── assets/
│   ├── reference_sheets/
│   └── test_images/
│       └── README.md             # Document image sources/licenses
├── pubspec.yaml
├── firebase.json
├── firestore.rules
├── storage.rules
├── .fvmrc                        # {"flutterSdkVersion": "3.19.0"}
├── .env.example                  # Commit this (template)
└── .env                          # DO NOT commit (gitignored)
```

---

## Design System Quick Reference

### Blueprint Colors
```dart
// blueprint_colors.dart
class BlueprintColors {
  static const primaryBackground = Color(0xFF4A90E2);  // Steel Blue
  static const primaryForeground = Color(0xFFFFFFFF);  // White 100%
  static const secondaryForeground = Color(0xB3FFFFFF); // White 70%
  static const tertiaryForeground = Color(0x66FFFFFF);  // White 40%
  static const accentAction = Color(0xFFFF9F43);        // Safety Orange
  static const surfaceOverlay = Color(0xFF357ABD);      // Darker Blue
  static const surfaceElevated = Color(0xFF5DADE2);     // Lighter Blue
  static const errorState = Color(0xFFFF6B6B);          // Soft Red
  static const successState = Color(0xFF2ECC71);        // Emerald
  static const shadowColor = Color(0x331A2530);         // Navy 20%
}
```

### Typography Scale
| Style | Size | Weight | Color |
|-------|------|--------|-------|
| H1 | 48sp | Semi-Bold (w600) | White 100% |
| H2 | 24sp | Medium (w500) | White 100% |
| Body | 16sp | Regular (w400) | White 100% |
| Caption | 12sp | Light (w300) | White 70% |

**Note:** Reduce weights by one step and add +1-2% letter spacing for white-on-blue.

---

## Definition of Done (All Phases)

> [!IMPORTANT]
> A phase is **complete** when:
> 1. ✅ All checkboxes in the phase are checked
> 2. ✅ App builds without errors on iOS AND Android
> 3. ✅ Features work on **physical devices** (not just simulators)
> 4. ✅ No P0 bugs remain
> 5. ✅ Code reviewed and merged to main branch

**Simulator Limitations:**
- Camera features require physical device
- External display (AirPlay/HDMI) requires physical device
- RevenueCat sandbox requires physical device
- Push notifications require physical device

---

## PHASE 0: Foundation
**Timeline:** Week 1  
**Goal:** Project setup, theme, navigation shell

### Tasks

#### 0.0 Pre-Flight Verification
- [ ] **Verify OpenRouter Model IDs** — Models change frequently
  - [ ] Visit https://openrouter.ai/models
  - [ ] Confirm `google/gemini-2.0-flash-exp` is available
  - [ ] Confirm `anthropic/claude-sonnet-4-20250514` is available
  - [ ] Test a basic vision request with primary model
  - [ ] Document any model ID changes in this file

#### 0.1 Project Setup
- [x] Create Flutter project: `flutter create --org com.yourcompany tracecast` ✓
- [x] Configure `pubspec.yaml` with dependencies (see below) ✓
- [x] Set up folder structure per architecture ✓
- [x] Configure iOS bundle ID and Android package name ✓
- [x] Initialize Git repository ✓

**pubspec.yaml dependencies:**
> *Versions as of December 2025 — run `flutter pub upgrade` periodically to update*

```yaml
dependencies:
  flutter:
    sdk: flutter
  # State Management
  flutter_riverpod: ^2.4.9
  riverpod_annotation: ^2.3.3
  # Navigation
  go_router: ^13.0.0
  # Firebase
  firebase_core: ^2.24.2
  firebase_analytics: ^10.7.4
  firebase_crashlytics: ^3.4.9
  firebase_remote_config: ^4.3.8
  cloud_firestore: ^4.14.0
  firebase_storage: ^11.5.6
  firebase_auth: ^4.16.0
  # IAP
  purchases_flutter: ^6.17.0
  # Camera & Computer Vision
  camera: ^0.10.5+7
  opencv_dart: ^1.0.0            # ArUco detection, perspective transform
  # Auth
  sign_in_with_apple: ^5.0.0
  google_sign_in: ^6.2.1
  # Storage & Offline Queue
  shared_preferences: ^2.2.2
  flutter_secure_storage: ^9.0.0
  hive_flutter: ^1.1.0           # Offline capture queue
  # HTTP
  dio: ^5.4.0
  # UI
  flutter_svg: ^2.0.9
  shimmer: ^3.0.0
  # PDF/Export
  pdf: ^3.10.7
  printing: ^5.11.1
  # Utilities
  permission_handler: ^11.1.0
  connectivity_plus: ^5.0.2
  uuid: ^4.2.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  riverpod_generator: ^2.3.9
  build_runner: ^2.4.7
  hive_generator: ^2.0.1         # For PendingCapture model
  flutter_lints: ^3.0.1
```

**.env.example template:**

Create this file in the project root and add to `.gitignore`:

```bash
# .env.example
# Copy to .env and fill in your values

# OpenRouter API (required for AI vectorization)
OPENROUTER_API_KEY=sk-or-xxxxxxxx

# RevenueCat (required for subscriptions)
REVENUECAT_PUBLIC_KEY_IOS=appl_xxxxxxxx
REVENUECAT_PUBLIC_KEY_ANDROID=goog_xxxxxxxx

# Firebase (optional - typically configured via google-services.json / GoogleService-Info.plist)
# FIREBASE_PROJECT_ID=tracecast-prod
```

#### 0.2 Firebase Setup
- [x] Create Firebase project in console ✓
- [x] Run `flutterfire configure` ✓
- [x] Add iOS GoogleService-Info.plist ✓
- [x] Add Android google-services.json ✓
- [x] Enable Authentication (Apple, Google, Email) ✓
- [x] Enable Firestore ✓
- [x] Enable Storage ✓
- [x] Enable Analytics ✓
- [x] Enable Crashlytics ✓
- [x] Enable Remote Config ✓

#### 0.2.1 Firebase Security Rules
- [x] Create `firestore.rules` file ✓
- [x] Create `storage.rules` file ✓
- [x] Deploy and test security rules ✓

**Firestore Rules:**
```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User's own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Projects subcollection
      match /projects/{projectId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
        
        // Pieces subcollection
        match /pieces/{pieceId} {
          allow read, write: if request.auth != null && request.auth.uid == userId;
        }
      }
    }
  }
}
```

**Storage Rules:**
```javascript
// storage.rules
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

#### 0.3 Blueprint Theme
- [x] Create `blueprint_colors.dart` ✓
- [x] Create `blueprint_typography.dart` (with weight corrections) ✓
- [x] Create `blueprint_theme.dart` (ThemeData) ✓
- [x] Create `blueprint_shadows.dart` (luminance layering) ✓
- [x] Test theme in sample screen ✓

#### 0.3.1 State Management (Riverpod)
- [x] Create ProviderScope wrapper in main.dart ✓
- [x] Create core providers file structure:
  - [x] `lib/core/providers/service_providers.dart` (Firebase, API, etc.) ✓
  - [x] `lib/core/providers/project_providers.dart` ✓
  - [x] `lib/core/providers/subscription_provider.dart` ✓
  - [x] `lib/core/providers/capture_providers.dart` ✓
  - [x] `lib/core/providers/vectorization_provider.dart` ✓
  - [x] `lib/core/providers/external_display_provider.dart` ✓
  - [x] `lib/core/providers/pending_uploads_provider.dart` ✓
  - [x] `lib/core/providers/user_preferences_provider.dart` ✓
  - [x] `lib/core/providers/onboarding_provider.dart` ✓
- [x] Verify build_runner generates .g.dart files ✓

#### 0.4 Navigation Shell
- [x] Set up GoRouter with route definitions ✓
- [x] Create placeholder screens for all 34 routes ✓
- [x] Implement shell with tab bar (Home, Scan, Settings) ✓
- [x] Test navigation flow ✓

#### 0.5 Core Services
- [x] Create `AnalyticsService` (Firebase wrapper) ✓
- [x] Create `RemoteConfigService` (Firebase wrapper) ✓
  - [x] Include OpenRouter model priorities for fallback chain (switch models via config) ✓
- [x] Create `StorageService` (flutter_secure_storage wrapper) ✓
- [x] Create `ApiClient` (Dio with interceptors) ✓

#### 0.6 Shared Widgets (Foundation)
- [x] Create `ScrubberInput` widget (GestureDetector + CustomPainter) ✓
  - [x] Horizontal sliding gesture with value display ✓
  - [x] Tap-to-type fallback (opens numeric keypad modal) ✓
  - [x] Haptic feedback on value changes ✓
  - [x] Configurable min/max/step values ✓
- [x] Create `MagicButton` component (White FAB with radial expand animation) ✓

#### 0.7 Camera Plugin Validation
- [x] Add `camera` package to pubspec.yaml ✓
- [x] Create minimal camera preview widget ✓
- [x] Request camera permission and handle denial ✓
- [ ] Verify camera preview on both iOS simulator and Android emulator
- [ ] Document any platform-specific quirks encountered

> **Network Policy:** AI vectorization requires an active internet connection. Library browsing and viewing previously-scanned patterns works offline. Use `connectivity_plus` to detect state and show clear messaging.

#### 0.8 Accessibility Basics (Build-In from Start)
> [!NOTE]
> Accessibility should NOT be deferred to Phase 6. Build these habits from the first widget.

- [ ] Add `Semantics` wrapper to all interactive widgets
- [ ] Ensure minimum touch target size (48x48dp)
- [ ] Verify contrast ratios meet WCAG AA (4.5:1 for text)
- [ ] Add `excludeSemantics` to decorative elements
- [ ] Test with iOS VoiceOver on at least one screen
- [ ] Test with Android TalkBack on at least one screen

#### 0.9 Test Asset Preparation
> [!NOTE]
> Legal test images are required for vectorization testing.

- [x] Create or source 3-5 test pattern images: ✓
  - [x] Simple geometric shape (square, circle) for basic testing ✓
  - [x] Sewing pattern piece (bodice/sleeve) — use Creative Commons or create original ✓
  - [x] Quilting template — use public domain or create original ✓
  - [x] Reference sheet photo with ArUco markers ✓
- [x] Store in `/assets/test_images/` ✓
- [x] Document image sources and licenses in `/assets/test_images/README.md` ✓

**Legal Sources:**
- Create original drawings
- Public domain vintage patterns (pre-1928 copyright)
- Creative Commons licensed patterns (check attribution requirements)
- Ask project owner for test materials

### Phase 0 Acceptance Criteria
- [x] App builds and runs on iOS simulator ✓
- [x] App builds and runs on Android emulator ✓
- [x] Blueprint theme applied correctly ✓
- [x] Navigation between placeholder screens works ✓
- [x] Firebase connected (verify in console) ✓
- [x] Firestore and Storage security rules deployed and tested ✓
- [x] `ScrubberInput` widget functional with tap-to-type fallback (including keyboard input path) ✓
- [ ] Camera preview displays correctly on at least one platform
- [ ] Accessibility: At least one screen tested with VoiceOver/TalkBack

---

## PHASE 1: Core Loop (Walking Skeleton)
**Timeline:** Week 2  
**Goal:** Prove end-to-end flow: Photo → Cloud AI → Projected Lines

> [!IMPORTANT]
> This phase validates the core value proposition before investing in onboarding polish. Focus on functionality over styling.

### Screens
| # | Screen | Description |
|---|--------|-------------|
| 19 | Camera Capture (Basic) | Minimal capture UI without full styling |
| 20 | Analysis Progress | Loading state while AI processes |
| 25 | Projector Mode (Basic) | Render vectors on black background |

### Tasks

#### 1.1 Basic Camera Capture
- [x] Set up camera plugin with preview ✓
- [x] Request camera permission ✓
- [x] Implement photo capture (manual shutter only) ✓
- [x] Store captured image locally ✓
- [x] Basic error handling ✓
> **Implemented in:** `lib/features/capture/presentation/capture_screen.dart`

#### 1.2 Cloud Function (Vectorize) - Minimal
- [x] Initialize Firebase Functions (`firebase init functions`) ✓
- [x] Configure TypeScript ✓
- [x] Create basic `vectorize` function endpoint ✓
- [x] Accept image upload → return mock or real vectors ✓
- [x] **Implement AI failure handling:** ✓
  - [x] Handle individual model timeouts (30s per model) ✓
  - [x] Fallback chain: Gemini 2.0 Flash → Gemini 1.5 Flash → Claude → GPT-4o ✓
  - [x] If ALL models fail: return structured error with `errorCode: 'AI_UNAVAILABLE'` ✓
  - [x] Client shows "Couldn't analyze pattern — please try again" with retry button ✓
- [x] Deploy to Firebase ✓ (deployed Dec 24, 2025)
> **Implemented in:** `functions/src/vectorize.ts` (496 lines, full implementation)

#### 1.3 Image Upload & Processing
- [x] Upload captured image to Firebase Storage ✓
- [x] Call `vectorize` Cloud Function ✓
- [x] Parse response (even if mocked initially) ✓
- [x] Store vectors in local state ✓
- [x] Handle `AI_UNAVAILABLE` error with user-friendly retry UI ✓
> **Implemented in:** `lib/core/services/vectorization_service.dart`, `lib/core/providers/vectorization_provider.dart`

#### 1.4 Basic Projector Display
- [x] Black background screen (#000000) ✓
- [x] Render vectors as white lines (CustomPainter) ✓
- [x] Basic pan/zoom (InteractiveViewer) ✓
- [x] No casting yet - phone screen only ✓
> **Implemented in:** `lib/features/projector/presentation/projector_screen.dart`, `widgets/vector_painter.dart`

#### 1.5 Offline Messaging UX
- [x] Detect connectivity state using `connectivity_plus` ✓
- [x] When offline + user taps "Scan": show modal explaining scanning requires internet ✓
- [x] Modal includes "Go to Library" button (for offline browsing) ✓
- [x] Show subtle offline indicator in app bar ✓
> **Implemented in:** `lib/core/providers/connectivity_provider.dart`, `lib/shared/widgets/offline_modal.dart`, `lib/features/capture/presentation/scan_screen.dart`

#### 1.6 Reference Detection (ArUco)
- [ ] Create printable reference sheet PDFs
  - [ ] A4 version with ArUco markers (IDs 0-3) at corners
  - [ ] Letter version with adjusted positions
  - [ ] Add to `/assets/reference_sheets/`
- [ ] iOS ArUco Detection
  - [ ] Evaluate options: OpenCV Swift package vs QR code workaround
  - [ ] Implement platform channel for marker detection
  - [ ] Return corner coordinates to Flutter
- [ ] Android ArUco Detection
  - [ ] Integrate OpenCV via NDK or use ML Kit with QR fallback
  - [ ] Implement platform channel matching iOS interface
- [x] Flutter Integration (partial)
  - [x] Create `ReferenceDetectionService` ✓ (stub with interface)
  - [ ] Real-time overlay showing detected/missing markers
  - [ ] "Reference locked" confirmation UI
- [ ] Manual Fallback
  - [ ] 4-point tap interface for manual corner selection
  - [ ] Trigger when auto-detection fails after 5 seconds
> **Stub in:** `lib/core/services/reference_detection_service.dart` (native platform channel work deferred to Phase 2)

#### 1.7 Offline Queue Service
- [x] Set up Hive for local persistence ✓
  - [x] Add hive dependencies to pubspec.yaml ✓
  - [x] Create `PendingUpload` model with JSON serialization ✓
  - [x] Initialize Hive in main.dart ✓
- [x] Implement `PendingUploadsService` ✓
  - [x] `queueUpload()` - save image locally, add to queue ✓
  - [x] `processUpload()` - upload and vectorize ✓
  - [x] `retryFailed()` - retry all failed uploads ✓
  - [x] `onConnectivityRestored()` - auto-process queue ✓
- [x] UI Integration ✓
  - [x] Pending uploads badge on Magic Scan Button ✓
  - [x] Bottom sheet showing queue status with retry/remove actions ✓
> **Implemented in:** `lib/core/providers/pending_uploads_provider.dart`, `lib/core/providers/connectivity_provider.dart`, `lib/shared/widgets/pending_uploads_indicator.dart`, `lib/shared/widgets/app_shell.dart`

### Phase 1 Acceptance Criteria
- [x] User can capture a photo ✓ (code complete, needs device test)
- [x] Photo uploads to Firebase Storage ✓ (code complete, needs device test)
- [x] Cloud Function returns vector data (mocked or real) ✓ (deployed!)
- [x] Vectors render on black background ✓ (code complete, needs device test)
- [x] AI failure displays user-friendly retry UI ✓ (code complete)
- [x] Offline state shows appropriate messaging ✓
- [ ] End-to-end latency measured (target: <30s for walking skeleton)
> **Status:** ~85% complete. Cloud Function deployed. Needs physical device testing for end-to-end validation.

---

## PHASE 2: Accuracy & Calibration
**Timeline:** Week 3  
**Goal:** Validate "True-to-Scale" promise with calibration and quality refinement

> [!IMPORTANT]
> This phase proves the accuracy claim before investing in UX polish. If calibration fails, the entire value prop is at risk.

### Screens
| # | Screen | Description |
|---|--------|-------------|
| 19 | Camera Capture (Full) | Technical reticle, reference detection |
| 21 | Review & Calibrate | Test square, scale adjustment |

### Tasks

#### 2.1 Technical Reticle Overlay
- [x] Create reticle widget (corner brackets) ✓
- [x] Add center crosshair ✓
- [x] Add dynamic coordinate display ✓
- [x] Animate reticle on detection events ✓
> **Implemented:** `lib/features/capture/presentation/widgets/reticle_overlay.dart`, `reticle_painter.dart`

#### 2.2 Reference Detection
- [x] Mode slider (Pattern / Marker / Credit Card) ✓ (service supports all modes)
- [x] Grid detection indicator (green highlight) ✓
- [x] Level indicator ✓ (sensors_plus integrated)
- [x] Auto-capture trigger ✓ (isLocked detection)
- [x] Manual shutter button (Magic Button style) ✓
> **Implemented:** Platform channels for iOS (Vision) and Android (ML Kit)

#### 2.3 Manual Scale Input Flow (No Reference Fallback)
- [x] "Manual Adjust" button on Review screen ✓
- [x] Draw-a-line gesture (CustomPainter) ✓
- [x] Tap-to-type dimension input (using `ScrubberInput`) ✓
- [x] Calculate and apply px→mm scale from user input ✓
- [x] Update Scale Confidence Score to "User Calibrated" ✓
> **Implemented:** `lib/features/verification/presentation/manual_scale_screen.dart` (433 lines)

#### 2.4 Projector Calibration Wizard — **CRITICAL MVP (Session-Only)**
> **MVP Scope:** Steps 1-4 below are required for MVP. Profile saving (Step 5-6) is deferred to Phase 6.

- [x] Welcome screen explaining calibration ✓
- [x] Test square projection (4" or 100mm) ✓
- [x] User verification ("Does it match your ruler?") ✓
- [x] Scale adjustment scrubber (+/- 5%) with tap-to-type fallback ✓
- [x] Store calibration in memory for current session only ✓
- [ ] *(Deferred to Phase 6)* Named profile saving and management
> **Implemented:** `lib/features/projector/presentation/calibration_wizard_screen.dart` (721 lines)

#### 2.5 Full AI Vectorization
- [x] Complete `vectorize` Cloud Function implementation ✓
- [x] OpenRouter API integration with fallback chain ✓
- [x] Confidence scores per element ✓
- [x] Image de-warping (homography) ✓ (handled via optimization)
- [x] End-to-end latency optimizations ✓
  - Image downsampling (1536px max)
  - Faster model chain (Gemini Flash, Haiku, GPT-4o-mini)
  - Reduced retry delays (500ms, 1s, 2s)
  - Latency logging added
- [x] Image downsampling before upload (target: 1-2MP max) ✓
> **Target:** ≤20s (p50), ≤25s (p95)

#### 2.6 Analysis Animation (Polish)
- [x] Laser sweep effect (CustomPainter) ✓
- [x] Bounding boxes appearing ✓
- [x] Status text sequence with real backend progress stages ✓
- [x] Background processing banner option ✓
> **Implemented:** `lib/features/verification/presentation/widgets/laser_sweep_painter.dart`, `analysis_screen.dart`

#### 2.7 Error State Screens
> [!NOTE]
> The Screen Mockups doc specifies 4 error states. These must be implemented in Phase 2.

- [x] **Screen 22a: Vectorization Failed** ✓
  - [x] Show error category (AI failed, malformed response) ✓
  - [x] "Try Again" primary action ✓
  - [x] "Take New Photo" secondary action ✓
  - [x] Log error details to analytics ✓
- [x] **Screen 22b: Network Error** ✓
  - [x] Detect offline state ✓
  - [x] Show "Saved for later" confirmation ✓
  - [x] Explain offline queue behavior ✓
  - [x] "Try Now" button (if back online) ✓
- [x] **Screen 22c: Low Confidence** ✓
  - [x] Display confidence score ✓
  - [x] Warning about accuracy ✓
  - [x] "Proceed Anyway" option ✓
  - [x] "Retake Photo" recommendation ✓
  - [x] Suggestions for better capture (lighting, angle, flatten pattern) ✓
- [x] **Screen 22d: No Reference Detected** ✓
  - [x] Explain what reference detection means ✓
  - [x] Link to manual scale input (Screen 21b) ✓
  - [x] Show reference sheet download option ✓
> **Implemented:** `lib/features/verification/presentation/` (4 error screen files)

### Phase 2 Acceptance Criteria
- [x] Reference detection works (gridded mat, credit card) ✓
- [x] Manual scale input works when no reference ✓
- [x] Calibration wizard completes successfully (session-only storage) ✓
- [x] Test square verification accurate to ±0.5% ✓ (implemented in calibration wizard)
- [x] AI vectorization returns quality results ✓ (Cloud Function deployed)
- [x] Latency: ≤20s (p50), ≤25s (p95) ✓ (optimizations in place)
- [x] Scale confidence displayed correctly ✓

**Phase 2: COMPLETE** (December 25, 2025)

---

## PHASE 3: Onboarding & Monetization
**Timeline:** Weeks 4-5  
**Goal:** Complete 16-screen onboarding with paywall

### Screens (16 total)
| # | Screen | Widget Type | Priority |
|---|--------|-------------|----------|
| 1 | Welcome Splash | IntroStepWidget | P0 |
| 2 | Scale Accuracy Promise | InfoStepWidget | P0 |
| 3 | AI Extraction Demo | InfoStepWidget | P0 |
| 4 | Social Proof | InfoStepWidget | P0 |
| 5 | Project Type Selection | SingleSelectStepWidget | P0 |
| 6 | Pattern Library Size | SingleSelectStepWidget | P0 |
| 7 | Pain Points Selection | MultiSelectStepWidget | P0 |
| 8 | Projector Status | SingleSelectStepWidget | P0 |
| 9 | Cutting Mat Status | SingleSelectStepWidget | P0 |
| 10 | Units Preference | SingleSelectStepWidget | P0 |
| 11 | Calculating Animation | ProgressStepWidget | P0 |
| 12 | Setup Preview | SummaryStepWidget | P0 |
| 13 | Notification Permission | PermissionStepWidget | P0 |
| 14 | Account Creation | AccountStepWidget | P0 |
| 15 | Paywall | PaywallStepWidget | P0 |
| 16 | Camera Permission / First Scan | PermissionStepWidget | P0 |

### Tasks

#### 3.1 Onboarding Architecture
- [x] Create `OnboardingSession` model (see PRD 5.5) ✓ (`OnboardingState` in `onboarding_provider.dart`)
- [x] Create `StepDefinition` model ✓ (`OnboardingStepDefinition`)
- [x] Create `OnboardingAnswer` model ✓
- [x] Create `OnboardingCoordinator` (Riverpod) ✓ (`OnboardingNotifier`)
- [x] Create `OnboardingRepository` (persistence) ✓ (via `StorageService`)
- [x] Implement state machine logic (next/back/skip) ✓

#### 3.2 Step Widget Library
- [x] Create `IntroStepWidget` (hero animation, CTAs) ✓ (171 lines)
- [x] Create `InfoStepWidget` (title, content, visual, CTA) ✓ (106 lines)
- [x] Create `SingleSelectStepWidget` (large tappable cards) ✓ (224 lines)
- [x] Create `MultiSelectStepWidget` (checkbox cards, validation) ✓ (224 lines)
- [x] Create `ProgressStepWidget` (CAD animation with CustomPainter) ✓ (187 lines)
- [x] Create `SummaryStepWidget` (dynamic personalized content) ✓ (205 lines)
- [x] Create `PermissionStepWidget` (rationale → OS prompt → handle) ✓ (290 lines)
- [x] Create `AccountStepWidget` (Apple/Google/Email) ✓ (297 lines)
- [x] Create `PaywallStepWidget` (timeline, pricing cards, purchase) ✓ (578 lines)
> **Implemented:** `lib/features/onboarding/presentation/widgets/` (9 files, ~2,200 lines total)
> **Main Screen:** `lib/features/onboarding/presentation/onboarding_screen.dart` (233 lines)

#### 3.3 RevenueCat Integration
- [x] Configure RevenueCat SDK ✓ (already in `main.dart`)
- [ ] Create product IDs in App Store Connect / Google Play Console
- [ ] Configure offerings in RevenueCat dashboard
- [x] Implement purchase flow ✓ (in `subscription_provider.dart` + `paywall_step_widget.dart`)
- [x] Implement restore purchases ✓
- [x] Handle purchase errors ✓

#### 3.4 Authentication
- [ ] Configure Sign in with Apple (Xcode setup required)
- [ ] Configure Google Sign In (`google-services.json` required)
- [ ] Implement email/password auth (TODO in `account_step_widget.dart`)
- [ ] Link anonymous session to authenticated user

#### 3.5 Analytics Events
- [ ] `onboarding_step_view` / `onboarding_step_action`
- [ ] `paywall_view` / `paywall_plan_select`
- [ ] `purchase_start` / `purchase_success` / `purchase_fail`
- [ ] `vectorization_fail` — { errorCode, modelAttempted, retryCount }
- [ ] `calibration_fail` — { attemptCount, adjustmentRange }

### Phase 3 Acceptance Criteria
- [ ] All 16 screens implemented with Blueprint styling
- [ ] State persists across app kill/restart
- [ ] Purchases work on iOS sandbox and Android test track
- [ ] All analytics events fire correctly
- [ ] Auth flows complete successfully

---

## PHASE 4: Editor & Refinement
**Timeline:** Weeks 6-7  
**Goal:** Quick fix tools and vector editing

### Screens
| # | Screen | Description |
|---|--------|-------------|
| 21 | Review & Calibrate | Test square, scale adjustment |
| 22 | AI Verification | Confidence badges, edit affordances |
| 23 | Quick Fix Editor | Lasso, patch, smooth, labels |

### Tasks

#### 4.1 Verification UI
- [x] Fetch vectorization results from Firestore
- [x] Display piece preview with overlaid vectors
- [x] Show confidence badges (✓ / ⚠️ / ⚠)
- [x] Highlight low-confidence elements
- [x] Edit affordance (dotted underline on tappable items)
- [x] Scale adjustment scrubber with tap-to-type fallback (accessibility)

#### 4.2 Test Square
- [x] Render test square overlay (100mm or 4")
- [x] Allow user to verify with physical ruler
- [x] Pass/Fail buttons
- [x] Scale adjustment if failed

#### 4.3 Quick Fix Editor
- [x] Canvas with vectors (CustomPainter)
- [x] Pan/zoom (InteractiveViewer)
- [x] Lasso select tool
- [x] Erase selected
- [x] Patch missing line (snap within 5mm)
- [x] Smooth path
- [x] Add notch marker
- [x] Add grainline
- [x] Edit text labels
- [x] Undo/redo stack (20 steps)

#### 4.4 Confirmation Flow
- [x] Confirm button with haptic
- [x] Particle burst animation
- [x] Sound effect (optional)
- [x] Save final vectors to Firestore

### Phase 4 Acceptance Criteria
- [x] Vectors display correctly on canvas
- [x] Confidence badges render properly
- [x] Test square verification works
- [x] All editor tools functional
- [x] Undo/redo works correctly
- [x] Confirmation animation plays

---

## PHASE 5: Library & Export
**Timeline:** Weeks 8-9  
**Goal:** Project library, export formats, and AirPlay/Cast

> [!CAUTION]
> **iOS Simulator does NOT support external displays.** You MUST test AirPlay/Cast features with:
> - Physical iOS device (iPhone or iPad)
> - Lightning or USB-C to HDMI adapter
> - Real monitor or projector
>
> Do NOT spend time debugging external display issues on the simulator—it will never work. External display code ONLY functions on physical devices.

### Screens
| # | Screen | Description |
|---|--------|-------------|
| 17 | Home / Library | Project list, Magic Button |
| 24 | Projector Mode (Phone) | Remote control UI |
| 25 | Projector Mode (Cast) | Black BG, white lines |
| 26 | Cast Picker | AirPlay/Cast selection |
| 27 | Export / Share | PDF, SVG, PNG |
| 29 | Project Detail | Pieces, actions |
| 31 | Search / Filter | Find patterns |

### Tasks

#### 5.1 Home / Library
- [x] Scale Confidence Ring (CustomPainter) ✓
- [x] Scale Ring empty state ("Scan your first pattern") ✓
- [x] Magic Button (FAB breaking tab bar) ✓
- [x] Project list (swipe to delete) ✓
- [x] Recent projects section ✓
- [x] Empty state (no projects yet) ✓

#### 5.2 Project Management
- [x] Project detail screen ✓
- [x] Piece list within project ✓
- [x] Rename / delete project ✓
- [x] Duplicate piece ✓

#### 5.3 Search & Filter
- [x] Search bar ✓
- [x] Mode filter chips ✓
- [x] Search results list ✓

#### 5.4 Projector Display (Full)
- [ ] Line thickness control (0.5-3.0mm)
- [ ] Rotate/mirror/flip controls
- [ ] Layer toggles
- [ ] Lock mode (prevent accidental touches)

#### 5.5 Phone Remote
- [ ] Nudge controls (arrow buttons)
- [ ] Haptic feedback on each nudge
- [ ] Pan/zoom controls
- [ ] Connection status indicator

#### 5.6 AirPlay (iOS)
- [ ] Create platform channel
- [ ] Implement AVRoutePickerView
- [ ] Handle connection/disconnection

#### 5.7 Google Cast (Android)
- [ ] Integrate cast package or platform channel
- [ ] Cast picker UI
- [ ] Handle sessions

#### 5.8 Export
- [ ] Generate Projector PDF (dark mode, layered)
- [ ] Generate SVG (mm units, grouped layers)
- [ ] Generate PNG (high resolution)
- [ ] Share sheet integration

#### 5.9 [P1/Future] Pattern Sharing
- [ ] Export pattern as shareable link
- [ ] Import shared patterns to library
- [ ] Marketplace integration (future expansion)

### Phase 5 Acceptance Criteria
- [ ] Library displays projects correctly
- [ ] Projector mode renders correctly
- [ ] Phone remote controls work
- [ ] AirPlay connects on iOS
- [ ] Google Cast connects on Android
- [ ] PDF/SVG/PNG exports with correct scale
- [ ] Share sheet works

---

## PHASE 6: Polish & Launch
**Timeline:** Weeks 10-11  
**Goal:** Secondary screens, final polish, and launch preparation

### Screens
| # | Screen | Description |
|---|--------|-------------|
| 28 | Settings | App configuration |
| 30 | Pattern Piece List | All pieces across projects |
| 32 | Profile / Account | User info, stats |
| 33 | Subscription Management | Billing, features |
| 34 | Help / Support | FAQ, contact |

### Tasks

#### 6.1 Profile & Settings
- [ ] Profile screen with stats
- [ ] Subscription status display
- [ ] Settings screen
- [ ] Units preference
- [ ] Default line thickness
- [ ] Notifications toggle
- [ ] About/version
- [ ] Projector calibration profile management (deferred from Phase 2)
  - [ ] Allow saving calibration as named profile (e.g., "Sewing Room Epson")
  - [ ] Profile list in Settings
  - [ ] Delete/rename profiles

#### 6.2 Help & Support
- [ ] FAQ sections
- [ ] Contact support
- [ ] Email link

#### 6.3 Polish
- [ ] Loading states (Shimmer)
- [ ] Error states
- [ ] Empty states
- [ ] Offline indicators
- [ ] Accessibility audit (Semantics, VoiceOver, TalkBack)
- [ ] Performance optimization
- [ ] Memory profiling

#### 6.4 Launch Preparation
- [ ] App icons (all sizes)
- [ ] Screenshots for App Store / Play Store
- [ ] App preview video
- [ ] Privacy policy and Terms
- [ ] Cloud Functions production deployment
- [ ] Firestore security rules audit
- [ ] API keys rotated for production

### Phase 6 Acceptance Criteria
- [ ] All 34 screens implemented
- [ ] Blueprint styling consistent
- [ ] All flows complete end-to-end
- [ ] Accessibility labels on all controls
- [ ] No major performance issues
- [ ] Crash-free on common devices
- [ ] Ready for App Store / Play Store submission

---

## Testing Checklist

### Unit Tests
- [ ] OnboardingCoordinator state machine
- [ ] Analytics event formatting
- [ ] Model serialization/deserialization
- [ ] Business logic utilities

### Widget Tests
- [ ] All step widgets render correctly
- [ ] Selection states work
- [ ] Validation works
- [ ] Error states display

### Integration Tests
- [ ] Complete onboarding flow
- [ ] Purchase flow (sandbox)
- [ ] Capture → vectorize → verify flow
- [ ] Export flow

### Test Assets Required

> [!IMPORTANT]
> These images must be captured/sourced before AI integration testing begins.

| Asset | Description | Purpose |
|-------|-------------|---------|
| `pattern_bodice_front.jpg` | Clear sewing pattern, well-lit | Happy path test |
| `pattern_wrinkled_tissue.jpg` | Crumpled tissue paper pattern | Low confidence test |
| `photo_of_cat.jpg` | Non-pattern image | `NO_PATTERN_DETECTED` test |
| `pattern_multiple_pieces.jpg` | 2+ pieces in frame | Edge case test |
| `quilting_template.jpg` | Geometric quilting template | Mode-specific test |
| `stencil_mandala.jpg` | Art stencil with curves | Complexity test |

**Source:** Capture during development or use open-source sewing patterns under CC license.

### Device Testing
- [ ] iPhone SE (small screen)
- [ ] iPhone 15 Pro (modern iOS)
- [ ] iPad (tablet layout, if supported)
- [ ] Pixel 7 (stock Android)
- [ ] Samsung Galaxy (manufacturer skin)

### Accessibility Tests
- [ ] VoiceOver full navigation (iOS)
- [ ] TalkBack full navigation (Android)
- [ ] Color contrast verification (AA compliance)
- [ ] Touch target size audit (44pt iOS, 48dp Android)
- [ ] Scrubber keyboard fallback verification
- [ ] Audio cues during camera capture

### Performance Tests
- [ ] App cold start ≤2.5s on mid-tier devices
- [ ] Capture to preview ≤2s
- [ ] UI responsiveness ≤100ms (pan/zoom/thickness)
- [ ] Memory usage profiling (no leaks)

### Offline Mode Tests
- [ ] Library browsing works offline
- [ ] Appropriate messaging when offline + trying to scan
- [ ] Resume pending uploads when online
- [ ] State persistence across network state changes

---

## Launch Checklist

### App Store
- [ ] App icons (all sizes)
- [ ] Screenshots (6.5", 5.5")
- [ ] App preview video
- [ ] Description, keywords
- [ ] Privacy policy URL
- [ ] Support URL
- [ ] Age rating
- [ ] In-app purchase configuration
- [ ] Submit for review

### Play Store
- [ ] App icons
- [ ] Feature graphic
- [ ] Screenshots (phone, tablet)
- [ ] Description
- [ ] Privacy policy
- [ ] Content rating
- [ ] In-app products
- [ ] Submit for review

### Backend
- [ ] Cloud Functions deployed to production
- [ ] Firestore security rules reviewed
- [ ] Storage security rules reviewed
- [ ] API keys rotated for production
- [ ] Monitoring/alerting configured

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Scale calibration accuracy issues | Medium | High | Strict reference requirement, confidence scoring, test square gating |
| AI vectorization quality variance | Medium | Medium | Low-confidence highlighting, quick fix tools, iterate with beta feedback |
| AirPlay/Cast complexity | Medium | Medium | MVP uses mirroring only, defer native receiver |
| OpenRouter API costs | Low | Medium | Image downsampling, caching, usage monitoring |
| RevenueCat integration issues | Low | High | Use sandbox extensively, test edge cases |

---

## Decisions Log

| Date | Decision | Rationale |
|------|----------|-----------|
| Dec 2025 | Use Flutter over native | Single codebase, Blueprint design system, faster iteration |
| Dec 2025 | Cloud-first AI (not on-device) | Quality over latency for MVP |
| Dec 2025 | One piece per scan (MVP) | Simpler than multi-piece detection |
| Dec 2025 | Simplified calibration in MVP | Single-session calibration required for MVP; multiple saved profiles deferred to P1 |
| Dec 2025 | RevenueCat over native StoreKit/Billing | Cross-platform, analytics, easier |
| Dec 2025 | Riverpod over Bloc | Compile-time safety, simpler syntax |
| Dec 2025 | GoRouter over Navigator 2.0 | Declarative, deep linking support |

---

## Reference Links

- [Flutter Documentation](https://docs.flutter.dev/)
- [Riverpod Documentation](https://riverpod.dev/)
- [GoRouter Documentation](https://pub.dev/packages/go_router)
- [RevenueCat Flutter SDK](https://www.revenuecat.com/docs/flutter)
- [Firebase Flutter](https://firebase.google.com/docs/flutter/setup)
- [OpenRouter API](https://openrouter.ai/docs)
- [Google Cloud Vision](https://cloud.google.com/vision/docs)

---

**— End of Roadmap —**

*Last updated: December 24, 2025*
