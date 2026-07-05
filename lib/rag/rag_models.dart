enum EmbeddingMode { api, local }
enum IndexingTrigger { onAdd, lazy, background }

class TextChunk {
  const TextChunk({
    required this.id,
    required this.bookId,
    required this.chunkIndex,
    required this.text,
    required this.embedding,
  });

  final String id;
  final String bookId;
  final int chunkIndex;
  final String text;
  final List<double> embedding;
}

class ScoredChunk {
  const ScoredChunk(this.chunk, this.score);
  final TextChunk chunk;
  final double score;
}

enum BookIndexStatus { notIndexed, indexing, indexed, failed }