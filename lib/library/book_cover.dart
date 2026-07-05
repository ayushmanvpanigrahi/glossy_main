import 'package:flutter/material.dart';
import '../app_colors.dart';
import 'book.dart';

// ---------------------------------------------------------------------------
// BookCover — real cover art when available, designed placeholder otherwise
// ---------------------------------------------------------------------------

class BookCover extends StatelessWidget {
  const BookCover({super.key, required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final coverUrl = book.coverUrl;
    if (coverUrl == null) return GeneratedCover(title: book.title);

    return Image.network(
      coverUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: AppColors.stage,
          child: const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      // Covers are fetched from a public API and can 404 or fail to load —
      // fall back to the generated cover rather than showing a broken image.
      errorBuilder: (_, _, _) => GeneratedCover(title: book.title),
    );
  }
}

// ---------------------------------------------------------------------------
// GeneratedCover — designed placeholder shown until real cover art is
// found (or when no match exists). Uses a deterministic gradient so the
// same book always renders the same cover.
// ---------------------------------------------------------------------------

class GeneratedCover extends StatelessWidget {
  const GeneratedCover({super.key, required this.title});

  final String title;

  // Curated gradient pairs consistent with the app's warm palette, with
  // enough variety that a shelf of placeholders doesn't look identical.
  static const _palettes = [
    [Color(0xFFE8A45C), Color(0xFFC2703D)], // amber → primary
    [Color(0xFF3A4A5C), Color(0xFF1F2A36)], // slate navy
    [Color(0xFF8B9A7A), Color(0xFF4F5D45)], // olive
    [Color(0xFFC97B63), Color(0xFF8C4A3A)], // terracotta
    [Color(0xFF5C7A8B), Color(0xFF344B59)], // dusty blue
    [Color(0xFFB08968), Color(0xFF6B4A34)], // warm brown
  ];

  @override
  Widget build(BuildContext context) {
    final palette = _palettes[title.hashCode.abs() % _palettes.length];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette,
        ),
      ),
      child: Stack(
        children: [
          // Subtle diagonal accent so the placeholder reads as a designed
          // cover rather than a flat color swatch.
          Positioned.fill(
            child: CustomPaint(
              painter: _DiagonalAccentPainter(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                title.toUpperCase(),
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  height: 1.25,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagonalAccentPainter extends CustomPainter {
  const _DiagonalAccentPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width * 0.35, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.55)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DiagonalAccentPainter oldDelegate) =>
      oldDelegate.color != color;
}
