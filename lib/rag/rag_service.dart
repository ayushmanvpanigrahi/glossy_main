import 'embedding_service.dart';
import 'rag_models.dart';
import 'text_chunker.dart';
import 'vector_store.dart';

class RagService {
  RagService({required this.embeddingService, TextChunker? chunker})
    : _chunker = chunker ?? const TextChunker();

  final EmbeddingService embeddingService;
  final TextChunker _chunker;

  /// Call wherever the app currently extracts a book's plain text —
  /// on add / lazily / from background, depending on the user's setting.
  Future<void> indexBook(String bookId, String fullText) async {
    final store = await VectorStore.instance();
    final pieces = _chunker.chunk(fullText);
    if (pieces.isEmpty) return;

    final chunks = <TextChunk>[];
    for (var i = 0; i < pieces.length; i++) {
      final embedding = await embeddingService.embed(pieces[i]);
      chunks.add(
        TextChunk(
          id: '$bookId#$i',
          bookId: bookId,
          chunkIndex: i,
          text: pieces[i],
          embedding: embedding,
        ),
      );
    }
    await store.upsertChunks(chunks);
  }

  Future<bool> isIndexed(String bookId) async =>
      (await VectorStore.instance()).isBookIndexed(bookId);

  Future<void> removeBook(String bookId) async =>
      (await VectorStore.instance()).deleteBook(bookId);

  /// Retrieves relevant chunks for a question, ready to prepend to a
  /// chat-completion prompt as context.
  Future<String> retrieveContext(
    String question, {
    String? bookId,
    int topK = 5,
  }) async {
    final store = await VectorStore.instance();
    final queryEmbedding = await embeddingService.embed(question);
    final results = await store.search(
      queryEmbedding,
      bookId: bookId,
      topK: topK,
    );
    if (results.isEmpty) return '';
    return results
        .map((r) => '[chunk ${r.chunk.chunkIndex}] ${r.chunk.text}')
        .join('\n\n');
  }
}
