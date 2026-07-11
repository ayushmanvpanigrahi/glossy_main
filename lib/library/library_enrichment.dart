import 'dart:collection';
import '../book_cover_service.dart';
import '../settings/settings_service.dart';
import '../rag/rag_models.dart';
import '../rag/rag_service.dart';
import '../rag/embedding_service.dart';
import '../rag/pdf_text_extractor.dart';
import 'book.dart';
import 'indexing_status_service.dart';

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
//
// RAG indexing is serialized through a single in-memory queue rather than
// firing every book's indexing concurrently — one book is processed at a
// time; the rest wait their turn in [_indexingQueue].
//
// This class is also the single place that touches the RAG index for
// "automatic" indexing — there is intentionally no separate indexing
// pipeline elsewhere, to avoid two code paths racing to write the same
// VectorStore rows for the same book.
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

  final IndexingStatusService _statusService = IndexingStatusService.instance;

  // Serialized indexing queue — shared across every LibraryEnrichment
  // instance in the app (there's normally just one, owned by HomeScreen,
  // but static keeps this safe even if that ever changes).
  static final Queue<_IndexJob> _indexingQueue = Queue<_IndexJob>();
  static bool _isProcessingQueue = false;

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

  /// Current indexing status for [book], for UI badges.
  BookIndexStatus statusFor(Book book) => _statusService.statusFor(book.pdfPath);

  /// Enqueues [book] for RAG indexing if the user's indexing-trigger
  /// setting calls for it right now. The actual work happens one book at
  /// a time via [_processQueue] — this method returns immediately after
  /// enqueuing (or no-oping), so callers (including a loop over the
  /// whole library on app start) never block each other or the UI.
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

    // FIX: without this check, every app launch re-queues EVERY book for
    // indexing regardless of whether it was already indexed in a previous
    // session — re-extracting the full PDF and re-embedding every chunk
    // all over again, every single time HomeScreen loads. Besides wasting
    // the embedding API quota (and contributing to 429 rate-limit errors
    // on the chat model too, since both hit the network around the same
    // time), it also silently defeated the whole point of persisting the
    // vector store. Skip straight to "indexed" if VectorStore already has
    // this book's chunks.
    if (await isIndexed(book)) {
      _statusService.setStatus(book.pdfPath, BookIndexStatus.indexed);
      return;
    }

    final embeddingMode = ragSettings.embeddingMode ?? 'api';
    final apiKey = ragSettings.embeddingApiKey;

    if (embeddingMode == 'api' && (apiKey == null || apiKey.isEmpty)) {
      return; // no key configured yet — user hasn't set up RAG
    }

    // Avoid double-queuing the same book (e.g. upload + the load-time
    // backfill loop both calling this in quick succession).
    if (_statusService.statusFor(book.pdfPath) == BookIndexStatus.indexing) {
      return;
    }
    if (_indexingQueue.any((job) => job.book.pdfPath == book.pdfPath)) {
      return;
    }

    _statusService.setStatus(book.pdfPath, BookIndexStatus.notIndexed);
    _indexingQueue.add(
      _IndexJob(book: book, embeddingMode: embeddingMode, apiKey: apiKey),
    );
    _processQueue();
  }

  /// Manually re-index [book], bypassing both the indexing-trigger check
  /// AND the "already indexed" check above — used by the "Index for AI"
  /// action in the book card's menu, where re-indexing on demand is the
  /// whole point. Still goes through the same serialized queue as
  /// automatic indexing.
  Future<void> indexBookNow(Book book) async {
    if (!book.pdfPath.toLowerCase().endsWith('.pdf')) return;

    final ragSettings = await _settingsService.loadRagSettings();
    final embeddingMode = ragSettings.embeddingMode ?? 'api';
    final apiKey = ragSettings.embeddingApiKey;

    if (embeddingMode == 'api' && (apiKey == null || apiKey.isEmpty)) {
      _statusService.setStatus(book.pdfPath, BookIndexStatus.failed);
      return;
    }

    if (_statusService.statusFor(book.pdfPath) == BookIndexStatus.indexing) {
      return;
    }
    _indexingQueue.removeWhere((job) => job.book.pdfPath == book.pdfPath);

    _statusService.setStatus(book.pdfPath, BookIndexStatus.notIndexed);
    _indexingQueue.add(
      _IndexJob(book: book, embeddingMode: embeddingMode, apiKey: apiKey),
    );
    _processQueue();
  }

  /// Drains [_indexingQueue] one job at a time. Safe to call repeatedly —
  /// if a drain is already running, this is a no-op (the running loop
  /// will pick up newly-added jobs itself).
  Future<void> _processQueue() async {
    if (_isProcessingQueue) return;
    _isProcessingQueue = true;

    try {
      while (_indexingQueue.isNotEmpty) {
        final job = _indexingQueue.removeFirst();
        await _runIndexJob(job);
      }
    } finally {
      _isProcessingQueue = false;
    }
  }

  Future<void> _runIndexJob(_IndexJob job) async {
    final pdfPath = job.book.pdfPath;
    _statusService.setStatus(pdfPath, BookIndexStatus.indexing);

    try {
      final embeddingService = job.embeddingMode == 'api'
          ? GeminiEmbeddingService(job.apiKey!)
          : const LocalEmbeddingService();
      final ragService = RagService(embeddingService: embeddingService);

      final text = await _pdfExtractor.extractText(pdfPath);
      if (text.trim().isEmpty) {
        _statusService.setStatus(pdfPath, BookIndexStatus.failed);
        return;
      }

      await ragService.indexBook(pdfPath, text);
      _statusService.setStatus(pdfPath, BookIndexStatus.indexed);
    } catch (_) {
      // Best-effort — indexing failure shouldn't surface as a crash;
      // the status badge + a manual "Index for AI" retry is the recovery
      // path for the user.
      _statusService.setStatus(pdfPath, BookIndexStatus.failed);
    }
  }

  /// Removes [book] from the RAG index. Best-effort — a failure here
  /// shouldn't block the book being removed from the library.
  Future<void> removeFromIndex(Book book) async {
    _indexingQueue.removeWhere((job) => job.book.pdfPath == book.pdfPath);
    _statusService.clearStatus(book.pdfPath);
    try {
      await RagService(
        embeddingService: const LocalEmbeddingService(),
      ).removeBook(book.pdfPath);
    } catch (_) {
      // Non-fatal.
    }
  }
}

class _IndexJob {
  const _IndexJob({
    required this.book,
    required this.embeddingMode,
    required this.apiKey,
  });

  final Book book;
  final String embeddingMode;
  final String? apiKey;
}
