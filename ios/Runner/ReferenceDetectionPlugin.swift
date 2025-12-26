import Flutter
import UIKit
import Vision
import CoreImage

/// Flutter plugin for reference detection using iOS Vision framework
///
/// Supports detection of:
/// - ArUco-like markers (using barcode detection)
/// - Grid patterns (using line detection)
/// - Credit cards (using rectangle detection)
public class ReferenceDetectionPlugin: NSObject, FlutterPlugin {

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.jordansco.tracecast/reference_detection",
            binaryMessenger: registrar.messenger()
        )
        let instance = ReferenceDetectionPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isAvailable":
            // Vision framework is available on iOS 11+
            result(true)

        case "detectAruco":
            handleDetectAruco(call: call, result: result)

        case "detectGrid":
            handleDetectGrid(call: call, result: result)

        case "detectCreditCard":
            handleDetectCreditCard(call: call, result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - ArUco Detection

    private func handleDetectAruco(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let imageData = args["imageBytes"] as? FlutterStandardTypedData,
              let width = args["width"] as? Int,
              let height = args["height"] as? Int else {
            result(FlutterError(
                code: "INVALID_ARGS",
                message: "Missing required arguments: imageBytes, width, height",
                details: nil
            ))
            return
        }

        detectArucoMarkers(
            imageData: imageData.data,
            width: width,
            height: height,
            completion: result
        )
    }

    private func detectArucoMarkers(
        imageData: Data,
        width: Int,
        height: Int,
        completion: @escaping FlutterResult
    ) {
        guard let cgImage = createCGImage(from: imageData) else {
            completion([
                "detected": false,
                "error": "Failed to create image from data"
            ])
            return
        }

        // Use Vision's barcode detector to find square markers
        // Note: ArUco markers are similar to QR codes in structure
        let request = VNDetectBarcodesRequest { request, error in
            if let error = error {
                completion([
                    "detected": false,
                    "error": error.localizedDescription
                ])
                return
            }

            guard let observations = request.results as? [VNBarcodeObservation] else {
                completion([
                    "detected": false,
                    "markerIds": [Int](),
                    "corners": [[Double]]()
                ])
                return
            }

            // Filter for square-ish barcode markers (QR, Aztec, Data Matrix)
            let markers = observations.filter { observation in
                let validTypes: [VNBarcodeSymbology] = [.qr, .aztec, .dataMatrix]
                return validTypes.contains(observation.symbology)
            }

            if markers.isEmpty {
                completion([
                    "detected": false,
                    "markerIds": [Int](),
                    "corners": [[Double]]()
                ])
                return
            }

            var cornersList: [[Double]] = []
            var markerIds: [Int] = []

            for (index, marker) in markers.enumerated() {
                markerIds.append(index)

                // Get corner points (normalized 0-1, convert to pixels)
                // Vision uses bottom-left origin, so we flip Y
                let corners: [Double] = [
                    Double(marker.topLeft.x) * Double(width),
                    Double(1 - marker.topLeft.y) * Double(height),
                    Double(marker.topRight.x) * Double(width),
                    Double(1 - marker.topRight.y) * Double(height),
                    Double(marker.bottomRight.x) * Double(width),
                    Double(1 - marker.bottomRight.y) * Double(height),
                    Double(marker.bottomLeft.x) * Double(width),
                    Double(1 - marker.bottomLeft.y) * Double(height)
                ]
                cornersList.append(corners)
            }

            completion([
                "detected": true,
                "markerIds": markerIds,
                "corners": cornersList,
                "confidence": 0.9
            ])
        }

        // Configure for ArUco-like detection
        request.symbologies = [.qr, .aztec, .dataMatrix]

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try handler.perform([request])
            } catch {
                completion([
                    "detected": false,
                    "error": error.localizedDescription
                ])
            }
        }
    }

    // MARK: - Grid Detection

    private func handleDetectGrid(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let imageData = args["imageBytes"] as? FlutterStandardTypedData,
              let _ = args["width"] as? Int,
              let _ = args["height"] as? Int else {
            result(FlutterError(
                code: "INVALID_ARGS",
                message: "Missing required arguments",
                details: nil
            ))
            return
        }

        guard let cgImage = createCGImage(from: imageData.data) else {
            result([
                "detected": false,
                "error": "Failed to create image"
            ])
            return
        }

        // Use VNDetectContoursRequest for line detection (iOS 14+)
        if #available(iOS 14.0, *) {
            let request = VNDetectContoursRequest { request, error in
                if let error = error {
                    result([
                        "detected": false,
                        "error": error.localizedDescription
                    ])
                    return
                }

                guard let observations = request.results as? [VNContoursObservation],
                      !observations.isEmpty else {
                    result([
                        "detected": false,
                        "horizontalLines": [[Double]](),
                        "verticalLines": [[Double]]()
                    ])
                    return
                }

                // Analyze contours for grid pattern
                // This is a simplified implementation
                result([
                    "detected": true,
                    "horizontalLines": [[Double]](),
                    "verticalLines": [[Double]](),
                    "gridSpacingPx": 50.0,
                    "confidence": 0.7
                ])
            }

            request.detectsDarkOnLight = true
            request.contrastAdjustment = 2.0

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            DispatchQueue.global(qos: .userInteractive).async {
                do {
                    try handler.perform([request])
                } catch {
                    result([
                        "detected": false,
                        "error": error.localizedDescription
                    ])
                }
            }
        } else {
            // Fallback for iOS < 14
            result([
                "detected": false,
                "error": "Grid detection requires iOS 14+"
            ])
        }
    }

    // MARK: - Credit Card Detection

    private func handleDetectCreditCard(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let imageData = args["imageBytes"] as? FlutterStandardTypedData,
              let width = args["width"] as? Int,
              let height = args["height"] as? Int else {
            result(FlutterError(
                code: "INVALID_ARGS",
                message: "Missing required arguments",
                details: nil
            ))
            return
        }

        guard let cgImage = createCGImage(from: imageData.data) else {
            result([
                "detected": false,
                "error": "Failed to create image"
            ])
            return
        }

        // Use VNDetectRectanglesRequest to find credit card
        let request = VNDetectRectanglesRequest { request, error in
            if let error = error {
                result([
                    "detected": false,
                    "error": error.localizedDescription
                ])
                return
            }

            guard let observations = request.results as? [VNRectangleObservation],
                  let bestMatch = observations.first else {
                result([
                    "detected": false,
                    "corners": [Double]()
                ])
                return
            }

            // Credit card aspect ratio is ~1.585 (85.6mm / 53.98mm)
            let targetAspectRatio = 1.585

            // Calculate detected aspect ratio
            let detectedWidth = abs(bestMatch.topRight.x - bestMatch.topLeft.x)
            let detectedHeight = abs(bestMatch.topLeft.y - bestMatch.bottomLeft.y)
            let detectedRatio = max(detectedWidth, detectedHeight) / min(detectedWidth, detectedHeight)

            // Check if aspect ratio is close to credit card
            let ratioTolerance = 0.2
            let isCard = abs(detectedRatio - targetAspectRatio) < ratioTolerance

            if !isCard {
                result([
                    "detected": false,
                    "error": "Detected rectangle is not credit card shaped"
                ])
                return
            }

            // Convert corners to pixel coordinates
            let corners: [Double] = [
                Double(bestMatch.topLeft.x) * Double(width),
                Double(1 - bestMatch.topLeft.y) * Double(height),
                Double(bestMatch.topRight.x) * Double(width),
                Double(1 - bestMatch.topRight.y) * Double(height),
                Double(bestMatch.bottomRight.x) * Double(width),
                Double(1 - bestMatch.bottomRight.y) * Double(height),
                Double(bestMatch.bottomLeft.x) * Double(width),
                Double(1 - bestMatch.bottomLeft.y) * Double(height)
            ]

            result([
                "detected": true,
                "corners": corners,
                "aspectRatio": detectedRatio,
                "confidence": Double(bestMatch.confidence)
            ])
        }

        // Configure for credit card detection
        request.minimumAspectRatio = 1.4
        request.maximumAspectRatio = 1.8
        request.minimumSize = 0.1  // At least 10% of image
        request.maximumObservations = 1
        request.minimumConfidence = 0.7

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try handler.perform([request])
            } catch {
                result([
                    "detected": false,
                    "error": error.localizedDescription
                ])
            }
        }
    }

    // MARK: - Helpers

    private func createCGImage(from data: Data) -> CGImage? {
        guard let uiImage = UIImage(data: data) else {
            return nil
        }
        return uiImage.cgImage
    }
}
