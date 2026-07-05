class TextChunker {
  const TextChunker({this.chunkSize = 800, this.overlap = 150});

  final int chunkSize;
  final int overlap;

  List<String> chunk(String text) {
    final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.isEmpty) return [];

    final chunks = <String>[];
    var start = 0;
    while (start < clean.length) {
      final end = (start + chunkSize).clamp(0, clean.length);
      chunks.add(clean.substring(start, end));
      if (end == clean.length) break;
      start = (end - overlap).clamp(0, clean.length);
    }
    return chunks;
  }
}