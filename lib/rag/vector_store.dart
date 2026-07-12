import 'dart:math';
import 'dart:typed_data';
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
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE chunks (
            id TEXT PRIMARY KEY,
            book_id TEXT NOT NULL,
            chunk_index INTEGER NOT NULL,
            text TEXT NOT NULL,
            embedding BLOB NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_chunks_book ON chunks(book_id)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('DROP TABLE IF EXISTS chunks');
          await db.execute('''
            CREATE TABLE chunks (
              id TEXT PRIMARY KEY,
              book_id TEXT NOT NULL,
              chunk_index INTEGER NOT NULL,
              text TEXT NOT NULL,
              embedding BLOB NOT NULL
            )
          ''');
          await db.execute('CREATE INDEX idx_chunks_book ON chunks(book_id)');
        }
      },
    );
    return _instance = VectorStore._(db);
  }

  Future<void> upsertChunks(List<TextChunk> chunks) async {
    final batch = _db.batch();
    for (final c in chunks) {
      final floatList = Float32List.fromList(c.embedding);
      batch.insert('chunks', {
        'id': c.id,
        'book_id': c.bookId,
        'chunk_index': c.chunkIndex,
        'text': c.text,
        'embedding': floatList.buffer.asUint8List(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<bool> isBookIndexed(String bookId) async {
    final rows = await _db.query(
      'chunks',
      columns: ['id'],
      where: 'book_id = ?',
      whereArgs: [bookId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> deleteBook(String bookId) =>
      _db.delete('chunks', where: 'book_id = ?', whereArgs: [bookId]);

  /// Brute-force cosine similarity — now uses Float32List for better speed.
  Future<List<ScoredChunk>> search(
    List<double> queryEmbedding, {
    String? bookId,
    int topK = 5,
  }) async {
    final rows = bookId != null
        ? await _db.query('chunks', where: 'book_id = ?', whereArgs: [bookId])
        : await _db.query('chunks');

    final qEmb = Float32List.fromList(queryEmbedding);
    final scored = <ScoredChunk>[];

    for (final row in rows) {
      final bytes = row['embedding'] as Uint8List;
      final embedding = Float32List.sublistView(bytes);

      scored.add(
        ScoredChunk(
          TextChunk(
            id: row['id'] as String,
            bookId: row['book_id'] as String,
            chunkIndex: row['chunk_index'] as int,
            text: row['text'] as String,
            embedding: embedding,
          ),
          _cosineSimilarity(qEmb, embedding),
        ),
      );
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(topK).toList();
  }

  double _cosineSimilarity(Float32List a, Float32List b) {
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
