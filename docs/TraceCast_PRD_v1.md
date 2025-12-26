# TraceCast: Scan-to-Projector
## Product Requirements Document

**Version 1.0 | December 2025**

AI-Powered Pattern Digitization & Projection

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Problem Statement](#2-problem-statement)
3. [Target Users & Personas](#3-target-users--personas)
4. [UI/UX Design System: The Blueprint Paradigm](#4-uiux-design-system-the-blueprint-paradigm)
5. [Onboarding System (Critical Path)](#5-onboarding-system-critical-path)
6. [Feature Specification](#6-feature-specification)
7. [Screen-by-Screen Specification](#7-screen-by-screen-specification)
8. [Technical Architecture](#8-technical-architecture)
9. [Non-Functional Requirements](#9-non-functional-requirements)
10. [Development Phases](#10-development-phases)
11. [Analytics & Instrumentation](#11-analytics--instrumentation)
12. [Appendices](#12-appendices)
    - [12.0 AI Prompt Engineering Appendix](#120-ai-prompt-engineering-appendix)

---

## 1. Executive Summary

### Product Vision

TraceCast: Scan-to-Projector transforms any physical pattern or template into a projector-ready digital overlay in minutes. Users capture a paper pattern with guided camera assistance, the app corrects distortion and extracts clean vectors using AI, then projects the result at true scale with fabric-friendly display and phone-as-remote casting.

### Core Value Proposition

**"True-to-scale Scan-to-Projector in minutes, without desktop software or manual tracing."**

### Target Platforms

iOS and Android with feature parity for core workflow at launch.

### Business Model

**Subscription-only with hard paywall. No free tier.**

| Plan | Price | Trial |
|------|-------|-------|
| Monthly | $3.99/month | No trial (immediate billing) |
| Annual | $29.99/year | 3-day free trial |

**Annual Savings:** 37% discount vs. monthly ($47.88 → $29.99)

### Success Metrics & KPIs

#### Activation & Core Value
| Metric | Target |
|--------|--------|
| Time-to-Value (TTV) | ≤ 5 minutes from "New Project" to "Projected at true scale" |
| Scale Pass Rate | ≥90% verify test square within tolerance |
| Vectorization Success Rate | ≥95% produce usable cutline output |

#### Monetization
| Metric | Target |
|--------|--------|
| Trial-to-Paid Conversion (Annual) | 40%+ |
| Annual Plan Selection Rate | 70%+ |
| Monthly Churn | ≤5% |

---

## 2. Problem Statement

### User Pain Points

#### 1. Digitizing Paper Patterns is Slow and Technical
- Current digitization requires desktop vector tools and manual Bezier tracing
- Wrinkles, translucency, stains, and shadows cause generic "auto-trace" to fail

#### 2. Accurate Scale is Non-Negotiable
- Small scaling errors lead to garments that don't fit or parts that don't assemble
- Most scanning apps output raster images that pixelate when projected large

#### 3. Projection Requires Special Formatting
- "Normal PDFs" (white background) wash out contrast and light the room
- Users need dark mode, line-thickness tuning, mirroring/rotation, and projector calibration

#### 4. Workflow Fragmentation
Users bounce between scanner apps, desktop vector tools, PDF tools, projector viewer/calibrators, and casting solutions. TraceCast consolidates this into a single mobile workflow.

---

## 3. Target Users & Personas

### Primary Persona: Projector Sewist

| Attribute | Description |
|-----------|-------------|
| Age Range | 28-55 |
| Behaviors | Sews weekly; owns 20-200 paper patterns; active in Facebook groups; willing to pay for time-saving tools |
| Motivations | Faster cutting, avoid printing/taping, avoid crawling on floor, preserve vintage patterns |
| Pain Threshold | Will abandon if scale is unreliable or calibration is confusing |

### Secondary Personas

**Quilter / Template Crafter**
Ages 35-70. Template-heavy projects with repeated shapes. Values speed, repeatability, and accurate replication.

**Cosplay / Props Maker**
Ages 16-40. Uses foam, leather, fabric. Modifies patterns and shares files. Values fast scaling to body size and clean outlines for export.

**Mural / Sign / Stencil Artist**
Ages 20-55. Scales sketches, uses projectors, struggles with keystone distortion. Values accurate transfer at large scale with minimal prep.

### Jobs-to-be-Done (JTBD)

#### Primary JTBD
> "When I have a physical pattern/template and want to cut/trace accurately using a projector, I need a fast way to digitize it at true scale so I can project it clearly without desktop tools."

#### Functional Needs
Accuracy, speed, compatibility (AirPlay/Cast), export formats (PDF, SVG, PNG)

#### Emotional Needs
Confidence ("it will fit"), reduced frustration, feeling modern and organized

---

## 4. UI/UX Design System: The Blueprint Paradigm

TraceCast adopts the "Blueprint" visual paradigm—a Light Blue ambient substrate with White typography and elements. This aesthetic evokes sewing patterns, engineering schematics, and architectural blueprints, creating instant trust and professional credibility with our target users who work with paper patterns daily.

### 4.1 Design Philosophy: Verification-First Interface

#### The Supervisor Model

TraceCast is not an "Input-First" app where users perform data entry. It is a **"Verification-First"** system where the AI performs the labor (identifying cutlines, extracting markings, measuring scale) and the user's role is reduced to a binary function: **Confirm or Correct**.

**Legacy Hierarchy:**
```
Search Bar (Top) → List View (Center) → Keyboard (Bottom)
```

**TraceCast AI-First Hierarchy:**
```
Camera Viewfinder (Background) → Result Overlay (Floating) → Confirmation Button (Primary)
```

#### The "Magic Moment" and Latency Management

The core value proposition is the **"Magic Moment"**—the few seconds where a chaotic image of wrinkled tissue paper is transmuted into clean, editable vectors with scale metadata. The interface must hide AI latency through theatrical loading states that visualize the thinking process.

**Engineering Requirement:**
- When user snaps photo, immediately display scanning animation (laser sweep, bounding boxes appearing)
- Show AI "identifying" elements in real-time (even if partially simulated)
- This makes wait feel like "processing" rather than "lagging" and builds trust in rigor

### 4.2 Color System: The Blueprint Palette

The "Light Blue" cannot be pastel—it must be a **Mid-Tone Architectural Blue** rich enough to support white text while meeting WCAG AA accessibility standards. Think blueprint paper, medical scrubs, or technical schematics.

#### Design Tokens

| Token | Value | Usage |
|-------|-------|-------|
| `primaryBackground` | `#4A90E2` | Steel Blue canvas (replaces white) |
| `primaryForeground` | `#FFFFFF` 100% | Main text, icons |
| `secondaryForeground` | `#FFFFFF` 70% | Subtitles, metadata |
| `tertiaryForeground` | `#FFFFFF` 40% | Placeholders, disabled |
| `accentAction` | `#FF9F43` | Safety Orange CTAs |
| `surfaceOverlay` | `#357ABD` | Cards, modals (darker blue for depth) |
| `errorState` | `#FF6B6B` | Soft red for alerts |
| `successState` | `#2ECC71` | Emerald green |

#### Luminance Layering (Depth Without Shadows)

Black shadows look "muddy" on blue backgrounds. Use **Luminance Layering** instead:

| Level | Value | Usage |
|-------|-------|-------|
| Level 0 (Background) | `#4A90E2` | Mid Blue |
| Level 1 (Cards) | `#5DADE2` (Lighter) or `#3A78C2` (Darker) | Elevated surfaces |
| Level 2 (Floating) | `#FFFFFF` | Pure White |
| Shadows | `#1A2530` at 20% opacity | Deep Navy |

### 4.3 Typography System

White text on colored backgrounds suffers from "optical blooming"—light bleeds into surrounding color, making text appear bolder. Apply these corrections:

- **Weight Correction:** Reduce font weights by one step (Bold → Semi-Bold, Regular → Light)
- **Letter Spacing:** Increase tracking +1% to +2% to prevent character blurring

#### Type Scale

| Style | Size | Weight | Color |
|-------|------|--------|-------|
| H1 (Dashboard Value) | 48sp | Semi-Bold | White 100% |
| H2 (Page Title) | 24sp | Medium | White 100% |
| Body (List Item) | 16sp | Regular | White 100% |
| Caption (Metadata) | 12sp | Light | White 70% |

### 4.4 Core Component Library

#### The Scale Confidence Ring (Dashboard)

The dashboard is dominated by a circular progress chart showing "Scale Confidence" or "Session Progress." This monochromatic approach reduces anxiety—white-on-blue feels informational, not judgmental.

| Property | Specification |
|----------|---------------|
| Geometry | Large ring chart occupying top 40% of screen |
| Track (Background) | White at 15% opacity |
| Fill (Progress) | Pure White (#FFFFFF) |
| Center Data | Large Semi-Bold White typography (e.g., "98%") |
| Label | Small uppercase White text (e.g., "SCALE VERIFIED") |

#### The "Magic Button" (Floating Action Button)

The primary interaction point—"Scan Pattern"—must be the most visible element on screen.

| Property | Specification |
|----------|---------------|
| Shape | Perfect circle, 64pt × 64pt |
| Position | Center of Tab Bar, breaking horizon line (floating upward) |
| Color | Pure White (#FFFFFF) background |
| Icon | Blueprint Blue (#4A90E2)—inverted to signal interaction |
| Animation | On tap, expands radially to fill screen, transitioning into Camera Viewfinder |

#### Pattern List (The Data Stream)

| Element | Specification |
|---------|---------------|
| Container | No bounding boxes—items float directly on blue background |
| Separators | Full-width White lines, 1px height, 10% opacity |
| Thumbnail | Square image with 8px corner radius and 2px solid White border |
| Title | White, Medium weight |
| Subtitle | White, 60% opacity |
| Swipe Action | Reveals #FF6B6B background for delete |

#### Navigation System

| Element | Specification |
|---------|---------------|
| Tab Bar | Gradient fade from Deep Blue to Transparent |
| Icons | Thin-stroke vectors in White (Active: 100%, Inactive: 50%) |
| Header | Transparent with Glassmorphism blur on scroll |

### 4.5 Camera Capture Interface

The camera is the heart of TraceCast. The Blueprint theme creates a "Technical Instrument" aesthetic.

#### Viewfinder UI

| Element | Specification |
|---------|---------------|
| Overlay | Technical Reticle (corner brackets, center crosshair, dynamic coordinate numbers) |
| Color | Pure White lines on camera feed |
| Grid Detection | When cutting mat detected, overlay green highlight on grid lines |
| Shutter | The Magic Button anchors the bottom |
| Mode Slider | "Pattern" \| "Marker" \| "Credit Card" (selected = White, others = translucent) |

#### Analysis Animation

After capture, display a scanning animation to visualize AI processing:

1. White laser sweep moving across the flattened image
2. Bounding boxes appearing around detected elements
3. Status text: "Detecting cutlines..." → "Extracting markings..." → "Reading labels..."
4. **Minimum display time: 3-5 seconds** (builds perceived rigor)

### 4.6 AI Verification Interface

Addressing the "Black Box" problem—users must understand and trust AI decisions.

#### The Verification Card

| Element | Specification |
|---------|---------------|
| Container | Modal sheet sliding up from bottom (Light Blue #357ABD) |
| High Confidence (≥80%) | White checkmark |
| Medium Confidence (50-79%) | Orange warning icon |
| Low Confidence (<50%) | Red triangle—"Verify this" |
| Edit Affordance | Item titles underlined with dotted White line—tap to edit |
| Scale Adjustment | Horizontal scrubber (sliding ruler) for mm/inch values. **Accessibility:** Allow tapping the numeric value to open a numeric keypad for exact input. |

#### The Confirmation Moment

When user confirms accurate vectorization:

| Feedback | Specification |
|----------|---------------|
| Effect | Burst of White and Silver particles |
| Haptic | Sharp "Success" vibration |
| Sound | Clean mechanical chime (camera shutter or lock click) |

### 4.7 Projector Mode Interface

| Element | Specification |
|---------|---------------|
| Background | Pure Black (#000000) for maximum line contrast |
| Lines | Pure White or Neon options (#FFFFFF, #00FF00, #00FFFF) |
| Phone Remote | Blueprint Blue interface with White controls |
| Nudge Controls | Arrow buttons with haptic feedback on each tap |
| Lock Mode | Screen dims and displays padlock icon—prevents accidental touches |

### 4.8 Component Cheat Sheet

| Component | Background | Text/Icon | Border | Radius | Shadow |
|-----------|------------|-----------|--------|--------|--------|
| Primary Button | #FFFFFF | #4A90E2 | — | 50px | 0px 4px 12px rgba(26,37,48,0.15) |
| Card | #4A90E2 or #5AA0EB | #FFFFFF | 1px solid rgba(255,255,255,0.2) | 16px | — |
| Input | rgba(255,255,255,0.15) | #FFFFFF | — | 8px | — |
| Toggle (Off) | rgba(255,255,255,0.2) | #FFFFFF (thumb) | — | 50px | — |
| Toggle (On) | #2ECC71 | #FFFFFF (thumb) | — | 50px | — |

**Animation Standards:**
- Ease: `cubic-bezier(0.25, 0.1, 0.25, 1.0)`
- Spring: tension 180, friction 12
- Duration: 300ms (standard), 500ms (modals)

---

## 5. Onboarding System (Critical Path)

Onboarding is the single most important determinant of user activation and conversion. TraceCast uses an exhaustive onboarding funnel that builds psychological investment before presenting the hard paywall. By the time users reach pricing, they have invested 3-5 minutes of effort and are primed to convert.

### 5.1 Monetization Strategy

#### Hard Paywall with Annual Trial Incentive

| Aspect | Specification |
|--------|---------------|
| Free Tier | None—users cannot access the app without a subscription |
| Monthly Plan | $3.99/month — No trial (immediate billing) |
| Annual Plan | $29.99/year — 3-day free trial (payment method required) |

**Strategic Rationale:** Trial on annual plan drives higher LTV; users who trial are more likely to forget to cancel and have longer retention.

### 5.2 Four-Phase Funnel Structure

| Phase | Screens | Purpose |
|-------|---------|---------|
| Trust + Framing | 1-4 | Establish credibility around scale accuracy and AI extraction |
| Personalization | 5-10 | Collect project type, equipment, experience level, and pain points |
| Value Preview | 11-13 | "Calculate" their personalized setup; build anticipation |
| Conversion | 14-16 | Account creation, paywall with timeline, and activation |

### 5.3 Complete Onboarding Flow

**Total Steps:** 16 screens | **Estimated Time:** 3-5 minutes | **Target Completion Rate:** 60%+

---

#### Phase 1: Trust + Framing (Screens 1-4)

##### Screen 1: Welcome Splash

| Property | Value |
|----------|-------|
| Type | `intro` |
| Visual | Blueprint Blue background; White vector animation of pattern transforming to projected overlay |
| Title | "Paper patterns, meet the future" |
| Subtitle | "Scan. Flatten. Project. Cut." |
| Primary CTA | "Get Started" (White pill button) |
| Secondary | "I already have an account" (White text link) |

##### Screen 2: Scale Accuracy Promise

| Property | Value |
|----------|-------|
| Type | `info` |
| Title | "True-to-scale, guaranteed" |
| Content | "Our reference-based calibration ensures ±0.5% accuracy. Every pattern piece fits exactly as intended." |
| Visual | Split-screen: blurry phone photo vs. crisp TraceCast output with measurement overlay |

##### Screen 3: AI Extraction Demo

| Property | Value |
|----------|-------|
| Type | `info` |
| Title | "AI sees what you need" |
| Content | "Our pattern-trained AI ignores wrinkles, shadows, and stains. Clean cutlines, notches, and labels—automatically." |
| Visual | Before/after animation: wrinkled tissue paper → clean White vectors on Blue |

##### Screen 4: Social Proof

| Property | Value |
|----------|-------|
| Type | `info` |
| Title | "Join thousands of makers" |
| Stats | "50,000+ patterns digitized" \| "4.8★ App Store Rating" \| "Used in 40+ countries" |
| Testimonial | Rotating quotes from real users (with photos) |

---

#### Phase 2: Personalization (Screens 5-10)

##### Screen 5: Primary Project Type

| Property | Value |
|----------|-------|
| Type | `single_select` |
| Question ID | `project_type` |
| Title | "What will you create?" |
| Options | Clothing & Garments \| Home Decor & Bags \| Quilting \| Cosplay & Props \| Stencils & Art \| Woodworking |
| Visual | Large tappable cards (Blue BG, White border when unselected; White BG, Blue text when selected) |

##### Screen 6: Pattern Library Size

| Property | Value |
|----------|-------|
| Type | `single_select` |
| Question ID | `library_size` |
| Title | "How many paper patterns do you own?" |
| Options | Just getting started (1-5) \| Building a collection (6-20) \| Serious hobbyist (21-50) \| Pattern hoarder (50+) |

##### Screen 7: Current Pain Points

| Property | Value |
|----------|-------|
| Type | `multi_select` |
| Question ID | `pain_points` |
| Title | "What frustrates you most?" |
| Options | Tracing takes forever \| Scale never matches \| Printing and taping \| Crawling on the floor \| Patterns getting damaged \| Storage space |
| Validation | `minSelected: 1` |

##### Screen 8: Projector Status

| Property | Value |
|----------|-------|
| Type | `single_select` |
| Question ID | `projector_status` |
| Title | "Do you have a projector?" |
| Options | Yes, all set up \| Yes, need help setting up \| Planning to get one \| No, interested in PDF export |

##### Screen 9: Reference Equipment

| Property | Value |
|----------|-------|
| Type | `single_select` |
| Question ID | `has_cutting_mat` |
| Title | "Do you have a gridded cutting mat?" |
| Subtitle | "We use the grid for guaranteed scale accuracy" |
| Options | Yes, with grid lines \| Yes, no grid \| No, but I'll get one \| No |

##### Screen 10: Units Preference

| Property | Value |
|----------|-------|
| Type | `single_select` |
| Question ID | `units` |
| Title | "How do you measure?" |
| Options | Metric (mm/cm) \| Imperial (inches) |
| Default | Auto-detect from device locale |

---

#### Phase 3: Value Preview (Screens 11-13)

##### Screen 11: "Calculating" Your Setup

| Property | Value |
|----------|-------|
| Type | `progress_loading` |
| Visual | Complex CAD-style diagram drawing itself in White lines on Blue background |
| Text Sequence | "Analyzing your workflow..." → "Optimizing for [project_type]..." → "Calibrating scale settings..." |
| Duration | **Force 5-second minimum** (builds anticipation and perceived value) |
| Purpose | Creates psychological investment; user feels app is personalizing for them |

##### Screen 12: Personalized Setup Preview

| Property | Value |
|----------|-------|
| Type | `summary_preview` |
| Title | "Your TraceCast is ready" |
| Content | Dynamic summary based on answers |
| Visual | Animated mockup of their first scan → project flow |

**Dynamic Content:**
- "Optimized for [project_type]"
- "Ready to digitize your [library_size]+ patterns"
- "No more [primary pain point]"
- "Scale Guaranteed" badge (if `has_cutting_mat`)

##### Screen 13: Notification Rationale

| Property | Value |
|----------|-------|
| Type | `permission_prompt` |
| Title | "Never miss a scan" |
| Content | "Get notified when vectorization completes and receive tips for better results." |
| Optional | `true` (can skip) |
| Timing | After value established, before paywall |

---

#### Phase 4: Conversion (Screens 14-16)

##### Screen 14: Account Creation

| Property | Value |
|----------|-------|
| Type | `account_prompt` |
| Title | "Save your patterns forever" |
| Content | "Create an account to sync patterns across devices and never lose your work." |
| Options | Sign in with Apple (preferred) \| Sign in with Google \| Continue with Email |
| Skip | **Not allowed** (account required for subscription) |

##### Screen 15: Paywall (Critical)

| Property | Value |
|----------|-------|
| Type | `paywall` |
| Title | "Unlock TraceCast" |

**Personalized Headline (based on `pain_points`):**

| Pain Point | Headline |
|------------|----------|
| `tracing_takes_forever` | "Skip the tracing—scan and project in minutes" |
| `scale_errors` | "Guaranteed accurate scale with every scan" |
| `floor_crawling` | "Cut standing up—project directly onto your table" |

**Timeline Graphic (Trust Builder):**

Horizontal White timeline on Blue background:

```
[Today]─────────────[Day 2]─────────────[Day 3]
   │                   │                   │
"Full access      "Reminder          "Trial ends,
 unlocked"        notification"       billing begins"
```

**Pricing Cards:**

| Plan | Price | Badge | Subtext | Trial |
|------|-------|-------|---------|-------|
| Annual (Highlighted) | $29.99/year | "Best Value" (orange glow) | "Then $2.50/month" | 3-Day Free Trial |
| Monthly | $3.99/month | — | "Billed today" | No trial |

**CTAs:**
- **Primary:** "Start Free Trial" (White pill button) — Only shows when Annual selected
- **Secondary:** "Subscribe Now" — Shows when Monthly selected
- **Footer:** "Restore Purchases" link \| Terms \| Privacy
- **No Dismiss:** Hard paywall — cannot proceed without selection

##### Screen 16: Camera Permission + First Scan

| Property | Value |
|----------|-------|
| Type | `permission_prompt` + `activation` |
| Title | "Let's digitize your first pattern" |
| Content | "Point your camera at any pattern piece to experience the magic." |
| Camera Permission | Trigger OS prompt after rationale |
| CTA | "Open Camera" — Transitions directly to capture interface |

---

### 5.4 Onboarding Analytics Events

#### Core Step Events

```
onboarding_step_view: { stepId, stepType, flowId, variantId }
onboarding_step_action: { stepId, action: next|back|skip }
onboarding_answer: { questionId, answerId }
```

#### Monetization Events

```
paywall_view: { source: onboarding, preselected_plan }
paywall_plan_select: { planId: monthly|annual }
purchase_start: { planId, priceUsd, hasTrial }
purchase_success: { planId, priceUsd, transactionId }
purchase_fail: { planId, errorCategory }
```

#### Error & Quality Events

```
vectorization_fail: { errorCode, modelAttempted, retryCount, imageSizeKb }
calibration_fail: { attemptCount, adjustmentRange, userAborted }
offline_scan_blocked: { }
```

---

### 5.5 Onboarding Data Model

The following data structure captures the complete onboarding session state for persistence and analytics:

#### OnboardingSession Schema

```typescript
interface OnboardingSession {
  sessionId: string;           // UUID, stable across restarts
  startedAt: timestamp;
  updatedAt: timestamp;
  flowId: string;              // e.g., "tracecast_onboarding_v1"
  variantId: string;           // A/B assignment, e.g., "paywall_annual_first"
  currentStepId: string;
  completedStepIds: string[];
  answers: Record<questionId, answerValue>;
  flags: {
    isAuthenticated: boolean;
    hasSeenPaywall: boolean;
    hasPurchased: boolean;
    selectedPlan: string | null;
    cameraPermissionGranted: boolean;
    notificationsGranted: boolean;
  };
}
```

#### Derived Segments (computed from answers)

| Segment | Values | Source |
|---------|--------|--------|
| `user_segment` | sewist \| quilter \| cosplayer \| stencil_artist \| maker | `project_type` |
| `projector_readiness` | ready \| needs_setup \| planning \| export_only | `projector_status` |
| `scale_capability` | guaranteed (has gridded mat) \| standard (no grid) | `has_cutting_mat` |
| `library_tier` | starter (1-5) \| growing (6-20) \| serious (21-50) \| power (50+) | `library_size` |
| `primary_pain` | tracing \| scale \| printing \| floor \| damage \| storage | `pain_points[0]` |

---

### 5.6 A/B Testing Roadmap

Implement these experiments via remote config to optimize conversion without code changes:

| Experiment | Variants | Hypothesis |
|------------|----------|------------|
| Paywall Plan Order | Annual first (current) vs. Monthly first | Annual-first drives higher selection rate |
| Trial Length | 3-day (current) vs. 7-day on annual | Longer trial increases conversion |
| Onboarding Length | Full 16-screen vs. condensed 10-screen | Shorter may reduce drop-off |
| Trust Framing | Scale accuracy vs. AI technology vs. time-saving | Different messaging resonates with segments |
| Social Proof Placement | Early (Screen 4) vs. just before paywall | Later placement may be more persuasive |
| Personalization Depth | 6 questions vs. 3 questions (minimal) | Investment vs. friction trade-off |
| "Calculating" Duration | 5 seconds (current) vs. 3 vs. 8 seconds | Optimal perceived value timing |
| Post-Decline Offer | No offer vs. 20% discount on monthly | Rescue declining users |

---

### 5.7 Implementation Architecture

#### Core Components (Flutter/Dart)

| Component | Responsibility |
|-----------|----------------|
| `OnboardingCoordinator` | State machine (using Riverpod/Bloc) managing step flow, branching, validation, and persistence |
| `StepRenderer` | Widget factory that returns the correct screen widget for each step type |
| `OnboardingRepository` | Local persistence using `flutter_secure_storage` (encrypted) |
| `AnalyticsService` | Single entry point wrapping `firebase_analytics` for all onboarding events |
| `RemoteConfigService` | Wraps `firebase_remote_config` for flow config and A/B variant assignments |

#### Step Widget Library

Build these reusable widgets with Blueprint styling, consistent layout, validation, haptics, and accessibility:

| Widget | Usage |
|--------|-------|
| `IntroStepWidget` | Welcome screens with Lottie/Rive hero animation |
| `InfoStepWidget` | Value propositions, social proof, feature explanations |
| `SingleSelectStepWidget` | Large tappable cards with Blueprint selection state |
| `MultiSelectStepWidget` | Checkbox-style selection with minimum validation |
| `ProgressStepWidget` | "Calculating" animation with `CustomPainter` CAD-style drawing |
| `SummaryStepWidget` | Personalized setup preview with dynamic content |
| `PermissionStepWidget` | Rationale screen → `permission_handler` → handle all outcomes |
| `AccountStepWidget` | `sign_in_with_apple`, `google_sign_in`, email/password |
| `PaywallStepWidget` | Timeline graphic, plan cards, RevenueCat purchase flow, restore |

#### Project Structure
```
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── router.dart                    # GoRouter or AutoRoute
│   └── theme/
│       ├── blueprint_theme.dart       # ThemeData + ColorScheme
│       ├── blueprint_colors.dart      # Design tokens
│       └── blueprint_typography.dart  # TextTheme with weight corrections
├── core/
│   ├── services/
│   │   ├── analytics_service.dart
│   │   ├── remote_config_service.dart
│   │   └── api_client.dart
│   ├── utils/
│   └── constants/
├── features/
│   ├── onboarding/
│   │   ├── data/
│   │   │   ├── onboarding_repository.dart
│   │   │   └── models/
│   │   │       ├── onboarding_session.dart
│   │   │       ├── step_definition.dart
│   │   │       └── onboarding_answer.dart
│   │   ├── domain/
│   │   │   └── onboarding_coordinator.dart
│   │   ├── presentation/
│   │   │   ├── onboarding_screen.dart
│   │   │   └── widgets/
│   │   │       ├── intro_step_widget.dart
│   │   │       ├── info_step_widget.dart
│   │   │       ├── single_select_step_widget.dart
│   │   │       ├── multi_select_step_widget.dart
│   │   │       ├── progress_step_widget.dart
│   │   │       ├── summary_step_widget.dart
│   │   │       ├── permission_step_widget.dart
│   │   │       ├── account_step_widget.dart
│   │   │       └── paywall_step_widget.dart
│   │   └── integrations/
│   │       ├── iap_integration.dart       # RevenueCat
│   │       ├── auth_integration.dart      # Apple/Google/Email
│   │       └── permissions_integration.dart
│   ├── capture/
│   ├── verification/
│   ├── editor/
│   ├── projector/
│   └── library/
├── shared/
│   └── widgets/
│       ├── magic_button.dart
│       ├── scale_confidence_ring.dart
│       ├── scrubber_input.dart
│       ├── blueprint_card.dart
│       └── pattern_list_tile.dart
└── platform_channels/
    ├── airplay_channel.dart
    └── cast_channel.dart
```

#### State Management Recommendation

Use **Riverpod** for its:
- Compile-time safety
- Easy testing and mocking
- Built-in async handling for API calls
- Natural fit for feature-based architecture
```dart
// Example: Onboarding state
@riverpod
class OnboardingCoordinator extends _$OnboardingCoordinator {
  @override
  OnboardingSession build() => OnboardingSession.initial();
  
  void nextStep() { /* ... */ }
  void previousStep() { /* ... */ }
  void submitAnswer(String questionId, dynamic value) { /* ... */ }
}
```
---

### 5.8 Onboarding Implementation Timeline

Phased implementation schedule for the onboarding system (Flutter):

| Week | Focus | Deliverables |
|------|-------|--------------|
| **Week 1** | Foundation | Project setup, `OnboardingCoordinator` (Riverpod), `OnboardingRepository` with `flutter_secure_storage`, step config schema (JSON), Blueprint theme setup |
| **Week 2** | Step Widgets (Part 1) | `IntroStepWidget`, `InfoStepWidget`, `SingleSelectStepWidget`, `MultiSelectStepWidget` with Blueprint styling and animations |
| **Week 3** | Step Widgets (Part 2) | `ProgressStepWidget` (CustomPainter CAD animation), `SummaryStepWidget`, `PermissionStepWidget` with `permission_handler` |
| **Week 4** | Auth & Monetization | `AccountStepWidget` (`sign_in_with_apple`, `google_sign_in`), `PaywallStepWidget` with timeline graphic, RevenueCat integration, restore purchases |
| **Week 5** | Analytics & Remote Config | Firebase Analytics event logging, `firebase_remote_config` variant assignment, funnel dashboards setup |
| **Week 6** | QA & Polish | Widget tests, integration tests, accessibility audit (`Semantics` widgets), edge cases (denied permissions, purchase failures, restore), state persistence verification |

#### Acceptance Criteria

- [ ] Onboarding flow completes end-to-end on iOS and Android simulators/devices
- [ ] State persists across app kill/restart at any step (verified via `flutter_secure_storage`)
- [ ] All analytics events fire with correct properties (verified in Firebase DebugView)
- [ ] RevenueCat purchase and restore work reliably across reinstalls
- [ ] A/B variants can be changed via Remote Config without app update
- [ ] Blueprint styling consistent across all step widgets
- [ ] Hot reload works throughout onboarding development (Flutter advantage)
- [ ] Widget tests cover all step types with >80% coverage

---

### 5.9 Onboarding Edge Cases

| Scenario | Handling |
|----------|----------|
| **Camera permission denied permanently** | Show "Camera Required" screen with button to open device Settings; explain why camera is essential; allow user to retry after granting permission |
| **User presses back on paywall** | Not allowed (hard paywall); back button navigates between pricing plans, not out of paywall |
| **Account creation fails** | Show inline error with retry; offer alternative auth methods; allow offline mode for browsing help/FAQ only |
| **Anonymous user later signs in** | Anonymous session data (onboarding answers) automatically linked to new authenticated account via Firebase Auth linking |
| **User force-quits mid-onboarding** | State persisted via `flutter_secure_storage`; resume exactly where left off on next launch |
| **Notification permission denied** | Continue silently; no blocking; user can enable later in Settings |
| **Purchase fails** | Show error category (network, cancelled, already owned); offer retry; log to analytics; don't block user from re-attempting |
| **Restore purchases finds nothing** | Show "No purchases found" with explanation; suggest contacting support if user believes they have a subscription |
| **Reinstall with valid Firebase Auth** | On launch, check RevenueCat for active entitlement. If found → skip directly to Home. If not → show paywall (user may have cancelled subscription). Local `hasSeenOnboarding` flag cleared on reinstall, but backend subscription state is authoritative. |
| **Trial expired on app launch** | Redirect to paywall with "Trial ended" messaging; show billing date for annual or immediate payment for monthly |

---

### 5.10 Projector Calibration Flow (First-Time Setup)

When user first enters Projector Mode, a calibration wizard guides them through setup:

#### Calibration Steps

> **MVP Scope:** Steps 1-4 are required for MVP. Steps 5-6 (profile saving/management) are deferred to a later release.

| Step | Screen | Description | MVP? |
|------|--------|-------------|------|
| 1 | Welcome | "Let's calibrate your projector" - explains why calibration ensures accurate scale | ✓ |
| 2 | Position | User positions a 4" or 100mm test square on their cutting surface | ✓ |
| 3 | Verify | "Does the projected square match your ruler exactly?" Yes/No | ✓ |
| 4 | Adjust (if No) | Scrubber to fine-tune scale (+/- 5%) with tap-to-type fallback; shows live preview on cast display | ✓ |
| 5 | Save Profile | "Save this calibration for future sessions?" Name the profile (e.g., "Sewing Room Epson") | P1 |
| 6 | Complete | "Calibration complete! You're ready to project." - CTA to continue | ✓ |

#### Calibration Data Model

```typescript
interface ProjectorProfile {
  profile_id: UUID;
  name: string;
  scale_adjustment: float;  // 1.0 = no adjustment, 0.95 = 5% smaller
  last_used: timestamp;
  created_at: timestamp;
  is_default: boolean;
}
```

#### Calibration Behavior

- **MVP:** First-time users MUST complete Steps 1-4 before using Projector Mode. Calibration stored in memory for current session only.
- **P1 (Deferred):** Returning users can save, name, and switch between profiles. "Saved Profiles" available in Settings > Projector.
- If scale confidence from capture is <80%, suggest recalibration

---

## 6. Feature Specification

**Priority Definitions:** P0 = MVP must-have | P1 = Next release | P2 = Future expansion

### 6.1 Mode Selection & Project Setup (P0)

| Aspect | Specification |
|--------|---------------|
| User Story | As a user, I want to choose what I'm scanning so the app optimizes detection for my project |
| Modes | Sewing Pattern, Quilt Template, Stencil/Art, Maker/CNC, Custom |
| Acceptance | User starts project in ≤2 taps from Home |

### 6.2 Guided Capture with Reference Detection (P0)

| Aspect | Specification |
|--------|---------------|
| User Story | As a user, I want the app to guide my scan so output is accurate and not distorted |
| Features | Technical reticle overlay, level indicator, auto-capture, reference detection (mat grid, markers, credit card) |
| Acceptance | App refuses without reference OR explicit override with warning |

#### Scale Reference Methods

TraceCast offers three reference detection modes, each with different accuracy levels:

| Reference Type | How It Works | Accuracy | User Requirements |
|----------------|--------------|----------|-------------------|
| **Gridded Mat** (Recommended) | App detects cutting mat grid lines via computer vision. Requires visible 1" or 2.5cm grid squares in frame. | ±0.5% **Scale Guaranteed** | Place pattern on cutting mat with at least 4 grid squares visible |
| **ArUco Markers** | User prints provided ArUco marker sheet. App detects coded markers for precise scale + orientation. | ±0.3% (highest) | Print marker sheet at 100% scale, place around pattern |
| **Credit Card** | User places standard credit card (85.6mm × 53.98mm) in frame. App detects card dimensions for scale. | ±1-2% (acceptable) | Any standard credit/ID card flat against pattern |
| **No Reference** | User manually enters known dimension (e.g., "this line is 10 inches"). Scale calculated from user input. | Variable (user-dependent) | User must know at least one accurate measurement |

**Reference Detection Behavior:**

1. **On Camera Open:** Mode slider defaults to "Pattern" (gridded mat detection)
2. **Real-time Feedback:** Green highlight on detected grid lines; orange warning if partial detection
3. **Auto-Capture:** When reference is solid for 1.5s and phone is steady, auto-capture triggers (can disable)
4. **No Reference Warning:** If user taps shutter without reference, modal warns: "Scale may be inaccurate. Continue anyway?" with "Add Reference" and "Continue Without" options
5. **Fallback Flow:** If grid not detected after 10s, suggest switching to Credit Card or Marker mode

**Manual Scale Input Flow (No Reference):**

When the user proceeds without a reference, the Review & Calibrate screen (Screen 21) must provide an intuitive way to set scale manually:

1. User taps "Manual Adjust" button
2. App prompts: "Draw a line across a known dimension"
3. User draws a line on the **perspective-corrected (flattened)** image (e.g., along a marking they know is 10 inches)
4. Scrubber or tap-to-type input appears: "How long is this line?"
5. User enters the known dimension (e.g., "10 in" or "254 mm")
6. App calculates px→mm scale from the drawn line length (using same coordinate system as AI output)
7. Scale Confidence Score updates to reflect user-provided scale (marked as "User Calibrated")

**ManualScaleInput Implementation:**

```dart
// lib/core/models/manual_scale_input.dart

class ManualScaleInput {
  final Offset startPoint;    // px on flattened image
  final Offset endPoint;      // px on flattened image
  final double knownLength;   // mm (from user input)
  final String unit;          // 'mm' or 'in'
  
  double get lineDistancePx => 
    (endPoint - startPoint).distance;
    
  double get pxPerMm => lineDistancePx / knownLength;
  double get mmPerPx => knownLength / lineDistancePx;
}
```

> [!NOTE]
> The user draws on the same **perspective-corrected** image that the AI analyzes, ensuring consistent coordinate systems between manual calibration and AI-detected paths.

### 6.3 De-warping & Scale Calibration (P0)

| Aspect | Specification |
|--------|---------------|
| User Story | As a user, I want the scan flattened and scaled correctly for true-to-size projection |
| Features | Homography computation, perspective transform, px→mm scale, test square overlay, Scale Confidence Score |
| Acceptance | Scale error within ±0.5% using mat grid reference |

#### 6.3.1 Perspective Transform Pipeline (Preprocessing)

> [!IMPORTANT]
> The AI vision model **analyzes** the image and extracts semantic vector data—it does NOT perform geometric transformations. Perspective correction must happen BEFORE the AI call.

**Pipeline Flow:**
```
Capture → [Corner Detection] → [Perspective Transform] → [Upload] → AI Vectorization → Scale Calibration
                ↑                        ↑
                └── OpenCV on-device ────┘
```

**Implementation Approach:**

| Step | Technology | Notes |
|------|------------|-------|
| Corner Detection | OpenCV `findContours` + `approxPolyDP` | Detect pattern edges, OR use ArUco markers for precise corners |
| Perspective Transform | OpenCV `getPerspectiveTransform` + `warpPerspective` | Flatten to top-down view |
| Processing Location | On-device (Flutter via `opencv_dart`) | Before upload to Cloud Function |

**ArUco Markers (Recommended for Highest Accuracy):**

For users who need maximum precision (±0.3%), provide printable ArUco marker sheets. ArUco markers are:
- Machine-readable with known dimensions
- Orientation-aware (auto-detect rotation)
- Robust to partial occlusion

**ArUco Configuration:**

| Setting | Value |
|---------|-------|
| Dictionary | `cv2.aruco.DICT_4X4_50` |
| Marker IDs | 0, 1, 2, 3 (one per corner) |
| Marker Size | 30mm × 30mm |
| Spacing | Markers placed at known spacing on reference sheet |
| Asset Path | `/assets/aruco_reference_sheet.pdf` |

> [!NOTE]
> **See `TraceCast_Appendix_Computer_Vision.md`** for complete ArUco detection parameters, platform-specific implementation (iOS/Android), fallback chain logic, and reference sheet PDF specifications.

> [!TIP]
> Users download the ArUco reference sheet from in-app help or website. The PDF must be printed at **100% scale (no fit-to-page)** for accurate detection.

**Fallback If No ArUco:**
1. Attempt grid detection on cutting mat
2. If grid detected → calculate perspective transform from grid intersections
3. If no grid → prompt user for manual corner selection (4-point touch interface)
4. Apply `warpPerspective` to flatten image before upload

#### 6.3.2 Scale Reference Detection Strategy

**Priority Order (Hybrid Approach):**

| Priority | Method | Accuracy | When Used |
|----------|--------|----------|-----------|
| 1 | ArUco Markers | ±0.3% | User places printed markers around pattern |
| 2 | Cutting Mat Grid | ±0.5% | Grid lines detected via OpenCV (primary automatic method) |
| 3 | Credit Card | ±1-2% | User places standard card in frame |
| 4 | User Manual Input | Variable | User draws line + enters known dimension |

**Coordinate Transformation Math:**

The Cloud Function transforms AI pixel coordinates to mm using the detected scale:

```typescript
// Scale factor calculation (happens in Cloud Function)
// Example: Cutting mat grid square detected as 100px wide, known to be 25.4mm (1 inch)
const referenceWidthPx = detectReferenceObject(image); // e.g., 100
const referenceWidthMm = config.reference_dimension_mm; // e.g., 25.4 (1 inch)
const scaleFactorMmPerPx = referenceWidthMm / referenceWidthPx; // 0.254 mm/px

// Transform all AI coordinates from px to mm
const mmPaths = aiResponse.layers.cutlines.map(path => ({
  ...path,
  points: path.points.map(([x, y]) => [x * scaleFactorMmPerPx, y * scaleFactorMmPerPx])
}));
```

**Scale Source of Truth:**
- **Primary:** Automatic detection (ArUco markers or cutting mat grid) — `scale_mm_per_px` calculated on-device
- **Fallback:** User-provided dimension via draw-a-line interface (see Section 6.2)
- The `scale_mm_per_px` value is passed from client to Cloud Function after reference detection

### 6.4 AI Semantic Vectorization (P0)

| Aspect | Specification |
|--------|---------------|
| User Story | As a user, I want automatic cutline extraction that ignores wrinkles |
| Outputs | Vector cutlines (mm), markings (darts, notches, grainline), OCR text with confidence scores |
| Acceptance | ≥1 closed cutline OR recapture prompt; 95% success rate |

### 6.5 Quick Fix Vector Editor (P0)

| Aspect | Specification |
|--------|---------------|
| User Story | As a user, I want quick tools to fix mistakes without Illustrator |
| Tools | Lasso erase, patch line (snaps within 5mm), smooth path, add notch/grainline, edit labels |
| Acceptance | Close gap in ≤15 seconds; 20-step undo/redo |

### 6.6 Projector Mode + Casting (P0)

| Aspect | Specification |
|--------|---------------|
| Features | Dark preset (black BG/white lines), line thickness control (0.5-3.0mm), rotate/mirror, layer toggles, lock mode, AirPlay/Cast |
| Acceptance | Thickness change <100ms; nudge with haptic feedback |

### 6.7 Export/Share (P0)

| Aspect | Specification |
|--------|---------------|
| Formats | Projector PDF (dark, layered), SVG (mm units, grouped), PNG |
| Acceptance | SVG correct viewBox; PDF maintains scale at 100% print |

### 6.8 Multi-Piece Pattern Handling (P0)

| Aspect | Specification |
|--------|---------------|
| User Story | As a user, I want to scan multiple pattern pieces and see them organized together in one project |
| Behavior | Each scan creates a new piece within the active project; pieces are displayed in a scrollable grid |
| Assembly Preview | "Preview All" button shows all pieces laid out together (mosaic view) for visual verification |
| Individual vs. Combined Export | Export single piece or all pieces in one PDF/SVG |
| Duplicate Piece | Long-press to duplicate a piece (e.g., "Cut 2" for symmetric pieces) |

### 6.9 Pattern Piece Version Control (P0)

| Aspect | Specification |
|--------|---------------|
| User Story | As a user, I want to see edit history and revert to the original AI extraction if needed |
| Version Stack | Each piece maintains up to 10 versions (original AI + user edits) |
| Revert | "Reset to Original" button available in Quick Fix Editor menu |
| Comparison View | Side-by-side toggle to compare current vs. original extraction |
| Auto-save | Versions auto-saved on: initial extraction, after each edit session (5+ changes or 30 seconds idle) |

### 6.10 P1/P2 Features (Brief)

| Priority | Features |
|----------|----------|
| P1 | Multi-shot stitching for oversized patterns, saved projector profiles + calibration wizard, pattern library & tagging |
| P1 | **Pattern Sharing** — Export pattern as shareable link or file; recipients can import into their TraceCast library |
| P2 | DXF export + maker utilities, seam allowance generation, collaboration/versioning |

---

## 7. Screen-by-Screen Specification

*Beyond onboarding (Section 5), the core app flow consists of these screens:*

| Screen | Purpose | Key Components |
|--------|---------|----------------|
| Home / Dashboard | Pattern library, quick actions | Scale Confidence Ring, Magic Button, Pattern List |
| Camera Capture | Guided pattern scanning | Technical Reticle, Reference Detection, Mode Slider |
| Processing | AI vectorization feedback | Laser Sweep Animation, Status Text Sequence |
| Verification | Review AI results | Verification Card, Confidence Badges, Edit Controls |
| Editor | Quick fix tools | Lasso, Patch, Smooth, Notch/Grainline, Labels |
| Projector Mode | Display for projection | Black BG, Line Controls, Layer Toggles, Lock Mode |
| Export | Share/save options | Format Cards, Share Sheet |
| Settings | App configuration | Units, Projector Profiles, Account, Subscription |

---

## 8. Technical Architecture

### 8.1 Technology Stack

| Layer | Technology |
|-------|------------|
| Mobile | **Flutter/Dart** (single codebase for iOS and Android) |
| State Management | Riverpod or Bloc |
| Computer Vision | OpenCV via `opencv_dart` package, platform channels for iOS Vision/ML Kit |
| Backend | Firebase (Firestore, Storage, Cloud Functions) |
| AI | OpenRouter API (model-agnostic LLM routing for vision models) |
| IAP | RevenueCat Flutter SDK |
| Analytics | Firebase Flutter plugins (Analytics, Crashlytics, Remote Config) |
| Casting | Platform channels for AirPlay (iOS), `cast` package for Google Cast (Android) |

#### Platform Channel Requirements

Thin native wrappers (~200 lines per platform) required for:
- **iOS**: AirPlay mirroring triggers via `AVRoutePickerView`
- **Android**: Google Cast session management (or use `cast` package)

#### Recommended pubspec.yaml Dependencies

```yaml
dependencies:
  # Core
  flutter:
    sdk: flutter
  
  # State Management & Navigation
  flutter_riverpod: ^2.4.9
  riverpod_annotation: ^2.3.3
  go_router: ^13.0.0
  
  # Camera & Image Processing
  camera: ^0.10.5+7
  image: ^4.1.3
  opencv_dart: ^1.0.0        # Perspective transform, grid detection
  
  # Firebase
  firebase_core: ^2.24.2
  firebase_auth: ^4.16.0
  cloud_firestore: ^4.14.0
  firebase_storage: ^11.5.6
  firebase_analytics: ^10.7.4
  firebase_crashlytics: ^3.4.9
  firebase_remote_config: ^4.3.8
  
  # PDF & Vector Export
  pdf: ^3.10.7
  printing: ^5.11.1
  flutter_svg: ^2.0.9
  path_drawing: ^1.0.1
  
  # IAP & Monetization
  purchases_flutter: ^6.17.0
  
  # Storage & Offline
  shared_preferences: ^2.2.2
  flutter_secure_storage: ^9.0.0
  hive_flutter: ^1.1.0       # Offline queue
  
  # Networking
  dio: ^5.4.0
  connectivity_plus: ^5.0.2
  
  # Auth
  sign_in_with_apple: ^5.0.0
  google_sign_in: ^6.2.1
  
  # UI Utilities
  shimmer: ^3.0.0
  permission_handler: ^11.1.0
  uuid: ^4.2.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  riverpod_generator: ^2.3.9
  build_runner: ^2.4.7
  hive_generator: ^2.0.1     # For offline queue models
  flutter_lints: ^3.0.1
```

### 8.2 Core Data Models

#### Project

```typescript
interface Project {
  project_id: UUID;
  name: string;
  mode: 'sewing' | 'quilt' | 'stencil' | 'maker' | 'custom';
  units: 'mm' | 'in';
  created_at: timestamp;
  updated_at: timestamp;
  pieces: Piece[];
  projection_profiles: ProjectionProfile[];
}
```

#### Piece

```typescript
interface Piece {
  piece_id: UUID;
  source_image_id: UUID;
  scale_mm_per_px: float;
  width_mm: float;
  height_mm: float;
  layers: {
    cutline: Path[];
    markings: Path[];
    labels: TextBox[];
  };
  qa: {
    confidence: float;
    warnings: string[];
  };
}
```

#### Path

```typescript
interface Path {
  path_id: UUID;
  path_type: 'cutline' | 'dart' | 'notch' | 'grainline';
  closed: boolean;
  points: Array<{ x_mm: float; y_mm: float }>;
  stroke_hint_mm: float;
  confidence: float;
}
```

### 8.3 Core Riverpod Providers

TraceCast uses Riverpod with code generation (`riverpod_annotation`) for type-safe, compile-time checked state management.

#### Provider Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     UI LAYER                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Screens   │  │   Widgets   │  │   Consumer/Watch    │  │
│  └──────┬──────┘  └──────┬──────┘  └──────────┬──────────┘  │
└─────────┼────────────────┼────────────────────┼─────────────┘
          │                │                    │
          ▼                ▼                    ▼
┌─────────────────────────────────────────────────────────────┐
│                   PROVIDER LAYER                             │
│  State Notifier: projectListProvider │ captureStateProvider │
│  Async Notifier: vectorizationProvider │ exportProvider      │
└─────────────────────────────────────────────────────────────┘
          │                │                    │
          ▼                ▼                    ▼
┌─────────────────────────────────────────────────────────────┐
│                   SERVICE LAYER                              │
│  Firebase │ RevenueCat │ Local Storage │ Platform Channels   │
└─────────────────────────────────────────────────────────────┘
```

#### Core Providers

| Provider | Type | Purpose |
|----------|------|---------|
| `projectListProvider` | `AsyncNotifier<List<Project>>` | All user projects |
| `currentProjectProvider` | `StateNotifier<Project?>` | Active project being edited |
| `captureStateProvider` | `StateNotifier<CaptureState>` | Camera/capture flow state |
| `vectorizationProvider` | `AsyncNotifier<VectorizationResult>` | AI processing state |
| `currentPieceProvider` | `StateNotifier<Piece?>` | Active piece in editor |
| `editorStateProvider` | `StateNotifier<EditorState>` | Quick Fix editor state |
| `projectorModeProvider` | `StateNotifier<ProjectorState>` | Projector display state |
| `externalDisplayProvider` | `StreamProvider<ExternalDisplayState>` | Connected display info |
| `subscriptionProvider` | `AsyncNotifier<SubscriptionStatus>` | RevenueCat subscription |
| `pendingUploadsProvider` | `StreamProvider<List<PendingUpload>>` | Offline queue |
| `userPreferencesProvider` | `StateNotifier<UserPreferences>` | App settings |
| `onboardingProvider` | `StateNotifier<OnboardingState>` | Onboarding progress |

#### Subscription Gating Pattern

> [!IMPORTANT]
> Check entitlements at every protected action, not just app launch. Subscriptions can expire mid-session.

```dart
// lib/core/guards/subscription_guard.dart

/// Call before any protected action
Future<bool> requireSubscription(WidgetRef ref, BuildContext context) async {
  final subscription = await ref.read(subscriptionProvider.future);
  
  if (!subscription.isActive) {
    // Navigate to paywall
    context.push('/paywall', extra: {'source': 'subscription_guard'});
    return false;
  }
  
  // Check for trial expiration
  if (subscription.isTrial && subscription.trialEndsAt != null) {
    if (DateTime.now().isAfter(subscription.trialEndsAt!)) {
      context.push('/paywall', extra: {'source': 'trial_expired'});
      return false;
    }
  }
  
  return true;
}

// Usage in protected action
Future<void> startNewScan(WidgetRef ref, BuildContext context) async {
  if (!await requireSubscription(ref, context)) return;
  
  // Proceed with scan...
}
```

**Protected Actions (require active subscription):**

| Action | Guard Location |
|--------|----------------|
| Start new scan | `CaptureScreen.onCapturePressed` |
| Upload for vectorization | `VectorizationProvider.startProcessing` |
| Export to PDF/SVG | `ExportProvider.export` |
| Access projector mode | `ProjectorScreen.initState` |
| View pattern (after trial) | `PieceDetailScreen.initState` |

**Free Actions (no subscription required):**

- Browse help/FAQ
- View settings
- Restore purchases
- View account info

#### Rate Limiting

> [!WARNING]
> Without rate limiting, a single user could run up significant OpenRouter costs.

**Per-User Limits:**

| Limit Type | Value | Enforcement |
|------------|-------|-------------|
| Scans per hour | 20 | Client-side soft limit + Cloud Function hard limit |
| Scans per day | 100 | Cloud Function check against Firestore counter |
| Concurrent requests | 2 | Client-side queue |
| Max image size | 10MB | Client-side validation before upload |

**Cloud Function Rate Limiting:**

```typescript
// functions/src/vectorize.ts

async function checkRateLimit(userId: string): Promise<void> {
  const now = new Date();
  const hourKey = `${now.getUTCFullYear()}-${now.getUTCMonth()}-${now.getUTCDate()}-${now.getUTCHours()}`;
  const dayKey = `${now.getUTCFullYear()}-${now.getUTCMonth()}-${now.getUTCDate()}`;
  
  const usageRef = admin.firestore()
    .collection('users').doc(userId)
    .collection('usage').doc(dayKey);
  
  const usageDoc = await usageRef.get();
  const usage = usageDoc.data() || { hourly: {}, daily: 0 };
  
  const hourlyCount = usage.hourly[hourKey] || 0;
  const dailyCount = usage.daily || 0;
  
  if (hourlyCount >= 20) {
    throw new functions.https.HttpsError('resource-exhausted', 
      'Hourly limit reached. Please wait before scanning more patterns.');
  }
  
  if (dailyCount >= 100) {
    throw new functions.https.HttpsError('resource-exhausted',
      'Daily limit reached. Try again tomorrow.');
  }
  
  // Increment counters
  await usageRef.set({
    hourly: { ...usage.hourly, [hourKey]: hourlyCount + 1 },
    daily: dailyCount + 1,
    lastUpdated: admin.firestore.FieldValue.serverTimestamp()
  }, { merge: true });
}
```

**OpenRouter 429 Handling:**

```typescript
// Handle OpenRouter rate limits
if (error.response?.status === 429) {
  const retryAfter = error.response.headers['retry-after'] || 60;
  throw new VectorizeError({
    code: VectorizeErrorCode.AI_RATE_LIMITED,
    message: `Rate limited. Retry after ${retryAfter} seconds.`,
    retryable: true,
    userMessage: 'Our AI service is busy. Please try again in a minute.',
  });
}
```

**Cost Controls:**

| Control | Implementation |
|---------|---------------|
| Daily budget cap | OpenRouter dashboard setting ($50/day recommended) |
| Alert threshold | Email alert at 80% of daily budget |
| Emergency shutoff | Cloud Function checks billing flag before processing |

#### Code Generation Commands

```bash
# Generate provider code after adding @riverpod annotations
dart run build_runner build --delete-conflicting-outputs

# Watch mode during development
dart run build_runner watch --delete-conflicting-outputs
```

### 8.4 API Contracts (MVP)

#### POST /v1/inference/vectorize

**Request:**
```json
{
  "project_id": "uuid",
  "image_id": "uuid",
  "mode": "sewing",
  "targets": ["cutline", "markings", "labels"],
  "scale_mm_per_px": 0.25
}
```

**Response:**
```json
{
  "piece_id": "uuid",
  "confidence": 0.92,
  "warnings": [],
  "layers": {
    "cutline": [...],
    "markings": [...],
    "labels": [...]
  }
}
```

### 8.4 UI Implementation Requirements

#### The "No-Keyboard" Policy

UI must be navigable 95% of time without QWERTY keyboard. All numeric inputs (scale, quantity) use **custom scrubber widgets** (sliding rulers built with `GestureDetector` + `CustomPainter`) or **steppers** (+/- buttons). Keyboards cover 40% of screen and break Blueprint immersion.

**Accessibility Fallback:** All scrubber widgets must support **tap-to-type** as a secondary input method. When the user taps the numeric value label (e.g., "98%", "1.2mm"), a compact numeric keypad modal appears for precise entry. This addresses accessibility needs and users who prefer exact input over sliding.

#### Flutter-Specific Patterns

| Pattern | Implementation |
|---------|----------------|
| Camera Overlay | `camera` plugin + `Stack` widget for Technical Reticle |
| Vector Rendering | `CustomPainter` for cutlines, paths, and markings |
| Pan/Zoom | `InteractiveViewer` widget with custom boundaries |
| Glassmorphism Headers | `BackdropFilter` + `ImageFilter.blur()` |
| Magic Button Animation | `AnimatedContainer` or `Hero` widget for radial expansion |
| Scrubber Controls | `GestureDetector` + `CustomPainter` + haptic feedback via `HapticFeedback` |
| Skeleton Loading | `Shimmer` package with Blueprint color adaptation |

#### Optimistic Updates & AI Latency UX

**Critical UX Note:** AI vectorization has a p95 latency of 15 seconds. This is long for mobile UX. The following patterns are **mandatory** to prevent user frustration:

> [!WARNING]
> **Cloud Function Cold Starts:** Firebase Functions can add 3-8 seconds on first request after idle. This directly impacts the "Magic Moment" timing.
> 
> **Mitigations:**
> - Animation must handle variable latency (never show fake "95% complete" while waiting)
> - Consider minimum instances in production (`minInstances: 1` costs ~$10/month but eliminates cold starts)
> - Load testing should include cold start scenarios

1. User snaps photo → app immediately adds "Scanning..." item to list via state management
2. Local thumbnail with `Shimmer` overlay (White shimmer on Blueprint Blue)
3. `Isolate` or background thread uploads; when data returns, update state
4. User can close app immediately—push notification arrives when complete
5. **Real Progress Stages:** The Analysis Animation (Screen 20) must display real progress stages from the backend (e.g., "Uploading...", "Analyzing...", "Constructing vectors...") rather than a simulated timer. This prevents the app from appearing frozen if latency exceeds 15s.
6. **Background Processing:** Allow users to navigate to the Library or other screens while vectorization completes. Show a subtle "Processing 1 pattern..." banner at the top of the screen.

#### Network Requirements

- AI vectorization requires active internet connection
- Use `connectivity_plus` to detect network state
- If offline, display clear messaging: "Connect to internet to scan patterns"
- Library browsing and viewing previously scanned patterns works offline

#### Offline Queue Specification

When the device loses connectivity during or before a scan, images are queued locally for later processing:

| Aspect | Specification |
|--------|---------------|
| **Storage Engine** | Hive (`hive_flutter: ^1.1.0`) for queue; `flutter_secure_storage` for sensitive data |
| **Queue Model** | `PendingCapture` with: `localImagePath`, `projectId`, `capturedAt`, `mode`, `scaleHint`, `retryCount`, `lastError` |
| **Retry Logic** | Exponential backoff: 1s → 2s → 4s (max 3 retries per upload) |
| **Auto-Resume** | `ConnectivityProvider` listens for network restore → triggers `processQueue()` |
| **UI Indicator** | Badge on app bar showing pending count (e.g., "⏳ 2") |
| **Max Queue Size** | 50 images; oldest removed if exceeded (with user warning) |
| **Queue Persistence** | Survives app restart; Hive box opened in `main.dart` |

**PendingCapture Model:**

```dart
@HiveType(typeId: 0)
class PendingCapture extends HiveObject {
  @HiveField(0) final String localImagePath;
  @HiveField(1) final String projectId;
  @HiveField(2) final DateTime capturedAt;
  @HiveField(3) final String mode;
  @HiveField(4) final double? scaleHint;
  @HiveField(5) int retryCount;
  @HiveField(6) String? lastError;
}
```

**Queue States:**

| State | UI Display |
|-------|------------|
| Pending (first attempt) | "Saved for later" toast on capture |
| Processing | Spinner overlay on thumbnail |
| Failed (retrying) | Orange warning icon |
| Failed (max retries) | Red error icon + "Needs attention" |
| Succeeded | Item removed from queue, pattern appears in library |

### 8.5 Third-Party Integrations

#### Flutter Packages

| Integration | Package | Notes |
|-------------|---------|-------|
| Camera | `camera` | Official Flutter team package |
| Image Processing | `image` | Dart-native image manipulation |
| PDF Export | `pdf`, `printing` | Generate projector-ready PDFs |
| SVG Export | `flutter_svg`, `path_drawing` | Vector output with correct viewBox |
| IAP | `purchases_flutter` | RevenueCat official SDK |
| Analytics | `firebase_analytics` | First-party Google support |
| Crashlytics | `firebase_crashlytics` | First-party Google support |
| Remote Config | `firebase_remote_config` | A/B testing and feature flags |
| Local Storage | `shared_preferences`, `flutter_secure_storage` | Onboarding persistence |
| HTTP | `dio` | REST API with interceptors |
| State Management | `flutter_riverpod` or `flutter_bloc` | Reactive state |
| Haptics | `flutter_haptic_feedback` or native `HapticFeedback` | Confirmation moments |

#### Platform Channels (Native Code Required)

| Feature | iOS | Android |
|---------|-----|---------|
| AirPlay | `AVRoutePickerView` via MethodChannel | N/A |
| Google Cast | N/A | `cast` package or `CastContext` via MethodChannel |
| OpenCV (optional) | `opencv_dart` or native framework | `opencv_dart` or native library |
| Advanced OCR | iOS Vision via MethodChannel | ML Kit via MethodChannel |

#### Push Notification Strategy

> [!NOTE]
> MVP includes notification permission request but limited actual notifications. Full notification strategy is P1.

**MVP Scope (Phase 1-5):**

| Notification Type | Implementation |
|-------------------|---------------|
| Processing complete | Local notification when vectorization finishes (app backgrounded) |
| Offline queue processed | Local notification when pending uploads complete |

**P1 Scope (Post-Launch):**

| Notification Type | Implementation |
|-------------------|---------------|
| Trial expiring | Push notification 24h before trial ends |
| Subscription expired | Push notification on expiration day |
| New feature announcement | Push via FCM topic subscription |
| Pattern processing failed | Push notification for persistent failures |

**Implementation Notes:**

```dart
// MVP: Local notifications only
// No FCM server setup required for MVP

dependencies:
  flutter_local_notifications: ^16.0.0  # For local notifications

// P1: Add FCM for push notifications
  firebase_messaging: ^14.7.0
```

**Permission Request Timing:**
- Request notification permission AFTER paywall purchase (Screen 15)
- User has committed → more likely to allow
- If denied, continue silently (non-blocking)

### 8.6 Reference Detection & Scale Calibration

TraceCast uses ArUco marker detection for reliable scale calibration. Users print a reference sheet (included in-app as downloadable PDF) containing four ArUco markers at known positions.

#### Reference Sheet Specification

| Property | Value |
|----------|-------|
| Marker Dictionary | DICT_4X4_50 (OpenCV standard) |
| Marker IDs | 0, 1, 2, 3 (corners) |
| Marker Size | 40mm × 40mm printed |
| Sheet Size | A4 or Letter (auto-detected) |
| Corner Positions | 20mm inset from edges |
| Known Distance | 170mm (A4) or 165mm (Letter) between diagonal markers |

#### Detection Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    CAMERA FRAME                              │
│  ┌─────┐                                         ┌─────┐    │
│  │ ID:0│                                         │ ID:1│    │
│  │ ▓▓▓ │                                         │ ▓▓▓ │    │
│  └─────┘                                         └─────┘    │
│                                                              │
│                    ┌───────────────┐                        │
│                    │               │                        │
│                    │   PATTERN     │                        │
│                    │    PIECE      │                        │
│                    │               │                        │
│                    └───────────────┘                        │
│                                                              │
│  ┌─────┐                                         ┌─────┐    │
│  │ ID:3│                                         │ ID:2│    │
│  │ ▓▓▓ │                                         │ ▓▓▓ │    │
│  └─────┘                                         └─────┘    │
└─────────────────────────────────────────────────────────────┘
```

#### Implementation Requirements

| Component | Technology | Notes |
|-----------|------------|-------|
| iOS Detection | Vision framework + Core Image | Use `VNDetectBarcodesRequest` with `.aztec` symbology fallback to ArUco |
| Android Detection | ML Kit Barcode + OpenCV | ML Kit for QR fallback, OpenCV for ArUco |
| Fallback | Manual 4-point selection | If markers not detected, user taps corners manually |

#### Detection States

| State | UI Feedback | Action |
|-------|-------------|--------|
| All 4 markers detected | Green corner indicators + "Reference locked" | Auto-capture enabled |
| 2-3 markers detected | Yellow indicators + "Move to see all corners" | Guide user to reposition |
| 0-1 markers detected | Red indicators + "Place pattern on reference sheet" | Show help overlay |
| No reference sheet | Modal warning | Offer "Continue without" or "Add reference" |

#### Alternative Reference Methods (P1 - Post-MVP)

For users without a printer:
- **Credit Card Mode:** Place standard credit card (85.6mm × 53.98mm) in frame
- **Cutting Mat Mode:** Detect grid lines on standard cutting mats (requires ML model training)
- **Manual Entry:** User inputs a known measurement from the pattern (e.g., "test square = 2 inches")

#### Printable Reference Sheet

The app includes a "Print Reference Sheet" option in Settings that:
1. Generates a PDF with ArUco markers at correct positions
2. Includes measurement verification rulers on edges
3. Includes QR code linking to in-app calibration tutorial
4. Opens system share sheet for printing

**File location:** `/assets/reference_sheet_a4.pdf` and `/assets/reference_sheet_letter.pdf`

---

### 8.7 Image Preprocessing Pipeline

All image preprocessing occurs in the Firebase Cloud Function before AI vectorization. This ensures consistent processing regardless of device capabilities.

#### Preprocessing Steps

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Raw Image  │────▶│    Rotate    │────▶│  De-warp     │────▶│  Normalize   │
│  from Client │     │   (EXIF)     │     │ (Homography) │     │  (Contrast)  │
└──────────────┘     └──────────────┘     └──────────────┘     └──────────────┘
                                                                      │
                                                                      ▼
┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  To AI Model │◀────│   Encode     │◀────│   Resize     │◀────│   Enhance    │
│              │     │  (Base64)    │     │  (2048 max)  │     │  (Optional)  │
└──────────────┘     └──────────────┘     └──────────────┘     └──────────────┘
```

#### Key Processing Functions

```typescript
// Cloud Function: preprocessImage.ts
import sharp from 'sharp';

const MAX_DIMENSION = 2048;
const JPEG_QUALITY = 85;

export async function preprocessImage(
  rawImage: Buffer,
  markers?: MarkerCorners
): Promise<{ base64: string; dimensions: { width: number; height: number } }> {
  let pipeline = sharp(rawImage).rotate(); // Auto-rotate based on EXIF
  
  // Apply perspective correction if markers provided
  if (markers) {
    // Compute homography matrix and apply warp
    // Note: Full implementation requires opencv4nodejs or external service
  }
  
  // Normalize contrast (helps with tissue paper)
  pipeline = pipeline.normalize().sharpen({ sigma: 1 });
  
  // Resize if exceeds max dimension
  pipeline = pipeline.resize(MAX_DIMENSION, MAX_DIMENSION, {
    fit: 'inside',
    withoutEnlargement: true
  });
  
  const processedBuffer = await pipeline.jpeg({ quality: JPEG_QUALITY }).toBuffer();
  const metadata = await sharp(processedBuffer).metadata();
  
  return {
    base64: processedBuffer.toString('base64'),
    dimensions: { width: metadata.width!, height: metadata.height! }
  };
}
```

#### Client Responsibilities

The Flutter client is responsible for:
1. Capturing the image at maximum resolution
2. Detecting ArUco markers and extracting corner coordinates (using platform channels to native CV)
3. Sending raw image + marker coordinates to Cloud Function
4. Displaying preprocessing progress to user

The client does NOT perform homography—this ensures consistent results across devices.

---

### 8.8 Offline Queue & Sync Service

TraceCast must gracefully handle network interruptions during the capture-to-vectorization flow.

#### Pending Upload States

| State | Description | UI Indicator |
|-------|-------------|--------------|
| `queued` | Image saved locally, waiting for network | Clock icon |
| `uploading` | Currently uploading to Cloud Function | Progress spinner |
| `processing` | Uploaded, waiting for AI response | Brain icon animating |
| `completed` | Vectorization successful | Green checkmark |
| `failed` | Permanent failure (invalid image, etc.) | Red X with retry option |
| `retrying` | Temporary failure, will retry | Retry arrows |

#### Data Model

```dart
// lib/core/models/pending_upload.dart

@HiveType(typeId: 1)
class PendingUpload extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String projectId;
  
  @HiveField(2)
  final String localImagePath;
  
  @HiveField(3)
  final String mode; // sewing, quilting, stencil
  
  @HiveField(4)
  final Map<String, dynamic>? markerCorners;
  
  @HiveField(5)
  PendingUploadState state;
  
  @HiveField(6)
  final DateTime createdAt;
  
  @HiveField(7)
  int attemptCount;
}
```

#### Sync Triggers

| Trigger | Action |
|---------|--------|
| App launch | Check for queued uploads, process if online |
| Network restored | Process all queued/retrying uploads |
| Manual retry | User taps "Retry" on failed upload |
| Background fetch (iOS) | Process queued uploads (requires BGTaskScheduler setup) |

---

## 9. Non-Functional Requirements

### 9.1 Performance

| Metric | Target |
|--------|--------|
| App cold start | ≤2.5s on mid-tier devices |
| Capture to preview | ≤2s after shutter |
| Vectorization | Median ≤6s, p95 ≤15s |
| UI responsiveness | ≤100ms for pan/zoom/thickness changes |

### 9.2 Security & Privacy

| Aspect | Specification |
|--------|---------------|
| In Transit | TLS 1.2+ |
| At Rest | AES-256 |
| Data Separation | User ID scoping |
| Image Retention | Deleted within 30 days unless user opts into cloud sync |
| Disclosure | Clear disclosure for cloud AI processing |

### 9.3 Accessibility

| Aspect | Specification |
|--------|---------------|
| Standard | Target WCAG 2.1 AA compliance |
| Screen Readers | VoiceOver/TalkBack labels for all controls |
| Tap Targets | Minimum 44×44pt (iOS) / 48dp (Android) |
| Contrast | High-contrast UI mode option |

#### Detailed Accessibility Requirements

**Color Contrast:**
| Element | Contrast Ratio | Status |
|---------|----------------|--------|
| White text on Steel Blue (#4A90E2) | 4.6:1 | ✓ AA compliant |
| White text on Darker Blue (#357ABD) | 6.2:1 | ✓ AAA compliant |
| Orange CTA (#FF9F43) on Steel Blue | 3.1:1 | ✓ Large text compliant |
| Error Red (#FF6B6B) on Steel Blue | 3.5:1 | ✓ Large text compliant |

**Camera Capture Flow:**
- Audio cues when grid is detected ("Grid detected, ready to scan")
- Vibration feedback when auto-capture triggers
- High-contrast mode increases reticle line thickness to 3px
- Screen reader announces: reference type, scale confidence, and capture status

**Editor Tools:**
- All tools have unique haptic patterns (erase = short pulse, patch = double pulse, etc.)
- Tool selection announced via VoiceOver/TalkBack
- Zoom level and pan position announced on change
- Minimum touch target for tool palette: 48×48dp

**Projector Mode:**
- Phone remote has large touch targets (64×64dp nudge buttons)
- Lock mode requires deliberate two-finger tap to unlock
- High contrast preview available for low-vision users

### 9.4 Reliability

| Metric | Target |
|--------|--------|
| Crash-free sessions | ≥99.5% |
| Cloud inference error rate | ≤1% |
| Network Required | AI vectorization requires internet; library browsing works offline |

### 9.5 API Error Handling & Fallbacks

| Scenario | Behavior |
|----------|----------|
| OpenRouter API unavailable | Retry with exponential backoff (1s, 2s, 4s); show "AI temporarily unavailable, try again" after 3 attempts |
| Rate limit hit | Queue request, show estimated wait time, allow user to cancel |
| Low confidence result (<50%) | Show prominent warning, require user verification, suggest re-scan with better lighting |
| Network timeout | Show "Connection slow" banner, allow retry or cancel |
| Model error | Log to Crashlytics, fall back to secondary model via OpenRouter, notify user if all fail |

---

## 10. Development Phases

### MVP Scope

#### IN (MVP)
- Complete onboarding flow (16 screens)
- New project + mode selection
- Guided capture with reference detection
- De-warp + scale calibration + confidence score + test square
- Projector calibration wizard (single-session required for MVP)
- Cloud AI vectorization (cutline + basic OCR)
- Quick Fix editor (erase/patch/smooth/labels)
- Projector mode with dark preset, controls, layers
- Casting (AirPlay mirroring + Google Cast)
- Export: Projector PDF + SVG + PNG
- Basic project library

#### OUT (MVP)
- Multi-shot stitching (P1)
- Saved projector calibration profiles (P1)
- Pattern sharing & marketplace integration (P1)
- DXF export, kerf offsets (P2)
- Seam allowance generation (P2)

### Build Phases (Daily Tracking)

> **Note:** See `TraceCast_Roadmap.md` for detailed task breakdowns. Build Phases follow a **Risk-First** approach:

| Build Phase | Focus | Timeline |
|-------------|-------|----------|
| Phase 0 | Foundation (Theme, Navigation, Services) | Week 1 |
| Phase 1 | Core Loop (Camera → AI → Projector) | Week 2 |
| Phase 2 | Accuracy & Calibration | Week 3 |
| Phase 3 | Onboarding & Monetization | Weeks 4-5 |
| Phase 4 | Editor & Refinement | Weeks 6-7 |
| Phase 5 | Library & Export | Weeks 8-9 |
| Phase 6 | Polish & Launch | Weeks 10-11 |

> [!IMPORTANT]
> **Phase 1 Critical Dependency:** Platform channel for external display is **blocking** for projector mode. Start iOS/Android native work (UIScreen/UIWindow for iOS, Presentation API for Android) in Week 2 parallel to Flutter capture work. External display is ~200 lines per platform—not a trivial integration. See [TraceCast_Appendix_AI_Prompt_Engineering.md](../TraceCast_Appendix_AI_Prompt_Engineering.md#7-external-display-architecture) for complete implementation.

### Release Phases (External Milestones)

| Phase | Timeline | Deliverables |
|-------|----------|--------------|
| **MVP Beta** | 8-12 weeks | Full MVP flow + casting + export; invite-only beta |
| **Public Launch** | 4-8 weeks | Stability, Blueprint polish, onboarding optimization, ASO |
| **Expansion** | 8-16 weeks | Multi-shot stitching, pattern sharing, DXF |

#### Flutter Development Advantage

Timeline estimates assume Flutter single-codebase development:
- **Phase 0 savings**: ~30% faster than dual native development (one camera/CV integration instead of two)
- **Phase 1 savings**: ~40% faster for full MVP (onboarding, IAP, export built once)
- **Ongoing**: Feature parity guaranteed; no platform drift during iteration

Platform channel work for AirPlay/Cast is scoped at ~1-2 days per platform and can run parallel to main development.

---

## 11. Development Guidelines

Critical guidance for implementing this specification.

### 11.1 Build Order (Risk-First)

Implement in this order to surface blocking issues early:

| Priority | Component | Why First |
|----------|-----------|----------|
| 1 | External display platform channel | Blocking dependency for projector mode; ~200 lines native code per platform |
| 2 | Camera capture with ArUco detection | Core functionality; validates CV integration |
| 3 | AI vectorization round-trip | Validates OpenRouter integration, even with test images |
| 4 | Preprocessing pipeline (Cloud Function) | Required before real pattern testing |
| 5 | Verification UI | Can use mock data initially |
| 6 | Onboarding & paywall | Non-blocking; can develop in parallel |
| 7 | Editor & export | Depends on working vectorization |

### 11.2 Known Gotchas

#### Riverpod
- Use `flutter_riverpod` with code generation (`riverpod_annotation` + `riverpod_generator`)
- Run `dart run build_runner build` after adding `@riverpod` annotations
- Generated files are `.g.dart` — add to `.gitignore` patterns if desired

#### RevenueCat
- **Must call `await Purchases.configure()` before ANY entitlement check**
- Configure in `main.dart` before `runApp()`
- Sandbox testing requires device (not simulator) for iOS

#### OpenRouter
- Response is in `choices[0].message.content`, NOT `choices[0].text`
- Model IDs are case-sensitive
- Include `HTTP-Referer` header or requests may be rejected

#### External Display
- iOS: Requires `UIScreen.didConnectNotification` observer in AppDelegate
- Android: Use `DisplayManager.DISPLAY_CATEGORY_PRESENTATION` to find projectors
- Handle disconnect mid-projection gracefully

> [!CAUTION]
> **iOS Simulator does NOT support external displays.** You must test with a PHYSICAL device + HDMI/Lightning adapter + real monitor/projector. Use conditional compilation for development:
> ```swift
> #if targetEnvironment(simulator)
>     // Show mock projector UI for development
> #else
>     // Real external display code
> #endif
> ```

#### JSON Response Extraction
- Always use fallback extraction — LLMs sometimes add preamble
- Test with intentionally malformed responses

### 11.3 Pre-Flight Checks

Before each development session:

1. ✅ Verify OpenRouter API key: `curl -H "Authorization: Bearer $KEY" https://openrouter.ai/api/v1/models`
2. ✅ Verify Firebase emulators: `firebase emulators:start`
3. ✅ Verify Flutter doctor: `flutter doctor -v`
4. ✅ Verify build_runner: `dart run build_runner build`

### 11.4 Implementation Checklist

- [ ] Verify OpenRouter model IDs are current (check https://openrouter.ai/models)
- [ ] Set up OpenRouter account with billing
- [ ] Configure fallback chain in Firebase Remote Config
- [ ] Implement response validation before trusting AI output
- [ ] Add logging for debugging malformed responses
- [ ] Test with 10+ real pattern images before launch
- [ ] Measure actual latency and adjust timeouts accordingly
- [ ] Implement cost monitoring via OpenRouter dashboard

### 11.5 Firebase Remote Config Keys

All expected Remote Config keys for backend setup. Create these in Firebase Console before launch.

#### AI Vectorization

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `ai_primary_model` | String | `google/gemini-2.0-flash-exp` | Primary OpenRouter model ID |
| `ai_fallback_models` | JSON | `["google/gemini-1.5-flash", "anthropic/claude-sonnet-4-20250514"]` | Fallback chain |
| `ai_timeout_ms` | Number | `45000` | Per-model timeout |
| `ai_retry_delays_ms` | JSON | `[1000, 2000, 4000]` | Retry backoff delays |
| `max_image_dimension` | Number | `2048` | Max px before downsampling |
| `jpeg_quality` | Number | `85` | JPEG compression quality |
| `min_image_dimension` | Number | `800` | Minimum px (reject smaller) |
| `enable_contrast_normalization` | Boolean | `false` | A/B test: auto-level contrast |

#### Social Proof (Screen 4)

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `social_proof_patterns_count` | String | `"1,000+"` | Displayed pattern count |
| `social_proof_rating` | String | `null` | App Store rating (hide if null) |
| `social_proof_countries` | String | `"20+"` | Countries count |

#### Feature Flags

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `enable_projector_mode` | Boolean | `true` | Kill switch for projector feature |
| `enable_offline_queue` | Boolean | `true` | Kill switch for offline queue |
| `show_beta_features` | Boolean | `false` | Show experimental features |
| `force_maintenance_mode` | Boolean | `false` | Emergency maintenance screen |

#### Rate Limiting

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `rate_limit_hourly` | Number | `20` | Max scans per hour |
| `rate_limit_daily` | Number | `100` | Max scans per day |
| `billing_emergency_stop` | Boolean | `false` | Stop all AI calls (budget exceeded) |

---

## 12. Analytics & Instrumentation

### 12.1 Core Event Taxonomy

```
project_created: { mode, units }
capture_started / capture_completed: { reference_type, blur_score }
calibration_confidence: { score, reference_type }
vectorize_requested / vectorize_succeeded / vectorize_failed: { latency, error_code }
edit_tool_used: { tool_type }
projector_mode_opened
cast_connected / cast_disconnected: { cast_type }
export_completed: { format }
```

### 12.2 Conversion Funnels

#### Onboarding Funnel
```
Start → Each Step → Paywall View → Plan Select → Purchase Success
```

#### Activation Funnel
```
Home → Capture → Vectorize Success → Verify → Project → Export
```

#### Retention Metrics
- Weekly active sessions
- Projects per user
- Cast sessions per week

### 12.3 User Properties

| Property | Values |
|----------|--------|
| `user_segment` | power_sewist \| casual_crafter \| cosplayer \| maker |
| `projector_readiness` | ready \| needs_projector \| export_only |
| `experience_tier` | beginner \| intermediate \| advanced |
| `subscription_status` | trial \| pro_monthly \| pro_annual |
| `primary_pain_points` | Array from onboarding |

---

## 13. Appendices

### 13.0 AI Prompt Engineering Appendix

For complete AI vectorization implementation details, see [TraceCast_Appendix_AI_Prompt_Engineering.md](../TraceCast_Appendix_AI_Prompt_Engineering.md):

| Section | Content |
|---------|---------|
| OpenRouter Config | Corrected model IDs, Remote Config schema for hot-swapping |
| Prompt Architecture | Complete system prompt + mode-specific user prompts |
| Response Schema | TypeScript interfaces for raw AI output and transformed client format |
| Validation | Full response validation code with error handling |
| Error Handling | Error codes, user-facing messages, retry logic |
| Cloud Function | Complete implementation with image preprocessing |
| External Display | iOS (UIScreen/UIWindow) + Android (Presentation API) platform channel code (~200 lines per platform) |
| Testing | Test cases for success, low confidence, and failure scenarios |

> [!IMPORTANT]
> **Critical Implementation Details:**
> - Prompts use **low temperature (0.1)** — essential for consistent JSON output
> - **Response validation is mandatory** — LLMs sometimes return prose instead of JSON
> - **Coordinate transformation is px→mm** — happens in Cloud Function, not client
> - **External display code is substantial** — not a trivial integration

---

### 13.1 Why "Blueprint" Wins

| Dimension | Blueprint (Light Blue) | Dark Mode |
|-----------|------------------------|-----------|
| Perception | Engineering/Medical/Clean | Hacker/Media |
| Eye Strain | Softer for long sessions | Can cause halation |
| Differentiation | Unique brand identity | Generic |
| User Connection | Matches pattern/schematic aesthetic | No craft connection |

### 13.2 Glossary

| Term | Definition |
|------|------------|
| **Homography** | Mathematical transformation to flatten photo to top-down view |
| **Keystone Correction** | Compensating for trapezoid distortion from angled projection |
| **Cutline** | Outer boundary for cutting fabric/material |
| **Notch** | Tick marks for alignment between pieces |
| **Grainline** | Arrow indicating fabric grain direction |
| **Seam Allowance** | Extra margin beyond stitch line |
| **Magic Moment** | The reveal when AI transforms chaotic image into clean vectors |

### 13.3 Open Questions

| Question | Options |
|----------|---------|
| Piece Detection Strategy | Require one piece per scan (MVP) — auto-detect multiple deferred to P2 |
| IP/Copyright Handling | How to message "personal use" digitization? Disclaimers needed? |
| Projector Compatibility | App works with any projector that supports AirPlay/Cast mirroring — no minimum specs required |

### 13.4 Technical Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| Scale Accuracy Failures | Strict reference requirement, confidence scoring, test-square gating |
| Vectorization Quality Variance | Highlight low-confidence segments; quick fix tools; iterate with beta data |
| Casting Fragmentation | MVP uses mirroring; add native receiver/external display in P1 |
| AI Costs | Image downsampling, caching, on-device fallback, metered access |

### 13.5 Assumptions

- MVP uses screen mirroring for casting to reduce complexity
- AI vectorization starts cloud-first for quality; on-device fallback may be added later
- Scale accuracy requirements are achievable with reference mat/markers; without reference, app warns and disables "Scale Guaranteed"

---

**— End of Document —**

*TraceCast: Scan-to-Projector PRD v1.0 | December 2025*
