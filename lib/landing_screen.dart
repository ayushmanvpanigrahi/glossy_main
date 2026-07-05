import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'app_colors.dart';
import 'ai_status.dart';

// ---------------------------------------------------------------------------
// Book model
// ---------------------------------------------------------------------------

class Book {
  const Book({
    required this.title,
    required this.pdfPath,
    this.progress = 0.0,
  });

  final String title;
  final String pdfPath; // absolute path to the copied PDF on device
  final double progress;

  bool get isInProgress => progress > 0.0 && progress < 1.0;

  /// Uppercase file extension for display, e.g. "PDF", "EPUB".
  /// Falls back to "FILE" if the path has no extension for some reason.
  String get fileTypeLabel {
    final ext = p.extension(pdfPath).replaceFirst('.', '');
    return ext.isEmpty ? 'FILE' : ext.toUpperCase();
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'pdfPath': pdfPath,
    'progress': progress,
  };

  factory Book.fromJson(Map<String, dynamic> json) => Book(
    title: json['title'] as String,
    pdfPath: json['pdfPath'] as String,
    progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
  );
}

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
  bool _isUploading = false;
  bool _isLoadingLibrary = true;

  // Selection mode — keyed by Book.pdfPath since it's unique per book.
  bool _isSelectionMode = false;
  final Set<String> _selectedPaths = {};

  int get _inProgressCount => _books.where((b) => b.isInProgress).length;

  @override
  void initState() {
    super.initState();
    _loadLibrary();
  }

  // ── Persistence ────────────────────────────────────────────────────────

  Future<File> get _libraryIndexFile async {
    final docsDir = await getApplicationDocumentsDirectory();
    return File(p.join(docsDir.path, 'books', 'library_index.json'));
  }

  Future<void> _loadLibrary() async {
    try {
      final file = await _libraryIndexFile;
      if (await file.exists()) {
        final raw = await file.readAsString();
        final list = (jsonDecode(raw) as List)
            .cast<Map<String, dynamic>>()
            .map(Book.fromJson)
        // Skip entries whose file was deleted/moved outside the app.
            .where((b) => File(b.pdfPath).existsSync())
            .toList();
        setState(() => _books
          ..clear()
          ..addAll(list));
      }
    } catch (_) {
      // Corrupt or missing index — start with an empty library rather than crashing.
    } finally {
      if (mounted) setState(() => _isLoadingLibrary = false);
    }
  }

  Future<void> _saveLibrary() async {
    try {
      final file = await _libraryIndexFile;
      await file.parent.create(recursive: true);
      final raw = jsonEncode(_books.map((b) => b.toJson()).toList());
      await file.writeAsString(raw);
    } catch (_) {
      // Non-fatal — worst case the library doesn't persist this session.
    }
  }

  // ── Selection mode ────────────────────────────────────────────────────

  void _enterSelectionMode(String initialPath) {
    setState(() {
      _isSelectionMode = true;
      _selectedPaths
        ..clear()
        ..add(initialPath);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedPaths.clear();
    });
  }

  void _toggleSelection(String path) {
    setState(() {
      if (_selectedPaths.contains(path)) {
        _selectedPaths.remove(path);
        // Auto-exit selection mode if nothing is left selected.
        if (_selectedPaths.isEmpty) _isSelectionMode = false;
      } else {
        _selectedPaths.add(path);
      }
    });
  }

  // ── Delete ─────────────────────────────────────────────────────────────

  /// Deletes the given books: removes their files from disk, removes them
  /// from the in-memory list, and persists the updated library index.
  Future<void> _deleteBooks(List<Book> booksToDelete) async {
    for (final book in booksToDelete) {
      try {
        final file = File(book.pdfPath);
        if (await file.exists()) await file.delete();
      } catch (_) {
        // Non-fatal — if the file is already gone, still remove the entry.
      }
    }

    final pathsToDelete = booksToDelete.map((b) => b.pdfPath).toSet();
    setState(() {
      _books.removeWhere((b) => pathsToDelete.contains(b.pdfPath));
    });
    await _saveLibrary();
  }

  Future<void> _confirmDeleteSingle(Book book) async {
    final confirmed = await _showDeleteConfirmation(
      title: 'Delete book?',
      message: 'This will permanently delete "${book.title}". This cannot be undone.',
    );
    if (confirmed == true) {
      await _deleteBooks([book]);
      if (mounted) _showSnackBar('Deleted "${book.title}"');
    }
  }

  Future<void> _confirmDeleteSelected() async {
    final count = _selectedPaths.length;
    final confirmed = await _showDeleteConfirmation(
      title: count == 1 ? 'Delete book?' : 'Delete $count books?',
      message: 'This will permanently delete the selected '
          '${count == 1 ? 'book' : 'books'}. This cannot be undone.',
    );
    if (confirmed == true) {
      final toDelete = _books.where((b) => _selectedPaths.contains(b.pdfPath)).toList();
      _exitSelectionMode();
      await _deleteBooks(toDelete);
      if (mounted) {
        _showSnackBar(count == 1 ? 'Deleted 1 book' : 'Deleted $count books');
      }
    }
  }

  Future<bool?> _showDeleteConfirmation({
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Inter', color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'Inter')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                fontFamily: 'Inter',
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Extensions considered "book" formats — kept in one place so the
  // XTypeGroup filter and the post-pick validation never drift apart.
  static const _allowedBookExtensions = [
    'pdf', 'epub', 'mobi', 'azw3', 'fb2', 'djvu', 'txt',
  ];

  Future<void> _onUploadPressed() async {
    // Prevent double-tap while a pick is in progress.
    if (_isUploading) return;
    setState(() => _isUploading = true);

    try {
      const typeGroup = XTypeGroup(
        label: 'Books',
        extensions: _allowedBookExtensions,
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

      final XFile? picked = await openFile(
        acceptedTypeGroups: [typeGroup],
      );

      if (picked == null) return;

      final sourcePath = picked.path;
      final ext = p.extension(sourcePath).replaceFirst('.', '').toLowerCase();

      // Defensive check: some platform pickers are permissive about the
      // filter, so re-validate the extension before accepting the file.
      if (!_allowedBookExtensions.contains(ext)) {
        if (mounted) {
          _showSnackBar('Unsupported file type: .$ext');
        }
        return;
      }

      // Copy the book into app's documents directory so it survives cache clears.
      final docsDir  = await getApplicationDocumentsDirectory();
      final booksDir = Directory(p.join(docsDir.path, 'books'));
      await booksDir.create(recursive: true);

      final fileName = p.basename(sourcePath);
      final destPath = p.join(booksDir.path, fileName);
      await File(sourcePath).copy(destPath);

      // Title = filename without extension, as-is.
      final title = p.basenameWithoutExtension(fileName);

      // Prevent duplicates (same filename).
      if (_books.any((b) => b.pdfPath == destPath)) return;

      setState(() {
        _books.add(Book(title: title, pdfPath: destPath));
      });
      await _saveLibrary();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not import file: $e',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isSelectionMode
          ? _buildSelectionAppBar(context)
          : _buildAppBar(context),
      body: _isLoadingLibrary
          ? const Center(child: CircularProgressIndicator())
          : (_books.isEmpty ? _buildEmpty() : _buildGrid()),
      bottomNavigationBar: _isSelectionMode ? null : _buildBottomBar(),
      floatingActionButton: _isSelectionMode ? null : _buildFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endContained,
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Glossy.',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontStyle: FontStyle.italic,
            ),
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
        ],
      ),
      toolbarHeight: 72,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: ValueListenableBuilder<String>(
            valueListenable: aiStatusNotifier,
            builder: (_, status, _) => _AiBadge(status: status),
          ),
        ),
      ],
    );
  }

  // ── Selection-mode AppBar ──────────────────────────────────────────────────

  PreferredSizeWidget _buildSelectionAppBar(BuildContext context) {
    final count = _selectedPaths.length;
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close, color: AppColors.ink),
        onPressed: _exitSelectionMode,
        tooltip: 'Cancel',
      ),
      title: Text(
        '$count selected',
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
      toolbarHeight: 72,
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.danger),
          tooltip: 'Delete selected',
          onPressed: count == 0 ? null : _confirmDeleteSelected,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ── Grid ───────────────────────────────────────────────────────────────────

  Widget _buildGrid() {
    // +1 for the empty upload slot (hidden during selection mode)
    final itemCount = _isSelectionMode ? _books.length : _books.length + 1;

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
          return _BookCard(
            book: book,
            isSelectionMode: _isSelectionMode,
            isSelected: _selectedPaths.contains(book.pdfPath),
            onTap: () {
              if (_isSelectionMode) {
                _toggleSelection(book.pdfPath);
              }
              // Non-selection-mode tap is reserved for opening the book later.
            },
            onLongPress: () {
              if (!_isSelectionMode) _enterSelectionMode(book.pdfPath);
            },
            onDeletePressed: () => _confirmDeleteSingle(book),
          );
        }
        return _EmptySlot(onTap: _onUploadPressed);
      },
    );
  }

  // ── Empty state (no books at all) ──────────────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.menu_book_outlined, size: 80, color: AppColors.muted),
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

  // ── Bottom bar ─────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    final total      = _books.length;
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

  // ── FAB ────────────────────────────────────────────────────────────────────

  Widget _buildFab() {
    return FloatingActionButton(
      onPressed: _isUploading ? null : _onUploadPressed,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.paper,
      elevation: 2,
      child: _isUploading
          ? const SizedBox(
        width: 22, height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5, color: AppColors.paper,
        ),
      )
          : const Icon(Icons.add),
    );
  }
}

