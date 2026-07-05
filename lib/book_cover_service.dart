
import 'dart:convert';
import 'package:http/http.dart' as http;

// ---------------------------------------------------------------------------
// BookCoverService
// ---------------------------------------------------------------------------
// Best-effort lookup of a book's author + cover image, keyed by title, using
// Open Library's public search API (no API key required).
//
// This is intentionally forgiving: a missing/failed lookup should never
// block adding a book to the library, so every failure path returns
// BookMetadata.empty rather than throwing.
// ---------------------------------------------------------------------------

class BookCoverService {
  const BookCoverService();

  Future<BookMetadata> fetchMetadata(String title) async {
    try {
      final uri = Uri.https('openlibrary.org', '/search.json', {
        'title': title,
        'limit': '1',
        'fields': 'author_name,cover_i',
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return BookMetadata.empty;

      final docs = (jsonDecode(response.body)['docs'] as List?) ?? const [];
      if (docs.isEmpty) return BookMetadata.empty;

      final doc = docs.first as Map<String, dynamic>;
      final authors  = (doc['author_name'] as List?)?.cast<String>();
      final coverId  = doc['cover_i'] as int?;

      return BookMetadata(
        author: (authors != null && authors.isNotEmpty) ? authors.first : null,
        coverUrl: coverId != null
            ? 'https://covers.openlibrary.org/b/id/$coverId-M.jpg'
            : null,
      );
    } catch (_) {
      // Network/parse failure — treat as "no metadata found".
      return BookMetadata.empty;
    }
  }
}

class BookMetadata {
  const BookMetadata({this.author, this.coverUrl});

  final String? author;
  final String? coverUrl;

  static const empty = BookMetadata();

  bool get isEmpty => author == null && coverUrl == null;
}
