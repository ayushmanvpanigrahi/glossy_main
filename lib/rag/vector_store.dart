import 'dart:convert';
import 'dart:math';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'rag_models.dart';

class VectorStore {
  VectorStore._(this._db);
  final Database _db;
  static VectorStore? _instance;

  static Future<VectorStore> instance() async {
    if (_instance != null) return _instance!;
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'glossy_rag.db');
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE chunks (
            id TEXT PRIMARY KEY,
            book_id TEXT NOT NULL,
            chunk_index INTEGER NOT NULL,
            text TEXT NOT NULL,
            embedding TEXT NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_chunks_book ON chunks(book_id)');
      },
    );
    return _instance = VectorStore._(db);
  }

  Future<void> upsertChunks(List<TextChunk> chunks) async {
    final batch = _db.batch();
    for (final c in chunks) {
      batch.insert(
        'chunks',
        {
          'id': c.id,
          'book_id': c.bookId,
          'chunk_index': c.chunkIndex,
          'text': c.text,
          'embedding': jsonEncode(c.embedding),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<bool> isBookIndexed(String bookId) async {
    final rows = await _db.query('chunks',
        columns: ['id'], where: 'book_id = ?', whereArgs: [bookId], limit: 1);
    return rows.isNotEmpty;
  }

  Future<void> deleteBook(String bookId) =>
      _db.delete('chunks', where: 'book_id = ?', whereArgs: [bookId]);

  /// Brute-force cosine similarity — fast enough at book/library scale.
  Future<List<ScoredChunk>> search(
      List<double> queryEmbedding, {
        String? bookId,
        int topK = 5,
      }) async {
    final rows = bookId != null
        ? await _db.query('chunks', where: 'book_id = ?', whereArgs: [bookId])
        : await _db.query('chunks');

    final scored = <ScoredChunk>[];
    for (final row in rows) {
      final embedding = (jsonDecode(row['embedding'] as String) as List)
          .cast<num>()
          .map((n) => n.toDouble())
          .toList();
      scored.add(ScoredChunk(
        TextChunk(
          id: row['id'] as String,
          bookId: row['book_id'] as String,
          chunkIndex: row['chunk_index'] as int,
          text: row['text'] as String,
          embedding: embedding,
        ),
        _cosineSimilarity(queryEmbedding, embedding),
      ));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(topK).toList();
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    double dot = 0, magA = 0, magB = 0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      magA += a[i] * a[i];
      magB += b[i] * b[i];
    }
    if (magA == 0 || magB == 0) return 0;
    return dot / (sqrt(magA) * sqrt(magB));
  }
}