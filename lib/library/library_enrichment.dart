import '../book_cover_service.dart';
import '../settings/settings_service.dart';
import '../rag/rag_service.dart';
import '../rag/embedding_service.dart';
import '../rag/pdf_text_extractor.dart';
import 'book.dart';

// ---------------------------------------------------------------------------
// LibraryEnrichment
// ---------------------------------------------------------------------------
// Owns the two background side-effects that run after a book is added (or
// on library load, for books that haven't had them run yet):
//   1. Cover/author lookup via BookCoverService
//   2. RAG indexing via RagService, gated by the user's indexing-trigger
//      setting
//
// Both are best-effort: a failure here should never block adding a book
// or crash the library screen, so every method swallows its own errors.
// ---------------------------------------------------------------------------

class LibraryEnrichment {
  LibraryEnrichment({
    BookCoverService? coverService,
    SettingsService? settingsService,
    PdfTextExtractor? pdfExtractor,
  }) : _coverService = coverService ?? const BookCoverService(),
       _settingsService = settingsService ?? SettingsService(),
       _pdfExtractor = pdfExtractor ?? const PdfTextExtractor();

  final BookCoverService _coverService;
  final SettingsService _settingsService;
  final PdfTextExtractor _pdfExtractor;

  /// Looks up author + cover art for [title]. Returns null if no match
  /// was found or the lookup failed — caller decides what to do (usually
  /// nothing, leaving the book with its placeholder cover).
  Future<BookMetadata?> fetchCoverMetadata(String title) async {
    final metadata = await _coverService.fetchMetadata(title);
    return metadata.isEmpty ? null : metadata;
  }

  /// Whether [book] is already indexed for RAG.
  Future<bool> isIndexed(Book book) async {
    return RagService(
      embeddingService: const LocalEmbeddingService(),
    ).isIndexed(book.pdfPath);
  }

  /// Indexes [book] for RAG if the user's indexing-trigger setting calls
  /// for it right now. Silently no-ops on unsupported formats, missing
  /// API key, or extraction failure.
  Future<void> maybeIndexBook(Book book) async {
    final ragSettings = await _settingsService.loadRagSettings();
    final trigger = ragSettings.indexingTrigger ?? 'onAdd';

    // Only "onAdd" indexes right here. "lazy" indexes on first RAG query
    // (wire into the chat/ask screen when it queries a book with no
    // index yet). "background" needs a real scheduler (e.g. workmanager
    // package) — TODO once that dependency is added; for now it behaves
    // like "lazy" rather than blocking silently.
    if (trigger != 'onAdd') return;

    if (!book.pdfPath.toLowerCase().endsWith('.pdf')) {
      return; // text extraction only supports PDF right now
    }

    final embeddingMode = ragSettings.embeddingMode ?? 'api';
    final apiKey = ragSettings.embeddingApiKey;

    if (embeddingMode == 'api' && (apiKey == null || apiKey.isEmpty)) {
      return; // no key configured yet — user hasn't set up RAG
    }

    try {
      final embeddingService = embeddingMode == 'api'
          ? GeminiEmbeddingService(apiKey!)
          : const LocalEmbeddingService();
      final ragService = RagService(embeddingService: embeddingService);

      final text = await _pdfExtractor.extractText(book.pdfPath);
      if (text.trim().isEmpty) return;

      await ragService.indexBook(book.pdfPath, text);
    } catch (_) {
      // Best-effort — indexing failure shouldn't surface to the user
      // here; the settings screen can offer a manual "re-index" retry.
    }
  }

  /// Removes [book] from the RAG index. Best-effort — a failure here
  /// shouldn't block the book being removed from the library.
  Future<void> removeFromIndex(Book book) async {
    try {
      await RagService(
        embeddingService: const LocalEmbeddingService(),
      ).removeBook(book.pdfPath);
    } catch (_) {
      // Non-fatal.
    }
  }
}
