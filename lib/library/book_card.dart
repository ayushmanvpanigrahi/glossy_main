import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../reader/reader_screen.dart';
import '../rag/rag_models.dart';
import 'book.dart';
import 'book_cover.dart';
import 'home_widgets.dart';
import 'indexing_status_service.dart';

// ---------------------------------------------------------------------------
// BookCard
// ---------------------------------------------------------------------------

class BookCard extends StatelessWidget {
  const BookCard({
    super.key,
    required this.book,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onToggleSelected,
    required this.onEnterSelectionMode,
    required this.onDelete,
    required this.onIndexNow,
  });

  final Book book;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onToggleSelected;
  final VoidCallback onEnterSelectionMode;
  final VoidCallback onDelete;
  final VoidCallback onIndexNow;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSelectionMode
          ? onToggleSelected
          : () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ReaderScreen(book: book)),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover art — real cover when we have one, designed placeholder
          // otherwise — plus the "…" menu or selection checkbox on top,
          // and the indexing status badge at the bottom.
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  BookCover(book: book),

                  // Dim the cover slightly once selected, like a pressed state.
                  if (isSelected)
                    Container(color: Colors.black.withValues(alpha: 0.15)),

                  if (isSelectionMode)
                    _SelectionBadge(isSelected: isSelected)
                  else
                    _BookCardMenu(
                      onSelect: onEnterSelectionMode,
                      onDelete: onDelete,
                      onIndexNow: onIndexNow,
                    ),

                  if (!isSelectionMode)
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: _IndexingBadge(pdfPath: book.pdfPath),
                    ),
                ],
              ),
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

          // Author when known, otherwise fall back to the "PDF" file-type hint.
          Text(
            book.author ?? 'PDF',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.muted,
            ),
          ),

          const SizedBox(height: 6),

          ProgressBar(progress: book.progress),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _BookCardMenu — "…" button opening Select / Index for AI / Delete
// ---------------------------------------------------------------------------

class _BookCardMenu extends StatelessWidget {
  const _BookCardMenu({
    required this.onSelect,
    required this.onDelete,
    required this.onIndexNow,
  });

  final VoidCallback onSelect;
  final VoidCallback onDelete;
  final VoidCallback onIndexNow;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      right: 8,
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        tooltip: '',
        splashRadius: 18,
        icon: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.more_vert, color: Colors.white, size: 16),
        ),
        color: AppColors.paper,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onSelected: (value) {
          if (value == 'select') onSelect();
          if (value == 'delete') onDelete();
          if (value == 'index') onIndexNow();
        },
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: 'select',
            child: Text(
              'Select',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.ink,
              ),
            ),
          ),
          PopupMenuItem(
            value: 'index',
            child: Text(
              'Index for AI',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.ink,
              ),
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Text(
              'Delete',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _SelectionBadge — checkbox-style indicator shown during multi-select
// ---------------------------------------------------------------------------

class _SelectionBadge extends StatelessWidget {
  const _SelectionBadge({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected
              ? AppColors.primary
              : Colors.white.withValues(alpha: 0.85),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
        ),
        child: isSelected
            ? const Icon(Icons.check, size: 15, color: Colors.white)
            : null,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _IndexingBadge — live RAG-indexing status pill, bottom-left of the cover.
// Listens directly to IndexingStatusService so it updates in real time
// without the parent HomeScreen needing to rebuild the whole grid.
// ---------------------------------------------------------------------------

class _IndexingBadge extends StatelessWidget {
  const _IndexingBadge({required this.pdfPath});

  final String pdfPath;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, BookIndexStatus>>(
      valueListenable: IndexingStatusService.instance.statusNotifier,
      builder: (context, statuses, _) {
        final status = statuses[pdfPath] ?? BookIndexStatus.notIndexed;

        // Not-indexed books show nothing — the "…" menu's "Index for AI"
        // is the call to action, we don't want a badge on every single
        // card cluttering the grid before the user has opted in.
        if (status == BookIndexStatus.notIndexed) {
          return const SizedBox.shrink();
        }

        final (label, color, icon) = switch (status) {
          BookIndexStatus.indexing => (
            'INDEXING',
            AppColors.warning,
            Icons.autorenew,
          ),
          BookIndexStatus.indexed => (
            'INDEXED',
            AppColors.success,
            Icons.check_circle,
          ),
          BookIndexStatus.failed => (
            'FAILED',
            AppColors.danger,
            Icons.error_outline,
          ),
          BookIndexStatus.notIndexed => ('', AppColors.muted, Icons.circle),
        };

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (status == BookIndexStatus.indexing)
                SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                )
              else
                Icon(icon, size: 10, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
