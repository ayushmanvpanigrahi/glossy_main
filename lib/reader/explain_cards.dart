import 'package:flutter/material.dart';
import '../app_colors.dart';

// ---------------------------------------------------------------------------
// Small, stateless card widgets used inside GlossyExplainSheet's body.
// ---------------------------------------------------------------------------

class SelectedPassageCard extends StatelessWidget {
  const SelectedPassageCard({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SELECTED',
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 10,
              letterSpacing: 1,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '"$text"',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontStyle: FontStyle.italic,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class LabeledCard extends StatelessWidget {
  const LabeledCard({
    super.key,
    required this.label,
    required this.labelColor,
    required this.background,
    required this.text,
  });

  final String label;
  final Color labelColor;
  final Color background;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 10,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class ContextCard extends StatelessWidget {
  const ContextCard({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.stage,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 12,
            backgroundColor: AppColors.secondary,
            child: Text(
              'C',
              style: TextStyle(fontSize: 11, color: AppColors.ink),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Context in the book',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.muted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ErrorCard extends StatelessWidget {
  const ErrorCard({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.danger,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
