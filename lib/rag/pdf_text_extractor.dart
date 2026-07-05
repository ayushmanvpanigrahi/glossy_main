import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

class PdfTextExtractor {
  const PdfTextExtractor();

  /// Returns empty string (never throws) if extraction fails — indexing
  /// should never crash the add-book flow.
  Future<String> extractText(String pdfPath) async {
    try {
      final bytes = await File(pdfPath).readAsBytes();
      final document = sf.PdfDocument(inputBytes: bytes);
      final text = sf.PdfTextExtractor(document).extractText();
      document.dispose();
      return text;
    } catch (_) {
      return '';
    }
  }
}