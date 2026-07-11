import 'package:flutter/material.dart';
import '../app_colors.dart';

// ---------------------------------------------------------------------------
// ExplainSheetHeader — logo, title, model label, RAG status, close button.
// ---------------------------------------------------------------------------
// FIX (overflow bug — "RIGHT OVERFLOWED BY 45 PIXELS"):
// The old Row had a raw `Text(modelLabel)` with no size constraint, right
// before a `Spacer()`. Long model ids (e.g.
// "meta-llama/llama-3.2-3b-instruct:free") have no bounded width to shrink
// into, so they push the close button off-screen.
// Fix: wrap modelLabel in Expanded + ellipsis, and drop the Spacer — an
// Expanded already consumes all remaining space, which naturally docks the
// close button flush right without needing a separate Spacer.
//
// ADDED: an optional RAG status chip (issue #4/#5 — "pata nahi chalta RAG
// kaam kar raha hai ke nahi").
// ---------------------------------------------------------------------------

class ExplainSheetHeader extends StatelessWidget {
  const ExplainSheetHeader({
    super.key,
    required this.modelLabel,
    this.ragStatusLabel,
  });

  final String modelLabel;

  /// e.g. "RAG ready", "Indexing 42%", "RAG off" — null hides the chip.
  final String? ragStatusLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                'G',
                style: TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Glossy AI',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              modelLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 11,
                color: AppColors.muted,
              ),
            ),
          ),
          if (ragStatusLabel != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.stage,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                ragStatusLabel!,
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 10,
                  color: AppColors.muted,
                ),
              ),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
