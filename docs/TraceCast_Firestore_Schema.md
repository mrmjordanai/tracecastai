# TraceCast: Firestore Data Model

**Version 1.0 | December 2025**

Canonical reference for all Firestore collections, documents, and required indexes.

---

## Table of Contents

1. [Collection Structure Overview](#1-collection-structure-overview)
2. [User Document](#2-user-document)
3. [Project Document](#3-project-document)
4. [Piece Document](#4-piece-document)
5. [Pending Captures (Local)](#5-pending-captures-local)
6. [Required Indexes](#6-required-indexes)
7. [Security Rules](#7-security-rules)
8. [Data Migration Notes](#8-data-migration-notes)

---

## 1. Collection Structure Overview

```
firestore/
├── users/
│   └── {userId}/
│       ├── (user profile fields)
│       ├── projects/
│       │   └── {projectId}/
│       │       ├── (project fields)
│       │       └── pieces/
│       │           └── {pieceId}/
│       │               └── (piece fields)
│       └── usage/
│           └── {monthYear}/
│               └── (usage tracking for rate limiting)
```

---

## 2. User Document

**Path:** `/users/{userId}`

```typescript
interface User {
  // Identity
  userId: string;                    // Firebase Auth UID
  email: string;                     // From auth provider
  displayName: string | null;        // Optional
  photoUrl: string | null;           // Avatar from auth provider
  
  // Auth
  authProvider: 'apple' | 'google' | 'email';
  createdAt: Timestamp;
  lastLoginAt: Timestamp;
  
  // Subscription (synced from RevenueCat)
  subscription: {
    status: 'trial' | 'active' | 'expired' | 'none';
    productId: string | null;        // e.g., 'tracecast_annual_2999'
    expiresAt: Timestamp | null;
    trialEndsAt: Timestamp | null;
    originalPurchaseDate: Timestamp | null;
  };
  
  // Preferences
  preferences: {
    units: 'mm' | 'in' | 'cm';
    defaultLineWidthMm: number;      // Default: 1.2
    autoCapture: boolean;            // Default: true
    hapticFeedback: boolean;         // Default: true
    defaultProjectorColor: string;   // Default: '#FFFFFF'
    testSquareSizeMm: number;        // Default: 100 (4 inches)
  };
  
  // Stats
  stats: {
    totalProjects: number;
    totalPieces: number;
    totalScansThisMonth: number;
  };
  
  // Feature flags (for A/B testing)
  featureFlags: {
    enableContrastNormalization: boolean;
    showBetaFeatures: boolean;
  };
  
  // FCM token for push notifications
  fcmTokens: string[];               // Multiple devices
}
```

**Dart Model:**

```dart
// lib/core/models/user_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String authProvider;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final SubscriptionInfo subscription;
  final UserPreferences preferences;
  final UserStats stats;
  final List<String> fcmTokens;
  
  UserModel({
    required this.userId,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.authProvider,
    required this.createdAt,
    required this.lastLoginAt,
    required this.subscription,
    required this.preferences,
    required this.stats,
    this.fcmTokens = const [],
  });
  
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      userId: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoUrl: data['photoUrl'],
      authProvider: data['authProvider'] ?? 'email',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp).toDate(),
      subscription: SubscriptionInfo.fromMap(data['subscription'] ?? {}),
      preferences: UserPreferences.fromMap(data['preferences'] ?? {}),
      stats: UserStats.fromMap(data['stats'] ?? {}),
      fcmTokens: List<String>.from(data['fcmTokens'] ?? []),
    );
  }
  
  Map<String, dynamic> toFirestore() => {
    'email': email,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'authProvider': authProvider,
    'createdAt': Timestamp.fromDate(createdAt),
    'lastLoginAt': Timestamp.fromDate(lastLoginAt),
    'subscription': subscription.toMap(),
    'preferences': preferences.toMap(),
    'stats': stats.toMap(),
    'fcmTokens': fcmTokens,
  };
}

class SubscriptionInfo {
  final String status;
  final String? productId;
  final DateTime? expiresAt;
  final DateTime? trialEndsAt;
  
  SubscriptionInfo({
    required this.status,
    this.productId,
    this.expiresAt,
    this.trialEndsAt,
  });
  
  factory SubscriptionInfo.fromMap(Map<String, dynamic> map) => SubscriptionInfo(
    status: map['status'] ?? 'none',
    productId: map['productId'],
    expiresAt: (map['expiresAt'] as Timestamp?)?.toDate(),
    trialEndsAt: (map['trialEndsAt'] as Timestamp?)?.toDate(),
  );
  
  Map<String, dynamic> toMap() => {
    'status': status,
    'productId': productId,
    'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    'trialEndsAt': trialEndsAt != null ? Timestamp.fromDate(trialEndsAt!) : null,
  };
  
  bool get isActive => status == 'trial' || status == 'active';
}

class UserPreferences {
  final String units;
  final double defaultLineWidthMm;
  final bool autoCapture;
  final bool hapticFeedback;
  final String defaultProjectorColor;
  final double testSquareSizeMm;
  
  UserPreferences({
    this.units = 'in',
    this.defaultLineWidthMm = 1.2,
    this.autoCapture = true,
    this.hapticFeedback = true,
    this.defaultProjectorColor = '#FFFFFF',
    this.testSquareSizeMm = 100,
  });
  
  factory UserPreferences.fromMap(Map<String, dynamic> map) => UserPreferences(
    units: map['units'] ?? 'in',
    defaultLineWidthMm: (map['defaultLineWidthMm'] ?? 1.2).toDouble(),
    autoCapture: map['autoCapture'] ?? true,
    hapticFeedback: map['hapticFeedback'] ?? true,
    defaultProjectorColor: map['defaultProjectorColor'] ?? '#FFFFFF',
    testSquareSizeMm: (map['testSquareSizeMm'] ?? 100).toDouble(),
  );
  
  Map<String, dynamic> toMap() => {
    'units': units,
    'defaultLineWidthMm': defaultLineWidthMm,
    'autoCapture': autoCapture,
    'hapticFeedback': hapticFeedback,
    'defaultProjectorColor': defaultProjectorColor,
    'testSquareSizeMm': testSquareSizeMm,
  };
}

class UserStats {
  final int totalProjects;
  final int totalPieces;
  final int totalScansThisMonth;
  
  UserStats({
    this.totalProjects = 0,
    this.totalPieces = 0,
    this.totalScansThisMonth = 0,
  });
  
  factory UserStats.fromMap(Map<String, dynamic> map) => UserStats(
    totalProjects: map['totalProjects'] ?? 0,
    totalPieces: map['totalPieces'] ?? 0,
    totalScansThisMonth: map['totalScansThisMonth'] ?? 0,
  );
  
  Map<String, dynamic> toMap() => {
    'totalProjects': totalProjects,
    'totalPieces': totalPieces,
    'totalScansThisMonth': totalScansThisMonth,
  };
}
```

---

## 3. Project Document

**Path:** `/users/{userId}/projects/{projectId}`

```typescript
interface Project {
  projectId: string;                 // Auto-generated UUID
  name: string;                      // User-editable
  mode: 'sewing' | 'quilting' | 'stencil' | 'maker' | 'custom';
  
  // Metadata
  createdAt: Timestamp;
  updatedAt: Timestamp;
  
  // Stats
  pieceCount: number;                // Denormalized for quick display
  
  // Thumbnail (first piece preview)
  thumbnailUrl: string | null;       // Firebase Storage URL
  
  // Tags for search/filter
  tags: string[];                    // e.g., ['vintage', 'bodice', 'mcCall']
  
  // Source info
  sourceImageCount: number;          // Number of original photos
}
```

**Dart Model:**

```dart
// lib/core/models/project_model.dart

class ProjectModel {
  final String projectId;
  final String name;
  final String mode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int pieceCount;
  final String? thumbnailUrl;
  final List<String> tags;
  final int sourceImageCount;
  
  ProjectModel({
    required this.projectId,
    required this.name,
    required this.mode,
    required this.createdAt,
    required this.updatedAt,
    this.pieceCount = 0,
    this.thumbnailUrl,
    this.tags = const [],
    this.sourceImageCount = 0,
  });
  
  factory ProjectModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProjectModel(
      projectId: doc.id,
      name: data['name'] ?? 'Untitled',
      mode: data['mode'] ?? 'sewing',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      pieceCount: data['pieceCount'] ?? 0,
      thumbnailUrl: data['thumbnailUrl'],
      tags: List<String>.from(data['tags'] ?? []),
      sourceImageCount: data['sourceImageCount'] ?? 0,
    );
  }
  
  Map<String, dynamic> toFirestore() => {
    'name': name,
    'mode': mode,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'pieceCount': pieceCount,
    'thumbnailUrl': thumbnailUrl,
    'tags': tags,
    'sourceImageCount': sourceImageCount,
  };
}
```

---

## 4. Piece Document

**Path:** `/users/{userId}/projects/{projectId}/pieces/{pieceId}`

```typescript
interface Piece {
  pieceId: string;                   // Auto-generated UUID
  name: string;                      // e.g., "Front Bodice", "Piece 1"
  
  // Source reference
  sourceImageId: string;             // Original photo ID in Storage
  sourceImageUrl: string;            // Firebase Storage URL
  
  // Scale calibration
  scaleMmPerPx: number;              // Conversion factor
  scaleConfidence: number;           // 0-1 from AI
  scaleMethod: 'aruco' | 'grid' | 'card' | 'manual';
  
  // Dimensions (calculated from vectors + scale)
  widthMm: number;
  heightMm: number;
  
  // Vector layers (the core data)
  layers: {
    cutline: Path[];
    markings: Path[];
    labels: TextBox[];
  };
  
  // QA info from AI
  qa: {
    confidence: number;              // Overall 0-1
    warnings: string[];              // e.g., ["Low contrast in corner"]
  };
  
  // User edits tracking
  editHistory: {
    originalPaths: Path[];           // Before any user edits
    hasEdits: boolean;
  };
  
  // Timestamps
  createdAt: Timestamp;
  updatedAt: Timestamp;
  
  // Processing status
  status: 'pending' | 'processing' | 'complete' | 'failed';
  errorMessage: string | null;
}

interface Path {
  pathId: string;
  pathType: 'cutline' | 'dart' | 'notch' | 'grainline' | 'fold_line' | 'seam_line';
  closed: boolean;
  points: Array<{ x_mm: number; y_mm: number }>;
  strokeHintMm: number;
  confidence: number;
}

interface TextBox {
  labelId: string;
  text: string;
  position: { x_mm: number; y_mm: number };
  size: { width_mm: number; height_mm: number };
  confidence: number;
}
```

**Dart Model:**

```dart
// lib/core/models/piece_model.dart

class PieceModel {
  final String pieceId;
  final String name;
  final String sourceImageId;
  final String sourceImageUrl;
  final double scaleMmPerPx;
  final double scaleConfidence;
  final String scaleMethod;
  final double widthMm;
  final double heightMm;
  final PieceLayers layers;
  final PieceQA qa;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status;
  final String? errorMessage;
  
  PieceModel({
    required this.pieceId,
    required this.name,
    required this.sourceImageId,
    required this.sourceImageUrl,
    required this.scaleMmPerPx,
    required this.scaleConfidence,
    required this.scaleMethod,
    required this.widthMm,
    required this.heightMm,
    required this.layers,
    required this.qa,
    required this.createdAt,
    required this.updatedAt,
    this.status = 'pending',
    this.errorMessage,
  });
  
  factory PieceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PieceModel(
      pieceId: doc.id,
      name: data['name'] ?? 'Untitled',
      sourceImageId: data['sourceImageId'] ?? '',
      sourceImageUrl: data['sourceImageUrl'] ?? '',
      scaleMmPerPx: (data['scaleMmPerPx'] ?? 0).toDouble(),
      scaleConfidence: (data['scaleConfidence'] ?? 0).toDouble(),
      scaleMethod: data['scaleMethod'] ?? 'manual',
      widthMm: (data['widthMm'] ?? 0).toDouble(),
      heightMm: (data['heightMm'] ?? 0).toDouble(),
      layers: PieceLayers.fromMap(data['layers'] ?? {}),
      qa: PieceQA.fromMap(data['qa'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
      errorMessage: data['errorMessage'],
    );
  }
  
  Map<String, dynamic> toFirestore() => {
    'name': name,
    'sourceImageId': sourceImageId,
    'sourceImageUrl': sourceImageUrl,
    'scaleMmPerPx': scaleMmPerPx,
    'scaleConfidence': scaleConfidence,
    'scaleMethod': scaleMethod,
    'widthMm': widthMm,
    'heightMm': heightMm,
    'layers': layers.toMap(),
    'qa': qa.toMap(),
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'status': status,
    'errorMessage': errorMessage,
  };
}

class PieceLayers {
  final List<PathModel> cutline;
  final List<PathModel> markings;
  final List<TextBoxModel> labels;
  
  PieceLayers({
    this.cutline = const [],
    this.markings = const [],
    this.labels = const [],
  });
  
  factory PieceLayers.fromMap(Map<String, dynamic> map) => PieceLayers(
    cutline: (map['cutline'] as List? ?? [])
        .map((p) => PathModel.fromMap(p))
        .toList(),
    markings: (map['markings'] as List? ?? [])
        .map((p) => PathModel.fromMap(p))
        .toList(),
    labels: (map['labels'] as List? ?? [])
        .map((l) => TextBoxModel.fromMap(l))
        .toList(),
  );
  
  Map<String, dynamic> toMap() => {
    'cutline': cutline.map((p) => p.toMap()).toList(),
    'markings': markings.map((p) => p.toMap()).toList(),
    'labels': labels.map((l) => l.toMap()).toList(),
  };
}

class PathModel {
  final String pathId;
  final String pathType;
  final bool closed;
  final List<Point> points;
  final double strokeHintMm;
  final double confidence;
  
  PathModel({
    required this.pathId,
    required this.pathType,
    required this.closed,
    required this.points,
    required this.strokeHintMm,
    required this.confidence,
  });
  
  factory PathModel.fromMap(Map<String, dynamic> map) => PathModel(
    pathId: map['pathId'] ?? '',
    pathType: map['pathType'] ?? 'cutline',
    closed: map['closed'] ?? false,
    points: (map['points'] as List? ?? [])
        .map((p) => Point(
              (p['x_mm'] ?? 0).toDouble(),
              (p['y_mm'] ?? 0).toDouble(),
            ))
        .toList(),
    strokeHintMm: (map['strokeHintMm'] ?? 0.5).toDouble(),
    confidence: (map['confidence'] ?? 1.0).toDouble(),
  );
  
  Map<String, dynamic> toMap() => {
    'pathId': pathId,
    'pathType': pathType,
    'closed': closed,
    'points': points.map((p) => {'x_mm': p.x, 'y_mm': p.y}).toList(),
    'strokeHintMm': strokeHintMm,
    'confidence': confidence,
  };
}

class TextBoxModel {
  final String labelId;
  final String text;
  final Point position;
  final Size size;
  final double confidence;
  
  TextBoxModel({
    required this.labelId,
    required this.text,
    required this.position,
    required this.size,
    required this.confidence,
  });
  
  factory TextBoxModel.fromMap(Map<String, dynamic> map) => TextBoxModel(
    labelId: map['labelId'] ?? '',
    text: map['text'] ?? '',
    position: Point(
      (map['position']?['x_mm'] ?? 0).toDouble(),
      (map['position']?['y_mm'] ?? 0).toDouble(),
    ),
    size: Size(
      (map['size']?['width_mm'] ?? 0).toDouble(),
      (map['size']?['height_mm'] ?? 0).toDouble(),
    ),
    confidence: (map['confidence'] ?? 1.0).toDouble(),
  );
  
  Map<String, dynamic> toMap() => {
    'labelId': labelId,
    'text': text,
    'position': {'x_mm': position.x, 'y_mm': position.y},
    'size': {'width_mm': size.width, 'height_mm': size.height},
    'confidence': confidence,
  };
}

class PieceQA {
  final double confidence;
  final List<String> warnings;
  
  PieceQA({this.confidence = 0, this.warnings = const []});
  
  factory PieceQA.fromMap(Map<String, dynamic> map) => PieceQA(
    confidence: (map['confidence'] ?? 0).toDouble(),
    warnings: List<String>.from(map['warnings'] ?? []),
  );
  
  Map<String, dynamic> toMap() => {
    'confidence': confidence,
    'warnings': warnings,
  };
}

class Point {
  final double x;
  final double y;
  Point(this.x, this.y);
}

class Size {
  final double width;
  final double height;
  Size(this.width, this.height);
}
```

---

## 5. Pending Captures (Local)

**Storage:** Hive local database (NOT Firestore)

This is for offline queue only. See `TraceCast_PRD_v1.md` Section 8.4 for full spec.

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

---

## 5.1 App Constants

**Path:** `lib/core/constants/subscription_constants.dart`

```dart
// lib/core/constants/subscription_constants.dart

/// RevenueCat product and entitlement identifiers.
/// These must match exactly what's configured in RevenueCat dashboard.
class SubscriptionProducts {
  /// Monthly subscription product ID
  static const monthlyId = 'tracecast_monthly_399';
  
  /// Annual subscription product ID (includes 3-day free trial)
  static const annualId = 'tracecast_annual_2999';
  
  /// Entitlement identifier for pro features
  static const entitlementId = 'pro';
  
  /// All product IDs for RevenueCat offerings
  static const allProductIds = [monthlyId, annualId];
}

/// Subscription pricing for display purposes.
/// Actual pricing comes from RevenueCat but these are fallbacks.
class SubscriptionPricing {
  static const monthlyPriceUSD = 3.99;
  static const annualPriceUSD = 29.99;
  static const trialDays = 3;  // Only for annual
}
```

---

## 6. Required Indexes

Create these indexes in `firestore.indexes.json`:

```json
{
  "indexes": [
    {
      "collectionGroup": "projects",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "updatedAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "projects",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "mode", "order": "ASCENDING" },
        { "fieldPath": "updatedAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "pieces",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "pieces",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

**Common Queries:**

| Query | Index Used |
|-------|-----------|
| Get all projects, newest first | `projects.updatedAt DESC` |
| Filter projects by mode | `projects.mode ASC, updatedAt DESC` |
| Get pieces in a project | `pieces.createdAt DESC` |
| Get pending pieces | `pieces.status ASC, createdAt DESC` |

---

## 7. Security Rules

**File:** `firestore.rules`

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users can only access their own data
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
      
      // Usage tracking (read-only for client, written by Cloud Functions)
      match /usage/{monthYear} {
        allow read: if request.auth != null && request.auth.uid == userId;
        allow write: if false; // Only Cloud Functions can write
      }
    }
    
    // Deny all other access
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

---

## 8. Data Migration Notes

### Creating a New User

When a user signs up, create the document with default values:

```dart
Future<void> createUserDocument(User authUser) async {
  final userDoc = FirebaseFirestore.instance.collection('users').doc(authUser.uid);
  
  final exists = (await userDoc.get()).exists;
  if (exists) return;
  
  await userDoc.set({
    'email': authUser.email,
    'displayName': authUser.displayName,
    'photoUrl': authUser.photoURL,
    'authProvider': _detectProvider(authUser),
    'createdAt': FieldValue.serverTimestamp(),
    'lastLoginAt': FieldValue.serverTimestamp(),
    'subscription': {
      'status': 'none',
      'productId': null,
      'expiresAt': null,
      'trialEndsAt': null,
    },
    'preferences': UserPreferences().toMap(),
    'stats': UserStats().toMap(),
    'fcmTokens': [],
  });
}
```

### Syncing RevenueCat with Firestore

RevenueCat webhook → Cloud Function → Update user document:

```typescript
// functions/src/revenueCatWebhook.ts

export const revenueCatWebhook = functions.https.onRequest(async (req, res) => {
  const event = req.body;
  const userId = event.app_user_id;
  
  await admin.firestore().collection('users').doc(userId).update({
    'subscription.status': mapStatus(event.type),
    'subscription.productId': event.product_id,
    'subscription.expiresAt': event.expiration_at_ms 
      ? admin.firestore.Timestamp.fromMillis(event.expiration_at_ms)
      : null,
  });
  
  res.sendStatus(200);
});
```
