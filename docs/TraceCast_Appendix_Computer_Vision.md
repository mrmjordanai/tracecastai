# TraceCast: Computer Vision Appendix

**Version 1.0 | December 2025**

Appendix to TraceCast PRD v1.0 — ArUco Detection & Scale Calibration Specification

---

## Table of Contents

1. [Overview](#1-overview)
2. [Flutter Package Selection](#2-flutter-package-selection)
3. [ArUco Marker Configuration](#3-aruco-marker-configuration)
4. [Detection Parameters](#4-detection-parameters)
5. [Fallback Chain](#5-fallback-chain)
6. [Platform-Specific Implementation](#6-platform-specific-implementation)
7. [Reference Sheet Specification](#7-reference-sheet-specification)
8. [Testing & Validation](#8-testing--validation)

---

## 1. Overview

TraceCast uses computer vision for scale calibration—the most critical aspect of pattern digitization accuracy. This appendix specifies the technical implementation details for ArUco marker detection, grid recognition, and fallback mechanisms.

### Scale Calibration Pipeline

```
┌─────────────────────────────────────────────────────────────────────┐
│                      SCALE CALIBRATION FLOW                          │
│                                                                       │
│  Camera Frame → [ArUco Detection] → Scale Calculated (±0.3%)         │
│       │                                                               │
│       │ (if no ArUco)                                                │
│       ▼                                                               │
│  [Grid Detection] → Scale Calculated (±0.5%)                         │
│       │                                                               │
│       │ (if no grid)                                                  │
│       ▼                                                               │
│  [Credit Card Detection] → Scale Calculated (±1-2%)                  │
│       │                                                               │
│       │ (if no card)                                                  │
│       ▼                                                               │
│  [Manual 4-Point Tap] → User Selects Corners                         │
│       │                                                               │
│       │ (perspective corrected, then)                                 │
│       ▼                                                               │
│  [Manual Dimension Input] → User Enters Known Measurement            │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 2. Flutter Package Selection

### Primary: `opencv_dart`

| Aspect | Specification |
|--------|---------------|
| Package | `opencv_dart: ^1.0.0` |
| Source | [pub.dev/packages/opencv_dart](https://pub.dev/packages/opencv_dart) |
| Why | Pure Dart bindings to OpenCV, cross-platform, includes ArUco module |
| Platforms | iOS, Android (both via native FFI) |

```yaml
# pubspec.yaml
dependencies:
  opencv_dart: ^1.0.0
```

### Fallback: Platform Channels

If `opencv_dart` has issues on a specific platform, use platform channels to native CV:

| Platform | Native Option | Notes |
|----------|---------------|-------|
| iOS | Vision framework + Core Image | Built-in, no dependencies. Use `VNDetectBarcodesRequest` with custom ArUco decoder |
| Android | ML Kit + OpenCV NDK | ML Kit for barcode detection, OpenCV NDK for ArUco specifically |

> [!NOTE]
> The `opencv_dart` package wraps native OpenCV libraries. Binary size impact is ~15-20MB per platform. This is acceptable given the core functionality provided.

> [!WARNING]
> **Before committing to `opencv_dart`:**
> 1. Test ArUco detection on a physical iOS device
> 2. Test ArUco detection on a physical Android device
> 3. Verify app size increase is acceptable (~15-20MB)
> 4. Confirm no conflicts with other camera packages
>
> If issues arise, implement native platform channels instead (instructions below).

### Native Fallback: iOS (OpenCV via Swift Package Manager)

If `opencv_dart` fails on iOS, use OpenCV directly:

**1. Add OpenCV to `ios/Podfile`:**

```ruby
# ios/Podfile
pod 'OpenCV', '~> 4.7.0'
```

**2. Create Swift ArUco wrapper:**

See Section 6 for complete `ArucoDetector.swift` implementation.

**3. Register platform channel in `AppDelegate.swift`:**

```swift
// ios/Runner/AppDelegate.swift
import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    let arucoChannel = FlutterMethodChannel(
      name: "com.tracecast/aruco",
      binaryMessenger: controller.binaryMessenger
    )
    
    arucoChannel.setMethodCallHandler { [weak self] call, result in
      if call.method == "detectMarkers" {
        // Handle detection - see Section 6
      }
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### Native Fallback: Android (OpenCV via Gradle)

If `opencv_dart` fails on Android, use OpenCV NDK:

**1. Add to `android/app/build.gradle`:**

```groovy
// android/app/build.gradle
dependencies {
    implementation 'org.opencv:opencv:4.7.0'
}
```

**2. Create Kotlin ArUco wrapper:**

See Section 6 for complete `ArucoDetector.kt` implementation.

**3. Register platform channel in `MainActivity.kt`:**

```kotlin
// android/app/src/main/kotlin/.../MainActivity.kt
class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.tracecast/aruco"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "detectMarkers" -> {
                        // Handle detection - see Section 6
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
```

---

## 3. ArUco Marker Configuration

### Dictionary Selection

| Setting | Value | Rationale |
|---------|-------|-----------|
| Dictionary | `cv2.aruco.DICT_4X4_50` | Smaller markers (4×4 bits) = faster detection, 50 unique IDs is sufficient |
| Marker IDs Used | 0, 1, 2, 3 | One per corner of reference sheet |
| Alternative | `DICT_6X6_250` | Use if 4×4 has reliability issues in testing |

### Why 4×4_50?

- **Faster detection**: Fewer bits to decode = lower latency
- **Sufficient capacity**: We only need 4 markers
- **Better for phone cameras**: Lower resolution requirements
- **Robust to blur**: Simpler patterns survive motion blur

### Marker Specifications

| Parameter | Value |
|-----------|-------|
| Physical size | 30mm × 30mm |
| Border width | 1 cell (25% of marker) |
| Quiet zone | 5mm minimum around each marker |
| Print color | Pure black (#000000) on pure white (#FFFFFF) |

### Corner Assignment

```
┌────────────────────────────────────────────┐
│  [ID: 0]                          [ID: 1]  │
│    ●                                  ●    │
│                                            │
│              PATTERN AREA                  │
│                                            │
│                                            │
│    ●                                  ●    │
│  [ID: 3]                          [ID: 2]  │
└────────────────────────────────────────────┘
```

- ID 0: Top-left
- ID 1: Top-right
- ID 2: Bottom-right
- ID 3: Bottom-left

This clockwise ordering allows automatic orientation detection.

---

## 4. Detection Parameters

### ArUco Detector Parameters

```dart
// lib/core/services/aruco_detector.dart

class ArucoDetectorConfig {
  // Adaptive thresholding
  static const int adaptiveThreshWinSizeMin = 3;
  static const int adaptiveThreshWinSizeMax = 23;
  static const int adaptiveThreshWinSizeStep = 10;
  static const double adaptiveThreshConstant = 7.0;
  
  // Contour filtering
  static const double minMarkerPerimeterRate = 0.03;  // Min perimeter as % of image
  static const double maxMarkerPerimeterRate = 4.0;   // Max perimeter as % of image
  static const double polygonalApproxAccuracyRate = 0.03;
  
  // Marker identification
  static const double minCornerDistanceRate = 0.05;
  static const int minDistanceToBorder = 3;           // Pixels
  static const int markerBorderBits = 1;
  static const double minOtsuStdDev = 5.0;
  static const int perspectiveRemovePixelPerCell = 4;
  static const double perspectiveRemoveIgnoredMarginPerCell = 0.13;
  
  // Error correction
  static const int maxErroneousBitsInBorderRate = 0.35;
  static const double errorCorrectionRate = 0.6;
  
  // Detection thresholds
  static const int minMarkerSizePx = 20;              // Minimum marker dimension
  static const double minConfidence = 0.7;            // Reject below this
}
```

### Parameter Tuning Notes

| Parameter | Effect if Too Low | Effect if Too High |
|-----------|-------------------|-------------------|
| `adaptiveThreshWinSizeMin` | Miss small markers | Slower detection |
| `minMarkerPerimeterRate` | False positives | Miss distant markers |
| `maxErroneousBitsInBorderRate` | Reject valid markers | Accept corrupted markers |
| `errorCorrectionRate` | Miss damaged markers | Accept wrong IDs |

### Real-Time Detection Settings

For camera preview (30fps target):

```dart
class LiveDetectionConfig {
  static const int frameSkip = 2;           // Process every 3rd frame
  static const int maxProcessingTimeMs = 50; // Skip if exceeds
  static const int stabilityFrames = 5;     // Frames before "locked"
  static const double positionTolerancePx = 3.0; // Movement threshold
}
```

---

## 5. Fallback Chain

### Decision Flow

```dart
// lib/core/services/scale_detector.dart

enum ScaleMethod {
  aruco,      // ±0.3% accuracy
  grid,       // ±0.5% accuracy
  creditCard, // ±1-2% accuracy
  manual,     // User-dependent
}

class ScaleDetectionResult {
  final ScaleMethod method;
  final double mmPerPx;
  final double confidence; // 0.0 - 1.0
  final List<Point> referenceCorners; // For perspective transform
}

Future<ScaleDetectionResult> detectScale(CameraImage image) async {
  // 1. Try ArUco markers first (highest accuracy)
  final arucoResult = await _detectAruco(image);
  if (arucoResult != null && arucoResult.confidence > 0.8) {
    return arucoResult;
  }
  
  // 2. Try cutting mat grid
  final gridResult = await _detectGrid(image);
  if (gridResult != null && gridResult.confidence > 0.7) {
    return gridResult;
  }
  
  // 3. Try credit card
  final cardResult = await _detectCreditCard(image);
  if (cardResult != null && cardResult.confidence > 0.6) {
    return cardResult;
  }
  
  // 4. Return null - UI should prompt for manual input
  return null;
}
```

### Fallback Triggers

| Trigger | Action |
|---------|--------|
| No ArUco detected after 3 seconds | Try grid detection |
| Grid detection fails | Show "Place credit card in frame" prompt |
| Credit card not detected after 5 seconds | Show manual 4-point interface |
| User completes 4-point selection | Prompt for known dimension |

### User Messaging

| State | UI Message |
|-------|------------|
| Searching for ArUco | "Looking for reference markers..." |
| ArUco found | "✓ Reference markers detected" (green) |
| Trying grid | "Looking for cutting mat grid..." |
| Grid found | "✓ Cutting mat detected" (green) |
| Trying card | "Place a credit card in the frame" |
| Card found | "✓ Card detected" (green) |
| Manual needed | "Tap the four corners of your pattern" |

---

## 6. Platform-Specific Implementation

### iOS Implementation

```swift
// ios/Runner/ArucoDetector.swift

import opencv2
import Flutter

class ArucoDetector {
    private let dictionary: ArucoDictionary
    private let parameters: ArucoDetectorParameters
    
    init() {
        // Use 4x4_50 dictionary
        dictionary = Aruco.getPredefinedDictionary(Aruco.DICT_4X4_50)
        
        // Configure parameters
        parameters = ArucoDetectorParameters()
        parameters.adaptiveThreshWinSizeMin = 3
        parameters.adaptiveThreshWinSizeMax = 23
        parameters.minMarkerPerimeterRate = 0.03
        parameters.maxErroneousBitsInBorderRate = 0.35
    }
    
    func detect(image: Mat) -> [ArucoMarker] {
        var corners = [[Point2f]]()
        var ids = Mat()
        
        Aruco.detectMarkers(
            image: image,
            dictionary: dictionary,
            corners: &corners,
            ids: ids,
            parameters: parameters
        )
        
        return zip(ids.toArray(), corners).map { id, corner in
            ArucoMarker(id: Int(id), corners: corner)
        }
    }
}
```

### Android Implementation

```kotlin
// android/app/src/main/kotlin/.../ArucoDetector.kt

import org.opencv.aruco.Aruco
import org.opencv.aruco.DetectorParameters
import org.opencv.aruco.Dictionary

class ArucoDetector {
    private val dictionary: Dictionary = Aruco.getPredefinedDictionary(Aruco.DICT_4X4_50)
    private val parameters: DetectorParameters = DetectorParameters.create().apply {
        set_adaptiveThreshWinSizeMin(3)
        set_adaptiveThreshWinSizeMax(23)
        set_minMarkerPerimeterRate(0.03)
        set_maxErroneousBitsInBorderRate(0.35)
    }
    
    fun detect(image: Mat): List<ArucoMarker> {
        val corners = mutableListOf<Mat>()
        val ids = Mat()
        
        Aruco.detectMarkers(image, dictionary, corners, ids, parameters)
        
        return (0 until ids.rows()).map { i ->
            ArucoMarker(
                id = ids.get(i, 0)[0].toInt(),
                corners = corners[i].toList()
            )
        }
    }
}
```

### Flutter Platform Channel

```dart
// lib/platform_channels/aruco_channel.dart

class ArucoChannel {
  static const MethodChannel _channel = MethodChannel('com.tracecast/aruco');
  
  /// Detect ArUco markers in image bytes
  /// Returns list of detected markers with IDs and corner positions
  static Future<List<ArucoMarker>> detectMarkers(Uint8List imageBytes) async {
    final result = await _channel.invokeMethod('detectMarkers', {
      'image': imageBytes,
      'dictionary': 'DICT_4X4_50',
    });
    
    return (result as List).map((m) => ArucoMarker.fromMap(m)).toList();
  }
  
  /// Calculate perspective transform from 4 marker corners
  static Future<PerspectiveTransform> calculateTransform(
    List<Point> srcCorners,
    Size targetSize,
  ) async {
    final result = await _channel.invokeMethod('calculateTransform', {
      'corners': srcCorners.map((p) => [p.x, p.y]).toList(),
      'targetWidth': targetSize.width,
      'targetHeight': targetSize.height,
    });
    
    return PerspectiveTransform.fromMatrix(result);
  }
}
```

---

## 7. Reference Sheet Specification

### Printable PDF Specifications

| Attribute | A4 Version | Letter Version |
|-----------|------------|----------------|
| Page size | 210mm × 297mm | 8.5" × 11" |
| Marker positions | 20mm from edges | 0.75" from edges |
| Marker size | 30mm × 30mm | 30mm × 30mm |
| Inter-marker distance | Calculated from positions | Calculated from positions |
| QR code (optional) | Center, links to app help | Center, links to app help |

### Reference Sheet Layout (A4)

```
┌────────────────────────────────────────────────────────────────┐
│  (20,20)                                            (160,20)   │
│   ┌────┐                                              ┌────┐   │
│   │ 0  │                                              │ 1  │   │
│   └────┘                                              └────┘   │
│                                                                │
│                                                                │
│                        ┌──────────────┐                        │
│                        │  [QR CODE]   │                        │
│                        │ tracecast.app│                        │
│                        │    /help     │                        │
│                        └──────────────┘                        │
│                                                                │
│              TraceCast Reference Sheet v1.0                    │
│         Print at 100% scale (no fit-to-page)                  │
│                                                                │
│   ┌────┐                                              ┌────┐   │
│   │ 3  │                                              │ 2  │   │
│   └────┘                                              └────┘   │
│  (20,257)                                          (160,257)   │
└────────────────────────────────────────────────────────────────┘
```

### Marker Position Constants

```dart
// lib/core/constants/reference_sheet.dart

class ReferenceSheetA4 {
  static const double pageWidthMm = 210.0;
  static const double pageHeightMm = 297.0;
  static const double marginMm = 20.0;
  static const double markerSizeMm = 30.0;
  
  static const List<Offset> markerPositionsMm = [
    Offset(20, 20),    // ID 0: top-left
    Offset(160, 20),   // ID 1: top-right
    Offset(160, 257),  // ID 2: bottom-right
    Offset(20, 257),   // ID 3: bottom-left
  ];
  
  // Known distances for scale calculation
  static const double horizontalDistanceMm = 140.0; // Between ID 0 and ID 1
  static const double verticalDistanceMm = 237.0;   // Between ID 0 and ID 3
  static const double diagonalDistanceMm = 275.3;   // Between ID 0 and ID 2
}

class ReferenceSheetLetter {
  static const double pageWidthMm = 215.9; // 8.5"
  static const double pageHeightMm = 279.4; // 11"
  static const double marginMm = 19.05; // 0.75"
  static const double markerSizeMm = 30.0;
  
  // Calculate positions based on margins
  static List<Offset> get markerPositionsMm => [
    Offset(marginMm, marginMm),
    Offset(pageWidthMm - marginMm - markerSizeMm, marginMm),
    Offset(pageWidthMm - marginMm - markerSizeMm, pageHeightMm - marginMm - markerSizeMm),
    Offset(marginMm, pageHeightMm - marginMm - markerSizeMm),
  ];
}
```

### PDF Generation

```dart
// lib/features/help/reference_sheet_generator.dart

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<Uint8List> generateReferenceSheet(ReferenceSheetSize size) async {
  final pdf = pw.Document();
  final config = size == ReferenceSheetSize.a4 
      ? ReferenceSheetA4() 
      : ReferenceSheetLetter();
  
  pdf.addPage(pw.Page(
    pageFormat: size == ReferenceSheetSize.a4 
        ? PdfPageFormat.a4 
        : PdfPageFormat.letter,
    build: (context) => pw.Stack(
      children: [
        // Marker 0 (top-left)
        pw.Positioned(
          left: config.marginMm * PdfPageFormat.mm,
          top: config.marginMm * PdfPageFormat.mm,
          child: _buildArucoMarker(0, config.markerSizeMm),
        ),
        // ... repeat for markers 1, 2, 3
        
        // Center instructions
        pw.Center(
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text('TraceCast Reference Sheet',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text('Print at 100% scale (no fit-to-page)',
                style: pw.TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ],
    ),
  ));
  
  return pdf.save();
}
```

---

## 8. Testing & Validation

### Unit Tests

```dart
// test/core/services/aruco_detector_test.dart

void main() {
  group('ArucoDetector', () {
    test('detects all 4 markers in reference sheet image', () async {
      final testImage = await loadTestImage('assets/test/reference_sheet_clean.jpg');
      final detector = ArucoDetector();
      
      final markers = await detector.detect(testImage);
      
      expect(markers.length, equals(4));
      expect(markers.map((m) => m.id).toSet(), equals({0, 1, 2, 3}));
    });
    
    test('calculates correct scale from known markers', () async {
      final testImage = await loadTestImage('assets/test/reference_a4_1000px.jpg');
      final detector = ArucoDetector();
      final calibrator = ScaleCalibrator();
      
      final markers = await detector.detect(testImage);
      final scale = calibrator.calculateScale(markers, ReferenceSheetA4());
      
      // Image is 1000px wide, A4 is 210mm wide
      // Expected scale: 210/1000 = 0.21 mm/px
      expect(scale.mmPerPx, closeTo(0.21, 0.01));
    });
    
    test('handles partial occlusion gracefully', () async {
      final testImage = await loadTestImage('assets/test/reference_one_covered.jpg');
      final detector = ArucoDetector();
      
      final markers = await detector.detect(testImage);
      
      // Should detect 3 markers, still calculate scale
      expect(markers.length, greaterThanOrEqualTo(3));
    });
  });
}
```

### Integration Tests

| Test Case | Expected Result |
|-----------|-----------------|
| Clean reference sheet, good lighting | All 4 markers detected, ±0.3% scale accuracy |
| Reference sheet with pattern on top | Markers detected, pattern area identified |
| Slight motion blur | Markers detected with lower confidence |
| Partial marker occlusion (1 marker covered) | 3 markers detected, scale still calculated |
| Extreme angle (>45°) | Markers detected, perspective transform applied |
| Low light conditions | Markers detected with increased threshold |

### Device Testing Matrix

| Device | iOS Version | Expected Performance |
|--------|-------------|---------------------|
| iPhone 12+ | iOS 16+ | <50ms detection @ 30fps |
| iPhone SE 2nd gen | iOS 15+ | <80ms detection @ 30fps |
| iPad Pro | iOS 16+ | <40ms detection @ 30fps |

| Device | Android Version | Expected Performance |
|--------|-----------------|---------------------|
| Pixel 6+ | Android 12+ | <60ms detection @ 30fps |
| Samsung S21+ | Android 11+ | <70ms detection @ 30fps |
| Mid-range (Pixel 4a) | Android 11+ | <100ms detection @ 30fps |

### Accuracy Validation Protocol

1. Print reference sheet at 100% scale on calibrated printer
2. Place pattern piece with known dimensions on reference sheet
3. Capture image, run vectorization
4. Measure output dimensions vs. physical measurements
5. Log: `actual_mm`, `measured_mm`, `error_percentage`
6. Target: 95th percentile error < 0.5%

---

## Appendix A: Troubleshooting

### Common Detection Failures

| Symptom | Cause | Solution |
|---------|-------|----------|
| No markers detected | Poor lighting | Prompt user for better lighting |
| Partial detection | Marker partially out of frame | Show guide overlay |
| Wrong scale calculated | Reference sheet not printed at 100% | Show calibration verification |
| Jittery detection | Rapid movement | Increase `stabilityFrames` |
| False positives | Complex pattern with marker-like shapes | Increase `minConfidence` threshold |

### Debug Logging

```dart
// Enable in development only
class ArucoDebugLogger {
  static void log(ArucoDetectionResult result) {
    if (!kDebugMode) return;
    
    print('[ArUco] Detected ${result.markers.length} markers');
    for (final marker in result.markers) {
      print('  ID ${marker.id}: corners=${marker.corners}, confidence=${marker.confidence}');
    }
    print('[ArUco] Scale: ${result.scale?.mmPerPx} mm/px');
    print('[ArUco] Processing time: ${result.processingTimeMs}ms');
  }
}
```
