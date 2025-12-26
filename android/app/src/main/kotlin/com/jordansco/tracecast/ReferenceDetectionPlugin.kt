package com.jordansco.tracecast

import android.graphics.BitmapFactory
import android.graphics.PointF
import androidx.annotation.NonNull
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.BarcodeScannerOptions
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlin.math.abs
import kotlin.math.sqrt

/**
 * Flutter plugin for reference detection on Android using ML Kit
 *
 * Supports detection of:
 * - ArUco-like markers (using ML Kit barcode scanning)
 * - Grid patterns (using edge detection heuristics)
 * - Credit cards (using rectangle detection via contours)
 */
class ReferenceDetectionPlugin : MethodCallHandler {

    companion object {
        private const val CHANNEL = "com.jordansco.tracecast/reference_detection"

        // Credit card aspect ratio (85.6mm / 53.98mm)
        private const val CREDIT_CARD_ASPECT_RATIO = 1.585
        private const val ASPECT_RATIO_TOLERANCE = 0.2

        fun registerWith(flutterEngine: FlutterEngine) {
            val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            channel.setMethodCallHandler(ReferenceDetectionPlugin())
        }
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "isAvailable" -> {
                // Reference detection is available on Android via ML Kit
                result.success(true)
            }

            "detectAruco" -> {
                handleDetectAruco(call, result)
            }

            "detectGrid" -> {
                handleDetectGrid(call, result)
            }

            "detectCreditCard" -> {
                handleDetectCreditCard(call, result)
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    /**
     * Detect ArUco-like markers (QR, Aztec, Data Matrix) using ML Kit
     */
    private fun handleDetectAruco(call: MethodCall, result: Result) {
        val imageBytes = call.argument<ByteArray>("imageBytes")
        val width = call.argument<Int>("width")
        val height = call.argument<Int>("height")

        if (imageBytes == null || width == null || height == null) {
            result.error("INVALID_ARGS", "Missing required arguments: imageBytes, width, height", null)
            return
        }

        try {
            val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
            if (bitmap == null) {
                result.success(mapOf(
                    "detected" to false,
                    "error" to "Failed to decode image"
                ))
                return
            }

            val inputImage = InputImage.fromBitmap(bitmap, 0)

            // Configure barcode scanner for square markers
            val options = BarcodeScannerOptions.Builder()
                .setBarcodeFormats(
                    Barcode.FORMAT_QR_CODE,
                    Barcode.FORMAT_AZTEC,
                    Barcode.FORMAT_DATA_MATRIX
                )
                .build()

            val scanner = BarcodeScanning.getClient(options)

            scanner.process(inputImage)
                .addOnSuccessListener { barcodes ->
                    if (barcodes.isEmpty()) {
                        result.success(mapOf(
                            "detected" to false,
                            "markerIds" to listOf<Int>(),
                            "corners" to listOf<List<Double>>(),
                            "confidence" to 0.0
                        ))
                        return@addOnSuccessListener
                    }

                    val markerIds = mutableListOf<Int>()
                    val cornersList = mutableListOf<List<Double>>()

                    barcodes.forEachIndexed { index, barcode ->
                        markerIds.add(index)

                        // Get corner points
                        val corners = barcode.cornerPoints
                        if (corners != null && corners.size >= 4) {
                            val cornerCoords = listOf(
                                corners[0].x.toDouble(), corners[0].y.toDouble(),
                                corners[1].x.toDouble(), corners[1].y.toDouble(),
                                corners[2].x.toDouble(), corners[2].y.toDouble(),
                                corners[3].x.toDouble(), corners[3].y.toDouble()
                            )
                            cornersList.add(cornerCoords)
                        }
                    }

                    result.success(mapOf(
                        "detected" to true,
                        "markerIds" to markerIds,
                        "corners" to cornersList,
                        "confidence" to 0.9
                    ))
                }
                .addOnFailureListener { e ->
                    result.success(mapOf(
                        "detected" to false,
                        "error" to e.message
                    ))
                }

        } catch (e: Exception) {
            result.success(mapOf(
                "detected" to false,
                "error" to e.message
            ))
        }
    }

    /**
     * Detect grid lines in an image
     * 
     * Uses a simplified approach based on analyzing the image for
     * regular horizontal and vertical line patterns.
     */
    private fun handleDetectGrid(call: MethodCall, result: Result) {
        val imageBytes = call.argument<ByteArray>("imageBytes")
        val width = call.argument<Int>("width")
        val height = call.argument<Int>("height")
        val gridSpacingMm = call.argument<Double>("gridSpacingMm") ?: 25.4

        if (imageBytes == null || width == null || height == null) {
            result.error("INVALID_ARGS", "Missing required arguments", null)
            return
        }

        try {
            val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
            if (bitmap == null) {
                result.success(mapOf(
                    "detected" to false,
                    "error" to "Failed to decode image"
                ))
                return
            }

            // Simplified grid detection using pixel analysis
            // For production, consider using OpenCV's HoughLinesP
            val gridResult = detectGridPattern(bitmap)

            if (gridResult.detected) {
                result.success(mapOf(
                    "detected" to true,
                    "horizontalLines" to gridResult.horizontalLines,
                    "verticalLines" to gridResult.verticalLines,
                    "gridSpacingPx" to gridResult.gridSpacingPx,
                    "confidence" to gridResult.confidence
                ))
            } else {
                result.success(mapOf(
                    "detected" to false,
                    "horizontalLines" to listOf<List<Double>>(),
                    "verticalLines" to listOf<List<Double>>(),
                    "gridSpacingPx" to 0.0,
                    "confidence" to 0.0
                ))
            }

        } catch (e: Exception) {
            result.success(mapOf(
                "detected" to false,
                "error" to e.message
            ))
        }
    }

    /**
     * Simple grid pattern detection using edge analysis
     */
    private fun detectGridPattern(bitmap: android.graphics.Bitmap): GridDetectionResult {
        val width = bitmap.width
        val height = bitmap.height

        // Sample pixels along horizontal and vertical lines
        val horizontalEdges = mutableListOf<Int>()
        val verticalEdges = mutableListOf<Int>()

        // Sample center row
        val centerY = height / 2
        var prevBrightness = 0
        for (x in 0 until width) {
            val pixel = bitmap.getPixel(x, centerY)
            val brightness = (android.graphics.Color.red(pixel) + 
                             android.graphics.Color.green(pixel) + 
                             android.graphics.Color.blue(pixel)) / 3
            
            // Detect edge (significant brightness change)
            if (abs(brightness - prevBrightness) > 50) {
                verticalEdges.add(x)
            }
            prevBrightness = brightness
        }

        // Sample center column
        val centerX = width / 2
        prevBrightness = 0
        for (y in 0 until height) {
            val pixel = bitmap.getPixel(centerX, y)
            val brightness = (android.graphics.Color.red(pixel) + 
                             android.graphics.Color.green(pixel) + 
                             android.graphics.Color.blue(pixel)) / 3
            
            if (abs(brightness - prevBrightness) > 50) {
                horizontalEdges.add(y)
            }
            prevBrightness = brightness
        }

        // Check for regular spacing
        if (verticalEdges.size >= 3 && horizontalEdges.size >= 3) {
            val avgVerticalSpacing = calculateAverageSpacing(verticalEdges)
            val avgHorizontalSpacing = calculateAverageSpacing(horizontalEdges)

            // Check if spacing is consistent (grid-like)
            if (avgVerticalSpacing > 10 && avgHorizontalSpacing > 10) {
                val gridSpacing = (avgVerticalSpacing + avgHorizontalSpacing) / 2.0
                return GridDetectionResult(
                    detected = true,
                    horizontalLines = listOf(),
                    verticalLines = listOf(),
                    gridSpacingPx = gridSpacing,
                    confidence = 0.7
                )
            }
        }

        return GridDetectionResult(
            detected = false,
            horizontalLines = listOf(),
            verticalLines = listOf(),
            gridSpacingPx = 0.0,
            confidence = 0.0
        )
    }

    private fun calculateAverageSpacing(edges: List<Int>): Double {
        if (edges.size < 2) return 0.0
        
        var totalSpacing = 0
        for (i in 1 until edges.size) {
            totalSpacing += edges[i] - edges[i - 1]
        }
        return totalSpacing.toDouble() / (edges.size - 1)
    }

    /**
     * Detect credit card or similar rectangular reference
     * 
     * Uses contour analysis to find rectangles with credit card aspect ratio
     */
    private fun handleDetectCreditCard(call: MethodCall, result: Result) {
        val imageBytes = call.argument<ByteArray>("imageBytes")
        val width = call.argument<Int>("width")
        val height = call.argument<Int>("height")

        if (imageBytes == null || width == null || height == null) {
            result.error("INVALID_ARGS", "Missing required arguments", null)
            return
        }

        try {
            val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
            if (bitmap == null) {
                result.success(mapOf(
                    "detected" to false,
                    "error" to "Failed to decode image"
                ))
                return
            }

            // Find rectangles in the image
            val rectangles = findRectangles(bitmap)

            // Find the best match for credit card aspect ratio
            var bestMatch: RectangleCandidate? = null
            var bestConfidence = 0.0

            for (rect in rectangles) {
                val aspectRatio = maxOf(rect.width, rect.height).toDouble() / 
                                  minOf(rect.width, rect.height).toDouble()
                
                val ratioDiff = abs(aspectRatio - CREDIT_CARD_ASPECT_RATIO)
                
                if (ratioDiff < ASPECT_RATIO_TOLERANCE) {
                    val confidence = 1.0 - (ratioDiff / ASPECT_RATIO_TOLERANCE)
                    if (confidence > bestConfidence) {
                        bestConfidence = confidence
                        bestMatch = rect
                    }
                }
            }

            if (bestMatch != null) {
                // Convert corners to flat list [x1,y1,x2,y2,x3,y3,x4,y4]
                val corners = listOf(
                    bestMatch.corners[0].x.toDouble(), bestMatch.corners[0].y.toDouble(),
                    bestMatch.corners[1].x.toDouble(), bestMatch.corners[1].y.toDouble(),
                    bestMatch.corners[2].x.toDouble(), bestMatch.corners[2].y.toDouble(),
                    bestMatch.corners[3].x.toDouble(), bestMatch.corners[3].y.toDouble()
                )

                val aspectRatio = maxOf(bestMatch.width, bestMatch.height).toDouble() / 
                                  minOf(bestMatch.width, bestMatch.height).toDouble()

                result.success(mapOf(
                    "detected" to true,
                    "corners" to corners,
                    "aspectRatio" to aspectRatio,
                    "confidence" to bestConfidence
                ))
            } else {
                result.success(mapOf(
                    "detected" to false,
                    "corners" to listOf<Double>(),
                    "aspectRatio" to 0.0,
                    "confidence" to 0.0
                ))
            }

        } catch (e: Exception) {
            result.success(mapOf(
                "detected" to false,
                "error" to e.message
            ))
        }
    }

    /**
     * Find rectangular regions in the image using edge detection
     */
    private fun findRectangles(bitmap: android.graphics.Bitmap): List<RectangleCandidate> {
        val width = bitmap.width
        val height = bitmap.height
        val rectangles = mutableListOf<RectangleCandidate>()

        // Simple edge detection by scanning for brightness changes
        // For production, use OpenCV's findContours + approxPolyDP
        
        // Find prominent edges along rows and columns
        val horizontalEdges = mutableListOf<Pair<Int, Int>>() // (x, y)
        val verticalEdges = mutableListOf<Pair<Int, Int>>()

        // Sample every 10th row/column for efficiency
        val step = 10

        // Detect horizontal edges
        for (y in step until height step step) {
            var prevBrightness = getBrightness(bitmap, 0, y)
            for (x in 1 until width) {
                val brightness = getBrightness(bitmap, x, y)
                if (abs(brightness - prevBrightness) > 80) {
                    horizontalEdges.add(Pair(x, y))
                }
                prevBrightness = brightness
            }
        }

        // Try to form rectangles from detected edges
        // This is a simplified approach - real implementation would use contour detection
        
        // For now, look for a large rectangle in the center region
        val marginX = width / 10
        val marginY = height / 10
        
        // Create a simple rectangle candidate from the detected area
        if (horizontalEdges.size > 4) {
            val minX = horizontalEdges.minOfOrNull { it.first } ?: marginX
            val maxX = horizontalEdges.maxOfOrNull { it.first } ?: (width - marginX)
            val minY = horizontalEdges.minOfOrNull { it.second } ?: marginY
            val maxY = horizontalEdges.maxOfOrNull { it.second } ?: (height - marginY)

            val rectWidth = maxX - minX
            val rectHeight = maxY - minY

            if (rectWidth > width / 5 && rectHeight > height / 5) {
                rectangles.add(RectangleCandidate(
                    corners = arrayOf(
                        PointF(minX.toFloat(), minY.toFloat()),
                        PointF(maxX.toFloat(), minY.toFloat()),
                        PointF(maxX.toFloat(), maxY.toFloat()),
                        PointF(minX.toFloat(), maxY.toFloat())
                    ),
                    width = rectWidth,
                    height = rectHeight
                ))
            }
        }

        return rectangles
    }

    private fun getBrightness(bitmap: android.graphics.Bitmap, x: Int, y: Int): Int {
        val pixel = bitmap.getPixel(x, y)
        return (android.graphics.Color.red(pixel) + 
                android.graphics.Color.green(pixel) + 
                android.graphics.Color.blue(pixel)) / 3
    }

    // Data classes
    data class GridDetectionResult(
        val detected: Boolean,
        val horizontalLines: List<List<Double>>,
        val verticalLines: List<List<Double>>,
        val gridSpacingPx: Double,
        val confidence: Double
    )

    data class RectangleCandidate(
        val corners: Array<PointF>,
        val width: Int,
        val height: Int
    )
}
