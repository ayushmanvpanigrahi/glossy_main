import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

class PdfTextExtractor {
  const PdfTextExtractor();

  /// Returns empty string (never throws) if extraction fails — indexing
  /// should never crash the add-book flow.
  ///
  /// Runs the actual parse + text extraction in a background isolate via
  /// [compute], since Syncfusion's synchronous parsing of a large PDF on
  /// the main isolate can block the UI thread long enough to trigger an
  /// ANR — especially when multiple books are being extracted around the
  /// same time as the user is interacting with the app.
  Future<String> extractText(String pdfPath) async {
    try {
      final bytes = await File(pdfPath).readAsBytes();
      return await compute(_extractTextInIsolate, bytes);
    } catch (_) {
      return '';
    }
  }
}

/// Top-level function required by [compute] — must not be a method or
/// closure, since it's spawned in a separate isolate with no access to
/// the calling isolate's memory (only the passed-in [bytes]).
String _extractTextInIsolate(Uint8List bytes) {
  try {
    final document = sf.PdfDocument(inputBytes: bytes);
    final text = sf.PdfTextExtractor(document).extractText();
    document.dispose();
    return text;
  } catch (_) {
    return '';
  }
}
