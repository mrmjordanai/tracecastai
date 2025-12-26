import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Paper size options for reference sheet
enum ReferenceSheetPaperSize {
  a4,
  letter,
}

/// Service for generating printable reference sheets with calibration markers.
///
/// These sheets contain known-size markers that can be detected by the app
/// to calculate accurate scale factors for pattern digitization.
class ReferenceSheetService {
  /// Standard reference marker size in mm (based on credit card width)
  static const double markerSizeMm = 85.6;

  /// Ruler tick interval in mm
  static const double rulerIntervalMm = 10.0;

  /// Generate a reference sheet PDF document.
  ///
  /// Returns a [pw.Document] that can be printed or saved.
  Future<pw.Document> generateReferenceSheet({
    ReferenceSheetPaperSize paperSize = ReferenceSheetPaperSize.letter,
  }) async {
    final pdf = pw.Document();

    final pageFormat = paperSize == ReferenceSheetPaperSize.a4
        ? PdfPageFormat.a4
        : PdfPageFormat.letter;

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(20 * PdfPageFormat.mm),
        build: (context) => _buildReferenceSheetContent(context, pageFormat),
      ),
    );

    return pdf;
  }

  /// Print the reference sheet directly.
  Future<bool> printReferenceSheet({
    ReferenceSheetPaperSize paperSize = ReferenceSheetPaperSize.letter,
  }) async {
    final pdf = await generateReferenceSheet(paperSize: paperSize);
    return await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: 'TraceCast Reference Sheet',
    );
  }

  /// Save the reference sheet to bytes.
  Future<Uint8List> saveReferenceSheetBytes({
    ReferenceSheetPaperSize paperSize = ReferenceSheetPaperSize.letter,
  }) async {
    final pdf = await generateReferenceSheet(paperSize: paperSize);
    return pdf.save();
  }

  /// Build the main content of the reference sheet.
  pw.Widget _buildReferenceSheetContent(
    pw.Context context,
    PdfPageFormat pageFormat,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // Header
        _buildHeader(),
        pw.SizedBox(height: 10 * PdfPageFormat.mm),

        // Instructions
        _buildInstructions(),
        pw.SizedBox(height: 15 * PdfPageFormat.mm),

        // Reference markers with ruler
        _buildReferenceArea(),
        pw.SizedBox(height: 15 * PdfPageFormat.mm),

        // Usage tips
        _buildUsageTips(),

        pw.Spacer(),

        // Footer
        _buildFooter(),
      ],
    );
  }

  pw.Widget _buildHeader() {
    return pw.Column(
      children: [
        pw.Text(
          'TraceCast Reference Sheet',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 2 * PdfPageFormat.mm),
        pw.Text(
          'For Accurate Scale Calibration',
          style: const pw.TextStyle(
            fontSize: 14,
            color: PdfColors.grey700,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildInstructions() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'How to use:',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '1. Print this sheet at 100% scale (no scaling/fit to page)',
            style: const pw.TextStyle(fontSize: 11),
          ),
          pw.Text(
            '2. Verify the ruler marks with a physical ruler',
            style: const pw.TextStyle(fontSize: 11),
          ),
          pw.Text(
            '3. Place this sheet next to your pattern when capturing',
            style: const pw.TextStyle(fontSize: 11),
          ),
          pw.Text(
            '4. Ensure all 4 corner markers are visible in the frame',
            style: const pw.TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildReferenceArea() {
    // Reference area size (standard credit card width)
    const areaWidthMm = markerSizeMm;
    const areaHeightMm = markerSizeMm;

    return pw.Container(
      width: areaWidthMm * PdfPageFormat.mm,
      height: areaHeightMm * PdfPageFormat.mm,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 2),
      ),
      child: pw.Stack(
        children: [
          // Corner markers
          _buildCornerMarker(pw.Alignment.topLeft, 0),
          _buildCornerMarker(pw.Alignment.topRight, 1),
          _buildCornerMarker(pw.Alignment.bottomRight, 2),
          _buildCornerMarker(pw.Alignment.bottomLeft, 3),

          // Ruler marks on top edge
          _buildHorizontalRuler(isTop: true),

          // Ruler marks on left edge
          _buildVerticalRuler(isLeft: true),

          // Center dimension label
          pw.Center(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(4),
              color: PdfColors.white,
              child: pw.Text(
                '${markerSizeMm.toInt()} mm',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCornerMarker(pw.Alignment alignment, int markerId) {
    const markerSizeMm = 10.0;

    return pw.Align(
      alignment: alignment,
      child: pw.Container(
        width: markerSizeMm * PdfPageFormat.mm,
        height: markerSizeMm * PdfPageFormat.mm,
        decoration: pw.BoxDecoration(
          color: PdfColors.black,
          border: pw.Border.all(color: PdfColors.black, width: 1),
        ),
        child: pw.Center(
          child: pw.Text(
            '$markerId',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.white,
            ),
          ),
        ),
      ),
    );
  }

  pw.Widget _buildHorizontalRuler({required bool isTop}) {
    const rulerHeightMm = 5.0;
    final ticks = <pw.Widget>[];

    // Generate tick marks every 10mm
    for (var i = 0; i <= markerSizeMm ~/ rulerIntervalMm; i++) {
      final isMajor = i % 5 == 0; // Major tick every 50mm
      final tickHeight = isMajor ? rulerHeightMm : rulerHeightMm * 0.6;

      ticks.add(
        pw.Positioned(
          left: (i * rulerIntervalMm) * PdfPageFormat.mm,
          top: isTop ? 0 : null,
          bottom: isTop ? null : 0,
          child: pw.Container(
            width: 0.5,
            height: tickHeight * PdfPageFormat.mm,
            color: PdfColors.black,
          ),
        ),
      );
    }

    return pw.Positioned(
      left: 10 * PdfPageFormat.mm, // Start after corner marker
      right: 10 * PdfPageFormat.mm,
      top: isTop ? 10 * PdfPageFormat.mm : null,
      bottom: isTop ? null : 10 * PdfPageFormat.mm,
      child: pw.SizedBox(
        height: rulerHeightMm * PdfPageFormat.mm,
        child: pw.Stack(children: ticks),
      ),
    );
  }

  pw.Widget _buildVerticalRuler({required bool isLeft}) {
    const rulerWidthMm = 5.0;
    final ticks = <pw.Widget>[];

    // Generate tick marks every 10mm
    for (var i = 0; i <= markerSizeMm ~/ rulerIntervalMm; i++) {
      final isMajor = i % 5 == 0;
      final tickWidth = isMajor ? rulerWidthMm : rulerWidthMm * 0.6;

      ticks.add(
        pw.Positioned(
          top: (i * rulerIntervalMm) * PdfPageFormat.mm,
          left: isLeft ? 0 : null,
          right: isLeft ? null : 0,
          child: pw.Container(
            width: tickWidth * PdfPageFormat.mm,
            height: 0.5,
            color: PdfColors.black,
          ),
        ),
      );
    }

    return pw.Positioned(
      top: 10 * PdfPageFormat.mm, // Start after corner marker
      bottom: 10 * PdfPageFormat.mm,
      left: isLeft ? 10 * PdfPageFormat.mm : null,
      right: isLeft ? null : 10 * PdfPageFormat.mm,
      child: pw.SizedBox(
        width: rulerWidthMm * PdfPageFormat.mm,
        child: pw.Stack(children: ticks),
      ),
    );
  }

  pw.Widget _buildUsageTips() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Tips for best results:',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '• Use good lighting to ensure markers are clearly visible',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.Text(
            '• Keep the reference sheet flat and parallel to the camera',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.Text(
            '• Avoid shadows falling across the markers',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.Text(
            '• The app will automatically detect the markers and calculate scale',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'TraceCast',
          style: const pw.TextStyle(
            fontSize: 8,
            color: PdfColors.grey500,
          ),
        ),
        pw.Text(
          'Print at 100% scale for accurate calibration',
          style: const pw.TextStyle(
            fontSize: 8,
            color: PdfColors.grey500,
          ),
        ),
      ],
    );
  }
}
