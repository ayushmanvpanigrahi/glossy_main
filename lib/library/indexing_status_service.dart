import 'package:flutter/foundation.dart';
import '../rag/rag_models.dart';

// ---------------------------------------------------------------------------
// IndexingStatusService
// ---------------------------------------------------------------------------
// Tracks the live RAG-indexing status of each book, keyed by pdfPath, so
// the library UI can show a badge ("Indexing…", "Indexed", "Failed") and
// react to changes without polling. A single app-wide instance is used
// (via the static [instance] getter) since indexing status is inherently
// global state, not tied to any one screen's lifecycle.
// ---------------------------------------------------------------------------

class IndexingStatusService {
  IndexingStatusService._();
  static final IndexingStatusService instance = IndexingStatusService._();

  final ValueNotifier<Map<String, BookIndexStatus>> _statusNotifier =
      ValueNotifier(const {});

  /// Listenable map of pdfPath -> current status. UI can wrap this in a
  /// ValueListenableBuilder to react to any book's status changing.
  ValueListenable<Map<String, BookIndexStatus>> get statusNotifier =>
      _statusNotifier;

  BookIndexStatus statusFor(String pdfPath) =>
      _statusNotifier.value[pdfPath] ?? BookIndexStatus.notIndexed;

  void setStatus(String pdfPath, BookIndexStatus status) {
    _statusNotifier.value = {..._statusNotifier.value, pdfPath: status};
  }

  void clearStatus(String pdfPath) {
    final next = Map<String, BookIndexStatus>.from(_statusNotifier.value)
      ..remove(pdfPath);
    _statusNotifier.value = next;
  }
}
