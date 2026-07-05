import 'package:flutter/material.dart';
import '../app_colors.dart';

// ---------------------------------------------------------------------------
// EmptySlot — same action as the FAB, shown as the last grid item
// ---------------------------------------------------------------------------

class EmptySlot extends StatelessWidget {
  const EmptySlot({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.stage,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: const Center(
                child: Text(
                  'EMPTY',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.4,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ),
          ),
          // Keep same height as BookCard text area so grid rows align.
          const SizedBox(height: 8),
          const SizedBox(height: 13), // title line-height
          const SizedBox(height: 11), // author line-height
          const SizedBox(height: 6),
          const SizedBox(height: 4), // progress bar height
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ProgressBar
// ---------------------------------------------------------------------------

class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        return Stack(
          children: [
            Container(
              height: 4,
              width: constraints.maxWidth,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (progress > 0)
              Container(
                height: 4,
                width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// AiBadge
// ---------------------------------------------------------------------------

class AiBadge extends StatelessWidget {
  const AiBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'active';
    final isChecking = status == 'checking';

    final color = isActive
        ? AppColors.success
        : isChecking
        ? AppColors.warning
        : AppColors.muted;

    final label = isActive
        ? 'AI ACTIVE'
        : isChecking
        ? 'CHECKING'
        : 'AI OFF';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 4,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
