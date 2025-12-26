"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.vectorize = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const uuid_1 = require("uuid");
const sharp_1 = __importDefault(require("sharp"));
var VectorizeErrorCode;
(function (VectorizeErrorCode) {
    VectorizeErrorCode["AI_UNAVAILABLE"] = "AI_UNAVAILABLE";
})(VectorizeErrorCode || (VectorizeErrorCode = {}));
// ============================================================================
// Image Optimization
// ============================================================================
// Target image dimensions for optimal AI processing (balance quality vs speed)
const MAX_IMAGE_DIMENSION = 1536; // pixels - larger than 1024 for detail, smaller than 2048 for speed
const TARGET_QUALITY = 85; // JPEG quality - good balance of size and quality
/**
 * Downscale image if needed for faster processing
 * Returns base64 encoded JPEG and actual dimensions
 */
async function optimizeImageForAI(imageBuffer) {
    const metadata = await (0, sharp_1.default)(imageBuffer).metadata();
    if (!metadata.width || !metadata.height) {
        throw new Error("Could not determine image dimensions");
    }
    let { width, height } = metadata;
    let needsResize = false;
    // Check if image needs downscaling
    if (width > MAX_IMAGE_DIMENSION || height > MAX_IMAGE_DIMENSION) {
        needsResize = true;
        const scale = MAX_IMAGE_DIMENSION / Math.max(width, height);
        width = Math.round(width * scale);
        height = Math.round(height * scale);
    }
    let processedBuffer;
    if (needsResize) {
        // Downscale and re-encode as JPEG
        processedBuffer = await (0, sharp_1.default)(imageBuffer)
            .resize(width, height, {
            fit: 'inside',
            withoutEnlargement: true,
        })
            .jpeg({ quality: TARGET_QUALITY })
            .toBuffer();
    }
    else if (metadata.format !== 'jpeg') {
        // Only re-encode if not already JPEG
        processedBuffer = await (0, sharp_1.default)(imageBuffer)
            .jpeg({ quality: TARGET_QUALITY })
            .toBuffer();
    }
    else {
        processedBuffer = imageBuffer;
    }
    const sizeKB = Math.round(processedBuffer.length / 1024);
    const origDims = `${metadata.width}x${metadata.height}`;
    const newDims = `${width}x${height}`;
    console.log(`Image optimized: ${origDims} → ${newDims} (${sizeKB}KB)`);
    return {
        base64: processedBuffer.toString("base64"),
        width,
        height,
    };
}
// ============================================================================
// Prompts
// ============================================================================
const SYSTEM_PROMPT = `You are a specialized pattern vectorization AI for TraceCast, an app that digitizes sewing patterns, quilting templates, and craft stencils for projector use.

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
You must respond with ONLY valid JSON matching the schema provided. No markdown, no explanation, no preamble. Just the JSON object.`;
function getUserPrompt(width, height, mode) {
    return `Analyze this pattern photograph and extract vector data.

IMAGE DIMENSIONS: ${width}px × ${height}px
PATTERN MODE: ${mode}

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
        "confidence": number (0-100)
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
}`;
}
const MODEL_CHAIN = [
    // Optimized for speed - Gemini Flash is fastest for vision tasks
    { id: "google/gemini-2.0-flash-exp", timeout_ms: 20000 },
    { id: "google/gemini-1.5-flash", timeout_ms: 20000 },
    // Fallbacks with longer timeout
    { id: "anthropic/claude-3-5-haiku-20241022", timeout_ms: 25000 }, // Faster than Sonnet
    { id: "openai/gpt-4o-mini", timeout_ms: 25000 }, // Faster than GPT-4o
];
// Reduced retry delays for faster overall latency
const RETRY_DELAYS_MS = [500, 1000, 2000];
async function callOpenRouter(modelId, imageBase64, width, height, mode, timeoutMs) {
    var _a, _b, _c, _d;
    const apiKey = ((_a = functions.config().openrouter) === null || _a === void 0 ? void 0 : _a.api_key) || process.env.OPENROUTER_API_KEY;
    if (!apiKey) {
        throw new Error("OPENROUTER_API_KEY not configured");
    }
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), timeoutMs);
    try {
        const response = await fetch("https://openrouter.ai/api/v1/chat/completions", {
            method: "POST",
            headers: {
                "Authorization": `Bearer ${apiKey}`,
                "Content-Type": "application/json",
                "HTTP-Referer": "https://tracecast.app",
                "X-Title": "TraceCast",
            },
            body: JSON.stringify({
                model: modelId,
                max_tokens: 4096,
                temperature: 0.1,
                response_format: { type: "json_object" },
                messages: [
                    { role: "system", content: SYSTEM_PROMPT },
                    {
                        role: "user",
                        content: [
                            { type: "text", text: getUserPrompt(width, height, mode) },
                            {
                                type: "image_url",
                                image_url: {
                                    url: `data:image/jpeg;base64,${imageBase64}`,
                                    detail: "high",
                                },
                            },
                        ],
                    },
                ],
            }),
            signal: controller.signal,
        });
        clearTimeout(timeoutId);
        if (!response.ok) {
            const errorText = await response.text();
            throw new Error(`OpenRouter API error: ${response.status} - ${errorText}`);
        }
        const data = await response.json();
        const content = (_d = (_c = (_b = data.choices) === null || _b === void 0 ? void 0 : _b[0]) === null || _c === void 0 ? void 0 : _c.message) === null || _d === void 0 ? void 0 : _d.content;
        if (!content) {
            throw new Error("No content in OpenRouter response");
        }
        const parsed = JSON.parse(content);
        return validateAIResponse(parsed);
    }
    catch (error) {
        clearTimeout(timeoutId);
        throw error;
    }
}
function validateAIResponse(response) {
    if (typeof response !== "object" || response === null) {
        throw new Error("Response is not an object");
    }
    const r = response;
    if (typeof r.success !== "boolean") {
        throw new Error("Missing or invalid 'success' field");
    }
    if (typeof r.confidence !== "number" || r.confidence < 0 || r.confidence > 100) {
        throw new Error("Missing or invalid 'confidence' field");
    }
    if (!r.layers || typeof r.layers !== "object") {
        throw new Error("Missing 'layers' object");
    }
    const layers = r.layers;
    if (!Array.isArray(layers.cutlines)) {
        throw new Error("Missing 'layers.cutlines' array");
    }
    if (!Array.isArray(layers.markings)) {
        throw new Error("Missing 'layers.markings' array");
    }
    if (!Array.isArray(layers.labels)) {
        throw new Error("Missing 'layers.labels' array");
    }
    return response;
}
async function sleep(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
}
async function vectorizeWithRetry(imageBase64, width, height, mode) {
    const errors = [];
    for (const model of MODEL_CHAIN) {
        for (let attempt = 0; attempt <= RETRY_DELAYS_MS.length; attempt++) {
            try {
                const result = await callOpenRouter(model.id, imageBase64, width, height, mode, model.timeout_ms);
                if (result.confidence < 20) {
                    throw new Error(`Confidence too low: ${result.confidence}`);
                }
                return result;
            }
            catch (error) {
                const errorMessage = error instanceof Error ? error.message : String(error);
                errors.push({ model: model.id, error: errorMessage });
                if (errorMessage.includes("Missing") || errorMessage.includes("invalid")) {
                    break;
                }
                if (attempt < RETRY_DELAYS_MS.length) {
                    await sleep(RETRY_DELAYS_MS[attempt]);
                }
            }
        }
    }
    throw {
        code: VectorizeErrorCode.AI_UNAVAILABLE,
        message: "All AI models failed",
        userMessage: "Couldn't analyze pattern — please try again",
        details: { errors },
    };
}
// ============================================================================
// Transform
// ============================================================================
function transformToClientFormat(aiResponse, request) {
    const { scale_mm_per_px, image_id } = request;
    const pieceId = (0, uuid_1.v4)();
    const transformPath = (aiPath) => ({
        path_id: aiPath.id,
        path_type: aiPath.path_type,
        closed: aiPath.closed,
        points: aiPath.points.map(([x, y]) => ({
            x_mm: x * scale_mm_per_px,
            y_mm: y * scale_mm_per_px,
        })),
        stroke_hint_mm: 0.5,
        confidence: aiPath.confidence / 100,
    });
    const transformLabel = (aiLabel) => ({
        label_id: aiLabel.id,
        text: aiLabel.text,
        position: {
            x_mm: aiLabel.bounding_box.x * scale_mm_per_px,
            y_mm: aiLabel.bounding_box.y * scale_mm_per_px,
        },
        size: {
            width_mm: aiLabel.bounding_box.width * scale_mm_per_px,
            height_mm: aiLabel.bounding_box.height * scale_mm_per_px,
        },
        confidence: aiLabel.confidence / 100,
    });
    return {
        piece_id: pieceId,
        source_image_id: image_id,
        scale_mm_per_px: scale_mm_per_px,
        width_mm: aiResponse.image_dimensions.width * scale_mm_per_px,
        height_mm: aiResponse.image_dimensions.height * scale_mm_per_px,
        layers: {
            cutline: aiResponse.layers.cutlines.map(transformPath),
            markings: aiResponse.layers.markings.map(transformPath),
            labels: aiResponse.layers.labels.map(transformLabel),
        },
        qa: {
            confidence: aiResponse.confidence / 100,
            warnings: aiResponse.warnings || [],
        },
    };
}
// ============================================================================
// Cloud Function (Firebase Functions Gen 1)
// ============================================================================
exports.vectorize = functions
    .region("us-east1")
    .runWith({
    timeoutSeconds: 120,
    memory: "512MB",
})
    .https.onCall(async (data, context) => {
    // 1. Auth check
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Must be logged in to vectorize patterns");
    }
    const userId = context.auth.uid;
    // 2. Validate request
    if (!data.project_id || !data.image_id || !data.mode) {
        throw new functions.https.HttpsError("invalid-argument", "Missing required fields: project_id, image_id, mode");
    }
    if (!data.scale_mm_per_px || data.scale_mm_per_px <= 0) {
        throw new functions.https.HttpsError("invalid-argument", "Invalid or missing scale_mm_per_px");
    }
    try {
        const startTime = Date.now();
        // 3. Fetch image from Storage
        const bucket = admin.storage().bucket();
        const imagePath = `users/${userId}/uploads/${data.image_id}.jpg`;
        const [exists] = await bucket.file(imagePath).exists();
        if (!exists) {
            throw new functions.https.HttpsError("not-found", `Image not found: ${imagePath}`);
        }
        const [imageBuffer] = await bucket.file(imagePath).download();
        const fetchTime = Date.now() - startTime;
        console.log(`Image fetch: ${fetchTime}ms`);
        // 4. Optimize image for AI (downscale if needed)
        const optimizedImage = await optimizeImageForAI(imageBuffer);
        const optimizeTime = Date.now() - startTime - fetchTime;
        console.log(`Image optimization: ${optimizeTime}ms`);
        // 5. Call AI with retry logic
        const aiStartTime = Date.now();
        const aiResponse = await vectorizeWithRetry(optimizedImage.base64, optimizedImage.width, optimizedImage.height, data.mode);
        const aiTime = Date.now() - aiStartTime;
        console.log(`AI processing: ${aiTime}ms`);
        // Log total time for monitoring
        const totalTime = Date.now() - startTime;
        console.log(`Total vectorize time: ${totalTime}ms (target: ≤20000ms)`);
        // 6. Transform to client format
        const result = transformToClientFormat(aiResponse, data);
        // 7. Store result in Firestore
        const pieceRef = admin
            .firestore()
            .collection("users")
            .doc(userId)
            .collection("projects")
            .doc(data.project_id)
            .collection("pieces")
            .doc(result.piece_id);
        await pieceRef.set(Object.assign(Object.assign({}, result), { created_at: admin.firestore.FieldValue.serverTimestamp(), updated_at: admin.firestore.FieldValue.serverTimestamp() }));
        return result;
    }
    catch (error) {
        if (typeof error === "object" && error !== null && "code" in error) {
            const structuredError = error;
            throw new functions.https.HttpsError("unavailable", structuredError.userMessage, { code: structuredError.code, details: structuredError.details });
        }
        const message = error instanceof Error ? error.message : String(error);
        console.error("Vectorize error:", message);
        throw new functions.https.HttpsError("internal", "Failed to process pattern", { error: message });
    }
});
//# sourceMappingURL=vectorize.js.map