import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

// ---------------------------------------------------------------------------
// PdfTextExtractor
// ---------------------------------------------------------------------------
// IMPORTANT FIX: extraction (parsing the whole PDF + walking every page's
// content stream) is CPU-heavy synchronous work. Even though the old code
// wrapped it in an `async` function, everything still ran on the main
// isolate — which is exactly what freezes the UI thread and triggers
// "app isn't responding" the moment the user taps something while it runs.
//
// `compute()` moves the actual parsing to a background isolate. The main
// isolate stays free to keep rendering frames / responding to taps.
// ---------------------------------------------------------------------------

class PdfTextExtractor {
  const PdfTextExtractor();

  /// Returns empty string (never throws) if extraction fails — indexing
  /// should never crash the add-book flow.
  Future<String> extractText(String pdfPath) async {
    try {
      final bytes = await File(pdfPath).readAsBytes();
      return await compute(_extractAllTextIsolate, bytes);
    } catch (_) {
      return '';
    }
  }

  /// Extracts just one page's text — used by the reader to give the AI
  /// "surrounding page" context without re-parsing the entire book on
  /// every explain request.
  Future<String> extractPageText(String pdfPath, int pageIndex) async {
    try {
      final bytes = await File(pdfPath).readAsBytes();
      return await compute(
        _extractPageTextIsolate,
        _PageExtractArgs(bytes, pageIndex),
      );
    } catch (_) {
      return '';
    }
  }
}

String _extractAllTextIsolate(Uint8List bytes) {
  try {
    final document = sf.PdfDocument(inputBytes: bytes);
    final text = sf.PdfTextExtractor(document).extractText();
    document.dispose();
    return text;
  } catch (_) {
    return '';
  }
}

class _PageExtractArgs {
  const _PageExtractArgs(this.bytes, this.pageIndex);
  final Uint8List bytes;
  final int pageIndex;
}

String _extractPageTextIsolate(_PageExtractArgs args) {
  try {
    final document = sf.PdfDocument(inputBytes: args.bytes);
    if (args.pageIndex < 0 || args.pageIndex >= document.pages.count) {
      document.dispose();
      return '';
    }
    final text = sf.PdfTextExtractor(
      document,
    ).extractText(startPageIndex: args.pageIndex, endPageIndex: args.pageIndex);
    document.dispose();
    return text;
  } catch (_) {
    return '';
  }
}

// ---------------------------------------------------------------------------
// KNOWN LIMITATION — please read before assuming this is "not fixed":
// ---------------------------------------------------------------------------
// Some books (e.g. your "Psychology of Money" screenshot — "yForMyyFQOE...")
// come out garbled even after this fix. That specific pattern is caused by
// the PDF embedding a custom/subset font whose internal glyph codes don't
// map cleanly back to Unicode (missing/broken ToUnicode CMap). This is a
// known limitation of syncfusion_flutter_pdf's extractText() with certain
// subset fonts — it isn't something app-level code can regex its way out of
// without risking silently corrupting *other* books that extract fine.
//
// Two real next steps if you hit this on more books:
//  1. Run `flutter pub upgrade syncfusion_flutter_pdf` — newer releases have
//     periodically improved ToUnicode/CMap handling.
//  2. If a book still garbles, treat it as a "text extraction unavailable"
//     book for RAG/AI purposes (skip indexing, show a badge saying so)
//     rather than feeding garbage into the embedding model — garbled text
//     will actively make RAG answers worse, not just imperfect.
// ---------------------------------------------------------------------------