// ---------------------------------------------------------------------------
// _BookCard
// ---------------------------------------------------------------------------

class _BookCard extends StatelessWidget {
  const _BookCard({
    required this.book,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onDeletePressed,
  });

  final Book book;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDeletePressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover placeholder (no image extraction yet)
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _CoverPlaceholder(title: book.title),
                  ),
                ),

                // Dim overlay + checkmark when selected.
                if (isSelectionMode)
                  Positioned.fill(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.ink.withValues(alpha: 0.35)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                // Selection checkbox (top-left) — only in selection mode.
                if (isSelectionMode)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _SelectionCheckbox(isSelected: isSelected),
                  ),

                // 3-dot menu (top-right) — hidden during selection mode.
                if (!isSelectionMode)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: _BookCardMenu(onDeletePressed: onDeletePressed),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Title — filename without extension
          Text(
            book.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),

          // File type hint — shows the actual file type (PDF, EPUB, etc.)
          Text(
            book.fileTypeLabel,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.muted,
            ),
          ),

          const SizedBox(height: 6),

          _ProgressBar(progress: book.progress),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _BookCardMenu — the vertical 3-dot menu shown on each book card
// ---------------------------------------------------------------------------

class _BookCardMenu extends StatelessWidget {
  const _BookCardMenu({required this.onDeletePressed});

