# TraceCast: AI Prompt Engineering Appendix

**Version 1.0 | December 2025**

Appendix to TraceCast PRD v1.0 — AI Vectorization Implementation Specification

---

## Table of Contents

1. [Overview](#1-overview)
2. [OpenRouter Configuration](#2-openrouter-configuration)
3. [Prompt Architecture](#3-prompt-architecture)
4. [Response Schema](#4-response-schema)
5. [Error Handling](#5-error-handling)
6. [Cloud Function Implementation](#6-cloud-function-implementation)
7. [External Display Architecture](#7-external-display-architecture)
8. [Testing & Validation](#8-testing--validation)

---

## 1. Overview

TraceCast uses vision-language models via OpenRouter to extract vector data from pattern photographs. This appendix specifies the exact prompts, expected outputs, and error handling required for implementation.

### Core Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Client    │────▶│  Firebase   │────▶│  OpenRouter │────▶│   Client    │
│  (Flutter)  │     │  Function   │     │   (Vision)  │     │  (Flutter)  │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
      │                   │                   │                   │
      │  Upload image     │                   │                   │
      │  + metadata       │                   │                   │
      │──────────────────▶│                   │                   │
      │                   │  POST /chat       │                   │
      │                   │  + image base64   │                   │
      │                   │──────────────────▶│                   │
      │                   │                   │  JSON response    │
      │                   │◀──────────────────│                   │
      │                   │  Parse + validate │                   │
      │                   │  Transform to     │                   │
      │                   │  Piece model      │                   │
      │  Piece data       │◀──────────────────│                   │
      │◀──────────────────│                   │                   │
```

---

## 2. OpenRouter Configuration

> [!IMPORTANT]
> **Before Implementation: Verify Model IDs**
> 
> OpenRouter model identifiers change as providers update their offerings. Before starting development:
> 
> 1. Visit https://openrouter.ai/models
> 2. Search for each model in the priority chain
> 3. Verify the exact model ID string
> 4. Update the configuration below if needed
> 
> **Known Model IDs (as of December 2025):**
> | Provider | Model | Verified ID |
> |----------|-------|-------------|
> | Google | Gemini 2.0 Flash | `google/gemini-2.0-flash-exp` |
> | Google | Gemini 1.5 Flash | `google/gemini-1.5-flash` |
> | Anthropic | Claude Sonnet 4 | `anthropic/claude-sonnet-4-20250514` |
> | OpenAI | GPT-4o | `openai/gpt-4o` |
> 
> If a model ID is invalid, OpenRouter returns a 400 error with `"error": "Model not found"`.

### Model Priority Chain

Configure via Firebase Remote Config for hot-swapping without app updates:

```json
{
  "ai_vectorization": {
    "models": [
      {
        "id": "google/gemini-2.0-flash-exp",
        "priority": 0,
        "timeout_ms": 30000,
        "max_tokens": 8192,
        "notes": "Primary - fastest, best value"
      },
      {
        "id": "google/gemini-1.5-flash",
        "priority": 1,
        "timeout_ms": 30000,
        "max_tokens": 8192,
        "notes": "Fallback if 2.0 unavailable"
      },
      {
        "id": "anthropic/claude-sonnet-4-20250514",
        "priority": 2,
        "timeout_ms": 45000,
        "max_tokens": 8192,
        "notes": "High accuracy fallback for complex patterns"
      },
      {
        "id": "openai/gpt-4o",
        "priority": 3,
        "timeout_ms": 45000,
        "max_tokens": 8192,
        "notes": "Last resort"
      }
    ],
    "retry_delays_ms": [1000, 2000, 4000],
    "max_image_dimension": 2048,
    "jpeg_quality": 85
  }
}
```

### API Request Structure

```typescript
// OpenRouter API call
const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${OPENROUTER_API_KEY}`,
    'Content-Type': 'application/json',
    'HTTP-Referer': 'https://tracecast.app',
    'X-Title': 'TraceCast'
  },
  body: JSON.stringify({
    model: modelId,
    max_tokens: 4096,
    temperature: 0.1, // Low temperature for consistent structured output
    response_format: { type: "json_object" }, // Force JSON output (Gemini 2.0+)
    messages: [
      { role: 'system', content: SYSTEM_PROMPT },
      { 
        role: 'user', 
        content: [
          { type: 'text', text: USER_PROMPT },
          { 
            type: 'image_url', 
            image_url: { 
              url: `data:image/jpeg;base64,${imageBase64}`,
              detail: 'high'
            }
          }
        ]
      }
    ]
  })
});
```

---

## 3. Prompt Architecture

### System Prompt

```
You are a specialized pattern vectorization AI for TraceCast, an app that digitizes sewing patterns, quilting templates, and craft stencils for projector use.

Your task is to analyze a photograph of a pattern piece and extract:
1. The primary cutline (outer boundary for cutting)
2. Internal markings (darts, notches, grainlines, fold lines)
3. Text labels (pattern piece names, sizes, quantities)

CRITICAL REQUIREMENTS:
- All coordinates must be in PIXELS relative to the image dimensions provided
- Paths must be arrays of [x, y] coordinate pairs
- Cutlines should form CLOSED paths (first point = last point)
- Ignore wrinkles, shadows, stains, and background noise
- Focus only on the intentional printed/drawn lines
- If you cannot detect a clear cutline, set confidence to 0 and explain in warnings

OUTPUT FORMAT:
You must respond with ONLY valid JSON matching the schema provided. No markdown, no explanation, no preamble. Just the JSON object.
```

### User Prompt Template

```
Analyze this pattern photograph and extract vector data.

IMAGE DIMENSIONS: {width}px × {height}px
PATTERN MODE: {mode}
SCALE REFERENCE: {scale_info}

Extract all visible:
- Cutlines (outer boundaries)
- Darts (triangular fold markings)
- Notches (small marks on edges for alignment)
- Grainlines (arrows indicating fabric direction)
- Fold lines (dashed lines indicating where to fold)
- Text labels (piece names, sizes, cutting instructions)

Respond with JSON matching this exact schema:

{
  "success": boolean,
  "confidence": number (0-100),
  "image_dimensions": { "width": number, "height": number },
  "layers": {
    "cutlines": [
      {
        "id": "cutline_1",
        "path_type": "cutline",
        "closed": boolean,
        "points": [[x, y], [x, y], ...],
        "confidence": number (0-100)
      }
    ],
    "markings": [
      {
        "id": "marking_1",
        "path_type": "dart" | "notch" | "grainline" | "fold_line" | "seam_line",
        "closed": boolean,
        "points": [[x, y], [x, y], ...],
        "confidence": number (0-100),
        "metadata": { ... }
      }
    ],
    "labels": [
      {
        "id": "label_1",
        "text": "string",
        "bounding_box": { "x": number, "y": number, "width": number, "height": number },
        "confidence": number (0-100)
      }
    ]
  },
  "warnings": ["string"],
  "processing_notes": "string"
}
```

### Mode-Specific Prompt Variations

#### Sewing Pattern Mode
```
PATTERN MODE: sewing

Additional context for sewing patterns:
- Cutlines are typically the outermost solid lines
- Look for standard sewing notations: notches (perpendicular ticks), grainline arrows, dart triangles
- Text often includes: piece name, size, "Cut 2", "Cut on fold", seam allowance info
- Ignore tissue paper texture and wrinkles
```

#### Quilting Template Mode
```
PATTERN MODE: quilting

Additional context for quilting templates:
- Shapes are often geometric (squares, triangles, hexagons)
- Look for: seam allowance lines (dashed), grain arrows, template names
- Multiple nested shapes may represent different seam allowances
- Registration marks for alignment between pieces
```

#### Stencil/Art Mode
```
PATTERN MODE: stencil

Additional context for stencils and art patterns:
- Focus on the outline to be traced or cut
- May have complex curves and decorative elements
- Text is often minimal (artist signature, design name)
- Islands (closed shapes within the main shape) are important
```

---

## 4. Response Schema

### TypeScript Interfaces

```typescript
// Raw response from AI model
interface AIVectorizeResponse {
  success: boolean;
  confidence: number; // 0-100
  image_dimensions: {
    width: number;
    height: number;
  };
  layers: {
    cutlines: AIPath[];
    markings: AIPath[];
    labels: AILabel[];
  };
  warnings: string[];
  processing_notes: string;
}

interface AIPath {
  id: string;
  path_type: 'cutline' | 'dart' | 'notch' | 'grainline' | 'fold_line' | 'seam_line';
  closed: boolean;
  points: [number, number][]; // Array of [x, y] pixel coordinates
  confidence: number; // 0-100
  metadata?: {
    direction?: 'up' | 'down' | 'left' | 'right'; // For grainlines
    dart_depth_px?: number; // For darts
  };
}

interface AILabel {
  id: string;
  text: string;
  bounding_box: {
    x: number;
    y: number;
    width: number;
    height: number;
  };
  confidence: number; // 0-100
}

// Transformed response for client (matches PRD Piece model)
interface VectorizeResult {
  piece_id: string;
  source_image_id: string;
  scale_mm_per_px: number;
  width_mm: number;
  height_mm: number;
  layers: {
    cutline: Path[];
    markings: Path[];
    labels: TextBox[];
  };
  qa: {
    confidence: number; // 0-1 (normalized from 0-100)
    warnings: string[];
  };
  raw_ai_response?: string; // For debugging, stripped in production
}

interface Path {
  path_id: string;
  path_type: 'cutline' | 'dart' | 'notch' | 'grainline' | 'fold_line' | 'seam_line';
  closed: boolean;
  points: Array<{ x_mm: number; y_mm: number }>; // Converted to mm
  stroke_hint_mm: number;
  confidence: number; // 0-1
}

interface TextBox {
  label_id: string;
  text: string;
  position: { x_mm: number; y_mm: number };
  size: { width_mm: number; height_mm: number };
  confidence: number; // 0-1
}
```

### Response Validation

```typescript
function validateAIResponse(response: unknown): AIVectorizeResponse {
  // Required fields
  if (typeof response !== 'object' || response === null) {
    throw new ValidationError('Response is not an object');
  }

  const r = response as Record<string, unknown>;

  if (typeof r.success !== 'boolean') {
    throw new ValidationError('Missing or invalid "success" field');
  }

  if (typeof r.confidence !== 'number' || r.confidence < 0 || r.confidence > 100) {
    throw new ValidationError('Missing or invalid "confidence" field');
  }

  if (!r.layers || typeof r.layers !== 'object') {
    throw new ValidationError('Missing "layers" object');
  }

  const layers = r.layers as Record<string, unknown>;

  // Validate cutlines array
  if (!Array.isArray(layers.cutlines)) {
    throw new ValidationError('Missing "layers.cutlines" array');
  }

  for (const path of layers.cutlines) {
    validatePath(path);
  }

  // Validate markings array
  if (!Array.isArray(layers.markings)) {
    throw new ValidationError('Missing "layers.markings" array');
  }

  for (const path of layers.markings) {
    validatePath(path);
  }

  // Validate labels array
  if (!Array.isArray(layers.labels)) {
    throw new ValidationError('Missing "layers.labels" array');
  }

  for (const label of layers.labels) {
    validateLabel(label);
  }

  return response as AIVectorizeResponse;
}

function validatePath(path: unknown): void {
  if (typeof path !== 'object' || path === null) {
    throw new ValidationError('Path is not an object');
  }

  const p = path as Record<string, unknown>;

  if (typeof p.id !== 'string') {
    throw new ValidationError('Path missing "id"');
  }

  if (!Array.isArray(p.points)) {
    throw new ValidationError(`Path ${p.id} missing "points" array`);
  }

  for (const point of p.points) {
    if (!Array.isArray(point) || point.length !== 2) {
      throw new ValidationError(`Path ${p.id} has invalid point format`);
    }
    if (typeof point[0] !== 'number' || typeof point[1] !== 'number') {
      throw new ValidationError(`Path ${p.id} has non-numeric coordinates`);
    }
  }
}

function validateLabel(label: unknown): void {
  if (typeof label !== 'object' || label === null) {
    throw new ValidationError('Label is not an object');
  }

  const l = label as Record<string, unknown>;

  if (typeof l.id !== 'string') {
    throw new ValidationError('Label missing "id"');
  }

  if (typeof l.text !== 'string') {
    throw new ValidationError(`Label ${l.id} missing "text"`);
  }

  if (!l.bounding_box || typeof l.bounding_box !== 'object') {
    throw new ValidationError(`Label ${l.id} missing "bounding_box"`);
  }
}
```

---

## 5. Error Handling

### Error Categories

```typescript
enum VectorizeErrorCode {
  // Client errors (4xx equivalent)
  IMAGE_TOO_SMALL = 'IMAGE_TOO_SMALL',
  IMAGE_CORRUPT = 'IMAGE_CORRUPT',
  INVALID_REQUEST = 'INVALID_REQUEST',
  
  // AI processing errors
  NO_PATTERN_DETECTED = 'NO_PATTERN_DETECTED',
  LOW_CONFIDENCE = 'LOW_CONFIDENCE',
  MALFORMED_AI_RESPONSE = 'MALFORMED_AI_RESPONSE',
  
  // Infrastructure errors (5xx equivalent)
  AI_UNAVAILABLE = 'AI_UNAVAILABLE',
  AI_TIMEOUT = 'AI_TIMEOUT',
  AI_RATE_LIMITED = 'AI_RATE_LIMITED',
  STORAGE_ERROR = 'STORAGE_ERROR',
  INTERNAL_ERROR = 'INTERNAL_ERROR'
}

interface VectorizeError {
  code: VectorizeErrorCode;
  message: string;
  retryable: boolean;
  userMessage: string;
  details?: Record<string, unknown>;
}
```

### Error Response Examples

```typescript
// No cutline detected
{
  "error": {
    "code": "NO_PATTERN_DETECTED",
    "message": "AI could not identify a clear cutline in the image",
    "retryable": true,
    "userMessage": "Couldn't find pattern edges. Try better lighting or flatten the paper.",
    "details": {
      "ai_confidence": 15,
      "ai_warnings": ["Image appears to be mostly uniform color", "No clear boundaries detected"]
    }
  }
}

// All AI models failed
{
  "error": {
    "code": "AI_UNAVAILABLE",
    "message": "All AI models failed or timed out",
    "retryable": true,
    "userMessage": "Our pattern recognition service is temporarily unavailable. Please try again in a moment.",
    "details": {
      "models_attempted": ["google/gemini-2.0-flash-exp", "google/gemini-1.5-flash", "anthropic/claude-sonnet-4-20250514"],
      "last_error": "timeout"
    }
  }
}

// Malformed AI response (model returned non-JSON)
{
  "error": {
    "code": "MALFORMED_AI_RESPONSE",
    "message": "AI returned unparseable response",
    "retryable": true,
    "userMessage": "Something went wrong processing your pattern. Please try again.",
    "details": {
      "model": "google/gemini-2.0-flash-exp",
      "raw_response_preview": "I can see a sewing pattern in the image..."
    }
  }
}
```

### Retry Logic

```typescript
async function vectorizeWithRetry(
  imageBase64: string,
  metadata: VectorizeRequest
): Promise<VectorizeResult> {
  const config = await getRemoteConfig('ai_vectorization');
  const models = config.models.sort((a, b) => a.priority - b.priority);
  
  const errors: Array<{ model: string; error: Error }> = [];
  
  for (const model of models) {
    for (let attempt = 0; attempt <= config.retry_delays_ms.length; attempt++) {
      try {
        const result = await callOpenRouter(model.id, imageBase64, metadata, model.timeout_ms);
        
        // Validate response structure
        const validated = validateAIResponse(result);
        
        // Check minimum confidence
        if (validated.confidence < 20) {
          throw new Error(`Confidence too low: ${validated.confidence}`);
        }
        
        // Transform to client format
        return transformToClientFormat(validated, metadata);
        
      } catch (error) {
        errors.push({ model: model.id, error });
        
        // Don't retry on validation errors - try next model
        if (error instanceof ValidationError) {
          break;
        }
        
        // Wait before retry (if not last attempt)
        if (attempt < config.retry_delays_ms.length) {
          await sleep(config.retry_delays_ms[attempt]);
        }
      }
    }
  }
  
  // All models failed
  throw new VectorizeError({
    code: VectorizeErrorCode.AI_UNAVAILABLE,
    message: 'All AI models failed',
    retryable: true,
    userMessage: "Couldn't analyze pattern — please try again",
    details: { errors: errors.map(e => ({ model: e.model, message: e.error.message })) }
  });
}
```

---

## 6. Cloud Function Implementation

### Function Structure

```typescript
// functions/src/vectorize.ts

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { v4 as uuidv4 } from 'uuid';

interface VectorizeRequest {
  project_id: string;
  image_id: string;
  mode: 'sewing' | 'quilting' | 'stencil' | 'maker' | 'custom';
  scale_mm_per_px: number;
  targets: Array<'cutline' | 'markings' | 'labels'>;
}

export const vectorize = functions
  .runWith({
    timeoutSeconds: 120, // 2 minutes max
    memory: '512MB'
  })
  .https.onCall(async (data: VectorizeRequest, context) => {
    // 1. Auth check
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
    }
    
    const userId = context.auth.uid;
    
    // 2. Validate request
    if (!data.project_id || !data.image_id || !data.mode) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
    }
    
    // 3. Fetch image from Storage
    const bucket = admin.storage().bucket();
    const imagePath = `users/${userId}/uploads/${data.image_id}.jpg`;
    const [imageBuffer] = await bucket.file(imagePath).download();
    const imageBase64 = imageBuffer.toString('base64');
    
    // 4. Get image dimensions
    const dimensions = await getImageDimensions(imageBuffer);
    
    // 5. Downsample if needed
    const processedImage = await downsampleIfNeeded(imageBase64, dimensions);
    
    // 6. Call AI with retry logic
    try {
      const result = await vectorizeWithRetry(processedImage.base64, {
        ...data,
        image_dimensions: processedImage.dimensions
      });
      
      // 7. Store result in Firestore
      const pieceRef = admin.firestore()
        .collection('users').doc(userId)
        .collection('projects').doc(data.project_id)
        .collection('pieces').doc(result.piece_id);
      
      await pieceRef.set({
        ...result,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp()
      });
      
      return result;
      
    } catch (error) {
      if (error instanceof VectorizeError) {
        throw new functions.https.HttpsError(
          error.retryable ? 'unavailable' : 'internal',
          error.userMessage,
          { code: error.code, details: error.details }
        );
      }
      throw error;
    }
  });
```

### Image Preprocessing

The Cloud Function applies the following preprocessing steps before sending images to OpenRouter:

**Preprocessing Pipeline:**

| Step | Operation | Specification |
|------|-----------|---------------|
| 1 | **Resize** | Max 2048px on longest edge (maintains aspect ratio) |
| 2 | **Convert to JPEG** | 85% quality (balance of size vs. detail) |
| 3 | **Auto-level contrast** | Optional (A/B test) — `sharp.normalize()` |
| 4 | **Strip EXIF** | Remove all metadata for privacy |
| 5 | **Validate minimum resolution** | Reject if shortest edge < 800px |

> [!NOTE]
> Step 3 (contrast adjustment) is controlled by Firebase Remote Config key `enable_contrast_normalization`. Default: `false`. Enable if testing shows improved AI accuracy on low-contrast images.

```typescript
import sharp from 'sharp';

interface ProcessedImage {
  base64: string;
  dimensions: { width: number; height: number };
}

async function preprocessImage(
  imageBase64: string,
  dimensions: { width: number; height: number }
): Promise<ProcessedImage> {
  const config = await getRemoteConfig('ai_vectorization');
  const maxDim = config.max_image_dimension; // 2048
  const quality = config.jpeg_quality; // 85
  const minDim = config.min_image_dimension; // 800
  const normalizeContrast = config.enable_contrast_normalization; // false
  
  // Step 5: Validate minimum resolution
  const minCurrent = Math.min(dimensions.width, dimensions.height);
  if (minCurrent < minDim) {
    throw new PreprocessingError('IMAGE_TOO_SMALL', 
      `Image too small: ${minCurrent}px < ${minDim}px minimum`);
  }
  
  const maxCurrent = Math.max(dimensions.width, dimensions.height);
  
  // Step 1: Calculate resize dimensions (if needed)
  let newWidth = dimensions.width;
  let newHeight = dimensions.height;
  if (maxCurrent > maxDim) {
    const scale = maxDim / maxCurrent;
    newWidth = Math.round(dimensions.width * scale);
    newHeight = Math.round(dimensions.height * scale);
  }
  
  const inputBuffer = Buffer.from(imageBase64, 'base64');
  
  // Build sharp pipeline
  let pipeline = sharp(inputBuffer)
    .resize(newWidth, newHeight)  // Step 1: Resize
    .removeAlpha();               // Ensure no alpha channel
  
  // Step 3: Optional contrast normalization
  if (normalizeContrast) {
    pipeline = pipeline.normalize();
  }
  
  // Steps 2 & 4: Convert to JPEG (strips EXIF automatically)
  const outputBuffer = await pipeline
    .jpeg({ quality, mozjpeg: true })
    .toBuffer();
  
  return {
    base64: outputBuffer.toString('base64'),
    dimensions: { width: newWidth, height: newHeight }
  };
}
```

### Coordinate Transformation

```typescript
function transformToClientFormat(
  aiResponse: AIVectorizeResponse,
  request: VectorizeRequest
): VectorizeResult {
  const { scale_mm_per_px } = request;
  const pieceId = uuidv4();
  
  // Convert pixel coordinates to mm
  const transformPath = (aiPath: AIPath): Path => ({
    path_id: aiPath.id,
    path_type: aiPath.path_type,
    closed: aiPath.closed,
    points: aiPath.points.map(([x, y]) => ({
      x_mm: x * scale_mm_per_px,
      y_mm: y * scale_mm_per_px
    })),
    stroke_hint_mm: 0.5, // Default stroke width
    confidence: aiPath.confidence / 100 // Normalize to 0-1
  });
  
  const transformLabel = (aiLabel: AILabel): TextBox => ({
    label_id: aiLabel.id,
    text: aiLabel.text,
    position: {
      x_mm: aiLabel.bounding_box.x * scale_mm_per_px,
      y_mm: aiLabel.bounding_box.y * scale_mm_per_px
    },
    size: {
      width_mm: aiLabel.bounding_box.width * scale_mm_per_px,
      height_mm: aiLabel.bounding_box.height * scale_mm_per_px
    },
    confidence: aiLabel.confidence / 100
  });
  
  return {
    piece_id: pieceId,
    source_image_id: request.image_id,
    scale_mm_per_px: scale_mm_per_px,
    width_mm: aiResponse.image_dimensions.width * scale_mm_per_px,
    height_mm: aiResponse.image_dimensions.height * scale_mm_per_px,
    layers: {
      cutline: aiResponse.layers.cutlines.map(transformPath),
      markings: aiResponse.layers.markings.map(transformPath),
      labels: aiResponse.layers.labels.map(transformLabel)
    },
    qa: {
      confidence: aiResponse.confidence / 100,
      warnings: aiResponse.warnings
    }
  };
}
```

---

### 6.5 Offline Queue Architecture

When the device is offline, captured images are queued locally for later processing.

#### Data Model

```dart
// lib/core/models/pending_capture.dart

import 'package:hive/hive.dart';

part 'pending_capture.g.dart';

@HiveType(typeId: 0)
class PendingCapture extends HiveObject {
  @HiveField(0)
  final String localImagePath;
  
  @HiveField(1)
  final String projectId;
  
  @HiveField(2)
  final DateTime capturedAt;
  
  @HiveField(3)
  final String mode; // 'sewing', 'quilting', etc.
  
  @HiveField(4)
  final double? scaleHint; // From reference detection, if available
  
  @HiveField(5)
  int retryCount;
  
  @HiveField(6)
  String? lastError;

  PendingCapture({
    required this.localImagePath,
    required this.projectId,
    required this.capturedAt,
    required this.mode,
    this.scaleHint,
    this.retryCount = 0,
    this.lastError,
  });
}
```

#### Queue Behavior

| Scenario | Behavior |
|----------|----------|
| Capture while offline | Save to Hive queue, show "Saved for later" toast |
| Network restored | `ConnectivityProvider` triggers batch upload |
| Upload succeeds | Remove from queue, update project with result |
| Upload fails | Increment retry count, exponential backoff (max 3 retries) |
| Max retries exceeded | Keep in queue, show in UI as "Needs attention" |

#### ConnectivityProvider Integration

```dart
// lib/core/providers/connectivity_provider.dart

@riverpod
class ConnectivityNotifier extends _$ConnectivityNotifier {
  late StreamSubscription<ConnectivityResult> _subscription;
  
  @override
  ConnectivityState build() {
    _subscription = Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);
    return ConnectivityState.unknown;
  }
  
  void _onConnectivityChanged(ConnectivityResult result) {
    final isOnline = result != ConnectivityResult.none;
    state = isOnline ? ConnectivityState.online : ConnectivityState.offline;
    
    if (isOnline) {
      // Trigger pending upload processing
      ref.read(pendingCaptureQueueProvider.notifier).processQueue();
    }
  }
}
```

---

## 7. External Display Architecture

TraceCast uses **true external display output** (not screen mirroring) to project patterns. This allows the phone to show controls while the projector displays only the clean pattern on a black background.

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        FLUTTER APP                               │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                    PRIMARY DISPLAY                           ││
│  │                    (Phone Screen)                            ││
│  │  ┌─────────────────────────────────────────────────────────┐ ││
│  │  │  Blueprint Blue UI                                      │ ││
│  │  │  ┌──────────┐ ┌──────────┐ ┌──────────┐                │ ││
│  │  │  │  Nudge   │ │  Zoom    │ │  Lock    │                │ ││
│  │  │  │ Controls │ │ Controls │ │  Mode    │                │ ││
│  │  │  └──────────┘ └──────────┘ └──────────┘                │ ││
│  │  │                                                         │ ││
│  │  │  Pattern Preview (Small)                               │ ││
│  │  │  Connection Status                                     │ ││
│  │  └─────────────────────────────────────────────────────────┘ ││
│  └─────────────────────────────────────────────────────────────┘│
│                              │                                   │
│                    Platform Channel                              │
│                              │                                   │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                   EXTERNAL DISPLAY                           ││
│  │                   (Projector)                                ││
│  │  ┌─────────────────────────────────────────────────────────┐ ││
│  │  │  Pure Black Background (#000000)                        │ ││
│  │  │                                                         │ ││
│  │  │            ┌─────────────────┐                          │ ││
│  │  │            │   White Lines   │                          │ ││
│  │  │            │   (Pattern)     │                          │ ││
│  │  │            │                 │                          │ ││
│  │  │            └─────────────────┘                          │ ││
│  │  │                                                         │ ││
│  │  └─────────────────────────────────────────────────────────┘ ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

> [!NOTE]
> **Mirroring Mode Fallback:** If the native external display window fails to create (e.g., incompatible display, window creation error), the app falls back to standard AirPlay/Cast mirroring. This still shows the black-background projector view on the external display—the phone screen content is NOT mirrored. The difference is that the external display becomes a mirror of the Flutter projector view rather than an independent native window. Users will still see the control UI on their phone and the pattern on the projector.

### iOS Implementation (AirPlay External Display)

```swift
// ios/Runner/ExternalDisplayManager.swift

import UIKit
import Flutter

class ExternalDisplayManager: NSObject {
    static let shared = ExternalDisplayManager()
    
    private var externalWindow: UIWindow?
    private var projectorViewController: ProjectorViewController?
    
    private override init() {
        super.init()
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenDidConnect),
            name: UIScreen.didConnectNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenDidDisconnect),
            name: UIScreen.didDisconnectNotification,
            object: nil
        )
    }
    
    @objc private func screenDidConnect(_ notification: Notification) {
        guard let screen = notification.object as? UIScreen else { return }
        setupExternalDisplay(on: screen)
    }
    
    @objc private func screenDidDisconnect(_ notification: Notification) {
        teardownExternalDisplay()
    }
    
    func setupExternalDisplay(on screen: UIScreen) {
        do {
            // Create window for external display
            let window = UIWindow(frame: screen.bounds)
            window.screen = screen
            
            // Create projector view controller
            let projectorVC = ProjectorViewController()
            window.rootViewController = projectorVC
            window.isHidden = false
            
            self.externalWindow = window
            self.projectorViewController = projectorVC
            
            // Notify Flutter that external display is ready
            notifyFlutter(connected: true, screenSize: screen.bounds.size, fallbackToMirroring: false)
        } catch {
            // External display setup failed - fall back to mirroring mode
            print("External display setup failed: \(error.localizedDescription)")
            notifyFlutter(connected: false, screenSize: .zero, fallbackToMirroring: true)
        }
    }
    
    func teardownExternalDisplay() {
        externalWindow?.isHidden = true
        externalWindow = nil
        projectorViewController = nil
        
        notifyFlutter(connected: false, screenSize: .zero)
    }
    
    // Called from Flutter via platform channel
    func updatePattern(paths: [[CGPoint]], lineWidth: CGFloat, lineColor: UIColor) {
        projectorViewController?.updatePattern(paths: paths, lineWidth: lineWidth, lineColor: lineColor)
    }
    
    func nudge(dx: CGFloat, dy: CGFloat) {
        projectorViewController?.nudge(dx: dx, dy: dy)
    }
    
    func setZoom(_ scale: CGFloat) {
        projectorViewController?.setZoom(scale)
    }
    
    private func notifyFlutter(connected: Bool, screenSize: CGSize) {
        // Send event to Flutter via EventChannel
        // Implementation depends on your channel setup
    }
}

// Projector view that renders only the pattern
class ProjectorViewController: UIViewController {
    private let patternLayer = CAShapeLayer()
    private var transform = CGAffineTransform.identity
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.layer.addSublayer(patternLayer)
        patternLayer.strokeColor = UIColor.white.cgColor
        patternLayer.fillColor = nil
        patternLayer.lineWidth = 2.0
    }
    
    func updatePattern(paths: [[CGPoint]], lineWidth: CGFloat, lineColor: UIColor) {
        let combinedPath = UIBezierPath()
        
        for points in paths {
            guard let first = points.first else { continue }
            combinedPath.move(to: first)
            for point in points.dropFirst() {
                combinedPath.addLine(to: point)
            }
        }
        
        patternLayer.path = combinedPath.cgPath
        patternLayer.lineWidth = lineWidth
        patternLayer.strokeColor = lineColor.cgColor
        
        applyTransform()
    }
    
    func nudge(dx: CGFloat, dy: CGFloat) {
        transform = transform.translatedBy(x: dx, y: dy)
        applyTransform()
    }
    
    func setZoom(_ scale: CGFloat) {
        let center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        transform = CGAffineTransform(translationX: center.x, y: center.y)
            .scaledBy(x: scale, y: scale)
            .translatedBy(x: -center.x, y: -center.y)
        applyTransform()
    }
    
    private func applyTransform() {
        patternLayer.setAffineTransform(transform)
    }
}
```

### Android Implementation (Presentation API)

```kotlin
// android/app/src/main/kotlin/com/yourcompany/tracecast/ExternalDisplayManager.kt

import android.content.Context
import android.hardware.display.DisplayManager
import android.view.Display
import android.os.Bundle
import android.app.Presentation
import android.graphics.*

class ExternalDisplayManager(private val context: Context) {
    private var presentation: PatternPresentation? = null
    private val displayManager = context.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
    
    init {
        displayManager.registerDisplayListener(displayListener, null)
        checkForExternalDisplay()
    }
    
    private val displayListener = object : DisplayManager.DisplayListener {
        override fun onDisplayAdded(displayId: Int) {
            checkForExternalDisplay()
        }
        
        override fun onDisplayRemoved(displayId: Int) {
            if (presentation?.display?.displayId == displayId) {
                presentation?.dismiss()
                presentation = null
                notifyFlutter(connected = false)
            }
        }
        
        override fun onDisplayChanged(displayId: Int) {}
    }
    
    private fun checkForExternalDisplay() {
        val displays = displayManager.getDisplays(DisplayManager.DISPLAY_CATEGORY_PRESENTATION)
        if (displays.isNotEmpty() && presentation == null) {
            setupPresentation(displays[0])
        }
    }
    
    private fun setupPresentation(display: Display) {
        try {
            presentation = PatternPresentation(context, display).apply {
                show()
            }
            notifyFlutter(connected = true, width = display.width, height = display.height, fallbackToMirroring = false)
        } catch (e: Exception) {
            // Presentation failed - fall back to mirroring mode
            android.util.Log.e("ExternalDisplay", "Presentation setup failed", e)
            notifyFlutter(connected = false, fallbackToMirroring = true)
        }
    }
    
    fun updatePattern(paths: List<List<PointF>>, lineWidth: Float, lineColor: Int) {
        presentation?.updatePattern(paths, lineWidth, lineColor)
    }
    
    fun nudge(dx: Float, dy: Float) {
        presentation?.nudge(dx, dy)
    }
    
    fun setZoom(scale: Float) {
        presentation?.setZoom(scale)
    }
    
    private fun notifyFlutter(connected: Boolean, width: Int = 0, height: Int = 0) {
        // Send event to Flutter via EventChannel
    }
}

class PatternPresentation(context: Context, display: Display) : Presentation(context, display) {
    private lateinit var patternView: PatternView
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        patternView = PatternView(context)
        setContentView(patternView)
    }
    
    fun updatePattern(paths: List<List<PointF>>, lineWidth: Float, lineColor: Int) {
        patternView.updatePattern(paths, lineWidth, lineColor)
    }
    
    fun nudge(dx: Float, dy: Float) {
        patternView.nudge(dx, dy)
    }
    
    fun setZoom(scale: Float) {
        patternView.setZoom(scale)
    }
}

class PatternView(context: Context) : android.view.View(context) {
    private val paint = Paint().apply {
        style = Paint.Style.STROKE
        isAntiAlias = true
        color = Color.WHITE
        strokeWidth = 2f
    }
    
    private val path = Path()
    private var offsetX = 0f
    private var offsetY = 0f
    private var scale = 1f
    
    init {
        setBackgroundColor(Color.BLACK)
    }
    
    fun updatePattern(paths: List<List<PointF>>, lineWidth: Float, lineColor: Int) {
        path.reset()
        for (points in paths) {
            if (points.isEmpty()) continue
            path.moveTo(points[0].x, points[0].y)
            for (i in 1 until points.size) {
                path.lineTo(points[i].x, points[i].y)
            }
        }
        paint.strokeWidth = lineWidth
        paint.color = lineColor
        invalidate()
    }
    
    fun nudge(dx: Float, dy: Float) {
        offsetX += dx
        offsetY += dy
        invalidate()
    }
    
    fun setZoom(newScale: Float) {
        scale = newScale
        invalidate()
    }
    
    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        canvas.save()
        canvas.translate(width / 2f + offsetX, height / 2f + offsetY)
        canvas.scale(scale, scale)
        canvas.translate(-width / 2f, -height / 2f)
        canvas.drawPath(path, paint)
        canvas.restore()
    }
}
```

### Flutter Platform Channel

```dart
// lib/platform_channels/external_display_channel.dart

import 'dart:async';
import 'package:flutter/services.dart';

class ExternalDisplayChannel {
  static const MethodChannel _methodChannel = 
      MethodChannel('com.tracecast/external_display');
  static const EventChannel _eventChannel = 
      EventChannel('com.tracecast/external_display_events');
  
  Stream<ExternalDisplayState>? _stateStream;
  
  Stream<ExternalDisplayState> get stateStream {
    _stateStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((event) => ExternalDisplayState.fromMap(event));
    return _stateStream!;
  }
  
  Future<bool> isExternalDisplayConnected() async {
    final result = await _methodChannel.invokeMethod<bool>('isConnected');
    return result ?? false;
  }
  
  Future<void> updatePattern({
    required List<List<Offset>> paths,
    required double lineWidth,
    required Color lineColor,
  }) async {
    final pathsData = paths.map((path) => 
      path.map((p) => [p.dx, p.dy]).toList()
    ).toList();
    
    await _methodChannel.invokeMethod('updatePattern', {
      'paths': pathsData,
      'lineWidth': lineWidth,
      'lineColor': lineColor.value,
    });
  }
  
  Future<void> nudge(double dx, double dy) async {
    await _methodChannel.invokeMethod('nudge', {'dx': dx, 'dy': dy});
  }
  
  Future<void> setZoom(double scale) async {
    await _methodChannel.invokeMethod('setZoom', {'scale': scale});
  }
}

class ExternalDisplayState {
  final bool connected;
  final Size? screenSize;
  
  ExternalDisplayState({required this.connected, this.screenSize});
  
  factory ExternalDisplayState.fromMap(Map<dynamic, dynamic> map) {
    return ExternalDisplayState(
      connected: map['connected'] as bool,
      screenSize: map['width'] != null 
          ? Size(map['width'].toDouble(), map['height'].toDouble())
          : null,
    );
  }
}
```

---

## 8. Testing & Validation

### AI Response Test Cases

```typescript
// Test: Successful extraction
const successCase = {
  input: 'pattern_bodice_front.jpg',
  expected: {
    success: true,
    confidence: { min: 75 },
    layers: {
      cutlines: { count: 1, closed: true },
      markings: { minCount: 2 }, // At least dart + grainline
      labels: { minCount: 1 }   // At least piece name
    }
  }
};

// Test: Low confidence (wrinkled/damaged pattern)
const lowConfidenceCase = {
  input: 'pattern_wrinkled_tissue.jpg',
  expected: {
    success: true,
    confidence: { max: 60 },
    warnings: { contains: 'low confidence' }
  }
};

// Test: No pattern detected (blank/wrong image)
const noPatternCase = {
  input: 'photo_of_cat.jpg',
  expected: {
    success: false,
    confidence: { max: 20 },
    warnings: { contains: 'no pattern' }
  }
};

// Test: Multiple overlapping pieces (edge case)
const overlappingCase = {
  input: 'pattern_multiple_pieces.jpg',
  expected: {
    warnings: { contains: 'multiple' }
  }
};
```

### Integration Test Script

```bash
#!/bin/bash
# test_vectorization.sh

# Deploy function to emulator
firebase emulators:start --only functions,storage &
sleep 10

# Run test suite
npm run test:vectorize

# Test cases:
# 1. Valid sewing pattern → expect cutline + markings
# 2. Quilting template → expect geometric shapes
# 3. Low-quality photo → expect warnings
# 4. No pattern → expect failure with NO_PATTERN_DETECTED
# 5. Rate limit → verify fallback chain
# 6. Timeout → verify retry logic

# Cleanup
pkill -f "firebase emulators"
```

---

## 9. Implementation Notes

> **Note**: Development guidelines, build order, known gotchas, and pre-flight checks have been moved to **Section 11 of the PRD** for consolidated developer reference.

---

**— End of Appendix —**

*TraceCast: AI Prompt Engineering Appendix v1.0 | December 2025*
