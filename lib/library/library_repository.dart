import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'book.dart';

// ---------------------------------------------------------------------------
// LibraryRepository
// ---------------------------------------------------------------------------
// Owns everything that touches disk for the library: reading/writing the
// JSON index, copying picked files into app storage, and deleting book
// files. Kept free of Flutter UI so it's testable independently of
// home_screen.dart.
// ---------------------------------------------------------------------------

class LibraryRepository {
  const LibraryRepository();

  // Extensions considered "book" formats — kept in one place so the
  // upload picker and the post-pick validation never drift apart.
  static const allowedBookExtensions = [
    'pdf',
    'epub',
    'mobi',
    'azw3',
    'fb2',
    'djvu',
    'txt',
  ];

  Future<File> get _libraryIndexFile async {
    final docsDir = await getApplicationDocumentsDirectory();
    return File(p.join(docsDir.path, 'books', 'library_index.json'));
  }

  /// Loads the persisted library index, silently dropping any entries
  /// whose underlying file no longer exists on disk.
  /// Returns an empty list on a missing or corrupt index rather than
  /// throwing — the library screen should never crash on load.
  Future<List<Book>> loadLibrary() async {
    try {
      final file = await _libraryIndexFile;
      if (!await file.exists()) return [];

      final raw = await file.readAsString();
      return (jsonDecode(raw) as List)
          .cast<Map<String, dynamic>>()
          .map(Book.fromJson)
          .where((b) => File(b.pdfPath).existsSync())
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Persists the given list as the new library index. Non-fatal on
  /// failure — worst case the library doesn't persist this session.
  Future<void> saveLibrary(List<Book> books) async {
    try {
      final file = await _libraryIndexFile;
      await file.parent.create(recursive: true);
      final raw = jsonEncode(books.map((b) => b.toJson()).toList());
      await file.writeAsString(raw);
    } catch (_) {
      // Non-fatal.
    }
  }

  /// Copies the picked file at [sourcePath] into app storage and returns
  /// the new [Book] entry. Throws [UnsupportedBookFormatException] if the
  /// extension isn't an allowed book format (defensive re-check, since
  /// some platform pickers are permissive about the filter).
  Future<Book> importBook(String sourcePath) async {
    final ext = p.extension(sourcePath).replaceFirst('.', '').toLowerCase();
    if (!allowedBookExtensions.contains(ext)) {
      throw UnsupportedBookFormatException(ext);
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final booksDir = Directory(p.join(docsDir.path, 'books'));
    await booksDir.create(recursive: true);

    final fileName = p.basename(sourcePath);
    final destPath = p.join(booksDir.path, fileName);
    await File(sourcePath).copy(destPath);

    final title = p.basenameWithoutExtension(fileName);
    return Book(title: title, pdfPath: destPath);
  }

  /// Deletes the underlying file for [book] from disk. Non-fatal on
  /// failure — the library index is the source of truth for what's "in"
  /// the library, so a stray file left behind doesn't affect the app.
  Future<void> deleteBookFile(Book book) async {
    try {
      final file = File(book.pdfPath);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Non-fatal.
    }
  }
}

/// Thrown by [LibraryRepository.importBook] when the picked file's
/// extension isn't one of [LibraryRepository.allowedBookExtensions].
class UnsupportedBookFormatException implements Exception {
  UnsupportedBookFormatException(this.extension);
  final String extension;

  @override
  String toString() => 'Unsupported file type: .$extension';
}