  final VoidCallback onDeletePressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.ink.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: AppColors.paper, size: 18),
        padding: EdgeInsets.zero,
        splashRadius: 18,
        color: AppColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: (value) {
          if (value == 'delete') onDeletePressed();
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                SizedBox(width: 10),
                Text(
                  'Delete',
                  style: TextStyle(fontFamily: 'Inter', color: AppColors.danger),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _SelectionCheckbox — top-left indicator shown during selection mode
// ---------------------------------------------------------------------------

class _SelectionCheckbox extends StatelessWidget {
  const _SelectionCheckbox({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? AppColors.primary : AppColors.paper.withValues(alpha: 0.85),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: 1.5,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check, size: 16, color: AppColors.paper)
          : null,
    );
  }
}

// ---------------------------------------------------------------------------
// _EmptySlot — same action as FAB
// ---------------------------------------------------------------------------

class _EmptySlot extends StatelessWidget {
  const _EmptySlot({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.stage,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.border,
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Text(
                  'EMPTY',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.4,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ),
          ),
          // Keep same height as _BookCard text area so grid rows align.
          const SizedBox(height: 8),
          const SizedBox(height: 13), // title line-height
          const SizedBox(height: 11), // author line-height
          const SizedBox(height: 6),
          const SizedBox(height: 4),  // progress bar height
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ProgressBar
// ---------------------------------------------------------------------------

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        return Stack(
          children: [
            Container(
              height: 4,
              width: constraints.maxWidth,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (progress > 0)
              Container(
                height: 4,
                width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _CoverPlaceholder — shown when asset is missing
// ---------------------------------------------------------------------------

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.secondary,
      child: Center(
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppColors.muted,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _AiBadge
// ---------------------------------------------------------------------------

class _AiBadge extends StatelessWidget {
  const _AiBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isActive   = status == 'active';
    final isChecking = status == 'checking';

    final color = isActive
        ? AppColors.success
        : isChecking
        ? AppColors.warning
        : AppColors.muted;

    final label = isActive
        ? 'AI ACTIVE'
        : isChecking
        ? 'CHECKING'
        : 'AI OFF';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: isActive
                  ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4)]
                  : null,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}