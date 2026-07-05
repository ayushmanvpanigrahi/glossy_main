// ---------------------------------------------------------------------------
// Book model
// ---------------------------------------------------------------------------

class Book {
  const Book({
    required this.title,
    required this.pdfPath,
    this.progress = 0.0,
    this.author,
    this.coverUrl,
  });

  final String title;
  final String pdfPath; // absolute path to the copied file on device
  final double progress;

  /// Best-effort metadata from BookCoverService — null until enrichment
  /// completes (or if no match was found).
  final String? author;
  final String? coverUrl;

  bool get isInProgress => progress > 0.0 && progress < 1.0;

  Book copyWith({String? author, String? coverUrl}) => Book(
    title: title,
    pdfPath: pdfPath,
    progress: progress,
    author: author ?? this.author,
    coverUrl: coverUrl ?? this.coverUrl,
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'pdfPath': pdfPath,
    'progress': progress,
    'author': author,
    'coverUrl': coverUrl,
  };

  factory Book.fromJson(Map<String, dynamic> json) => Book(
    title: json['title'] as String,
    pdfPath: json['pdfPath'] as String,
    progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
    author: json['author'] as String?,
    coverUrl: json['coverUrl'] as String?,
  );
}
