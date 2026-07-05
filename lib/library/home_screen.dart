import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import '../app_colors.dart';
import '../ai_status.dart';
import 'book.dart';
import 'book_card.dart';
import 'home_widgets.dart';
import 'library_enrichment.dart';
import 'library_repository.dart';

// ---------------------------------------------------------------------------
// HomeScreen
// ---------------------------------------------------------------------------

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Book> _books = [];
  final _repository = const LibraryRepository();
  final _enrichment = LibraryEnrichment();

  bool _isUploading = false;
  bool _isLoadingLibrary = true;

  // Multi-select mode, entered via a book's "…" menu → Select.
  bool _isSelectionMode = false;
  final Set<String> _selectedPaths = {};

  int get _inProgressCount => _books.where((b) => b.isInProgress).length;

  @override
  void initState() {
    super.initState();
    _loadLibrary();
  }

  // ── Load & background enrichment ────────────────────────────────────────

  Future<void> _loadLibrary() async {
    try {
      final list = await _repository.loadLibrary();
      setState(
        () => _books
          ..clear()
          ..addAll(list),
      );

      // Backfill cover/author for any books saved before enrichment
      // existed, or where the initial lookup didn't find a match.
      for (final book in list) {
        if (book.author == null && book.coverUrl == null) {
          _enrichBookMetadata(book.pdfPath, book.title);
        }
      }

      // Check for books that need RAG indexing (e.g. if they were added
      // while RAG was off, or in a previous app version).
      for (final book in list) {
        _enrichment.isIndexed(book).then((indexed) {
          if (!indexed) _enrichment.maybeIndexBook(book);
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingLibrary = false);
    }
  }

  /// Best-effort lookup of author + cover art for [title], applied to the
  /// book at [pdfPath] if it's still in the library once the lookup returns.
  Future<void> _enrichBookMetadata(String pdfPath, String title) async {
    final metadata = await _enrichment.fetchCoverMetadata(title);
    if (metadata == null || !mounted) return;

    final index = _books.indexWhere((b) => b.pdfPath == pdfPath);
    if (index == -1) return;

    setState(() {
      _books[index] = _books[index].copyWith(
        author: metadata.author,
        coverUrl: metadata.coverUrl,
      );
    });
    await _repository.saveLibrary(_books);
  }

  // ── Multi-select & delete ────────────────────────────────────────────────

  void _enterSelectionMode(String pdfPath) {
    setState(() {
      _isSelectionMode = true;
      _selectedPaths
        ..clear()
        ..add(pdfPath);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedPaths.clear();
    });
  }

  void _toggleSelected(String pdfPath) {
    setState(() {
      if (!_selectedPaths.remove(pdfPath)) {
        _selectedPaths.add(pdfPath);
      }
    });
  }

  Future<void> _confirmDeleteSingle(Book book) async {
    final confirmed = await _showDeleteConfirmDialog(count: 1);
    if (confirmed != true) return;
    await _deleteBooks([book]);
  }

  Future<void> _deleteSelectedBooks() async {
    final books = _books
        .where((b) => _selectedPaths.contains(b.pdfPath))
        .toList();
    if (books.isEmpty) return;

    final confirmed = await _showDeleteConfirmDialog(count: books.length);
    if (confirmed != true) return;

    await _deleteBooks(books);
    _exitSelectionMode();
  }

  Future<bool?> _showDeleteConfirmDialog({required int count}) {
    final isSingle = count == 1;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isSingle ? 'Delete book?' : 'Delete $count books?'),
        content: Text(
          isSingle
              ? 'This removes it from your library and deletes the file from this device.'
              : 'This removes them from your library and deletes the files from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBooks(List<Book> books) async {
    final paths = books.map((b) => b.pdfPath).toSet();

    setState(() {
      _books.removeWhere((b) => paths.contains(b.pdfPath));
      _selectedPaths.removeAll(paths);
    });
    await _repository.saveLibrary(_books);

    for (final book in books) {
      await _enrichment.removeFromIndex(book);
      await _repository.deleteBookFile(book);
    }
  }

  // ── Upload ─────────────────────────────────────────────────────────────

  Future<void> _onUploadPressed() async {
    // Prevent double-tap while a pick is in progress.
    if (_isUploading) return;
    setState(() => _isUploading = true);

    try {
      const typeGroup = XTypeGroup(
        label: 'Books',
        extensions: LibraryRepository.allowedBookExtensions,
        // iOS/macOS need UTIs; these cover PDF, EPUB, and plain text.
        // Formats without a public UTI (mobi/azw3/fb2/djvu) will still be
        // filterable via extensions on Android/Windows/Linux.
        uniformTypeIdentifiers: [
          'com.adobe.pdf',
          'org.idpf.epub-container',
          'public.plain-text',
        ],
        mimeTypes: [
          'application/pdf',
          'application/epub+zip',
          'application/x-mobipocket-ebook',
          'application/vnd.amazon.ebook',
          'text/plain',
        ],
      );

      final XFile? picked = await openFile(acceptedTypeGroups: [typeGroup]);
      if (picked == null) return;

      // Prevent duplicates (same filename would collide on disk anyway,
      // but check before copying so we can skip cleanly).
      final prospectiveTitle = p.basenameWithoutExtension(picked.path);
      if (_books.any(
        (b) => p.basenameWithoutExtension(b.pdfPath) == prospectiveTitle,
      )) {
        return;
      }

      final book = await _repository.importBook(picked.path);

      setState(() => _books.add(book));
      await _repository.saveLibrary(_books);

      _enrichBookMetadata(book.pdfPath, book.title);
      _enrichment.maybeIndexBook(book);
    } on UnsupportedBookFormatException catch (e) {
      if (mounted) _showSnackBar(e.toString());
    } catch (e) {
      if (mounted) _showSnackBar('Could not import file: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Inter', color: AppColors.ink),
        ),
        backgroundColor: AppColors.paper,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _isLoadingLibrary
          ? const Center(child: CircularProgressIndicator())
          : (_books.isEmpty ? _buildEmpty() : _buildGrid()),
      bottomNavigationBar: _buildBottomBar(),
      floatingActionButton: _isSelectionMode ? null : _buildFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endContained,
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Glossy.',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontStyle: FontStyle.italic),
          ),
          const Text(
            'MY BOOKS',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 3),
        ],
      ),
      toolbarHeight: 88,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: ValueListenableBuilder<String>(
            valueListenable: aiStatusNotifier,
            builder: (_, status, _) => AiBadge(status: status),
          ),
        ),
      ],
    );
  }

  // ── Grid ───────────────────────────────────────────────────────────────

  Widget _buildGrid() {
    // +1 for the empty upload slot
    final itemCount = _books.length + 1;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.62,
      ),
      itemCount: itemCount,
      itemBuilder: (_, i) {
        if (i < _books.length) {
          final book = _books[i];
          return BookCard(
            book: book,
            isSelectionMode: _isSelectionMode,
            isSelected: _selectedPaths.contains(book.pdfPath),
            onToggleSelected: () => _toggleSelected(book.pdfPath),
            onEnterSelectionMode: () => _enterSelectionMode(book.pdfPath),
            onDelete: () => _confirmDeleteSingle(book),
          );
        }
        return EmptySlot(onTap: _isSelectionMode ? () {} : _onUploadPressed);
      },
    );
  }

  // ── Empty state (no books at all) ───────────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.menu_book_outlined,
            size: 80,
            color: AppColors.muted,
          ),
          const SizedBox(height: 16),
          const Text(
            'No books yet',
            style: TextStyle(fontFamily: 'Inter', color: AppColors.muted),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload a PDF to get started',
            style: TextStyle(fontFamily: 'Inter', color: AppColors.muted),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _onUploadPressed,
            icon: const Icon(Icons.add),
            label: const Text('Upload PDF'),
          ),
        ],
      ),
    );
  }

  // ── Bottom bar ─────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    if (_isSelectionMode) {
      return BottomAppBar(
        color: AppColors.paper,
        elevation: 0,
        child: Row(
          children: [
            TextButton(
              onPressed: _exitSelectionMode,
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
            ),
            const Spacer(),
            Text(
              '${_selectedPaths.length} selected',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
                color: AppColors.ink,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              tooltip: 'Delete selected',
              onPressed: _selectedPaths.isEmpty ? null : _deleteSelectedBooks,
            ),
          ],
        ),
      );
    }

    final total = _books.length;
    final inProgress = _inProgressCount;

    final label = inProgress > 0
        ? '$total ${total == 1 ? 'BOOK' : 'BOOKS'} · $inProgress IN PROGRESS'
        : '$total ${total == 1 ? 'BOOK' : 'BOOKS'}';

    return BottomAppBar(
      color: AppColors.paper,
      elevation: 0,
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }

  // ── FAB ────────────────────────────────────────────────────────────────

  Widget _buildFab() {
    return FloatingActionButton(
      onPressed: _isUploading ? null : _onUploadPressed,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.paper,
      elevation: 2,
      child: _isUploading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.paper,
              ),
            )
          : const Icon(Icons.add),
    );
  }
}
