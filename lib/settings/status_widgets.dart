import 'package:flutter/material.dart';
import '../app_colors.dart';

// ---------------------------------------------------------------------------
// Service status badge — three boxes (OFF / CHECKING / ACTIVE), one lit up.
// ---------------------------------------------------------------------------

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.aiStatus});

  final String aiStatus;

  static const _statuses = [
    (label: 'OFF', color: AppColors.danger, key: 'inactive'),
    (label: 'CHECKING', color: AppColors.warning, key: 'checking'),
    (label: 'ACTIVE', color: AppColors.success, key: 'active'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SERVICE STATUS',
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 11,
            letterSpacing: 1.0,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (int i = 0; i < _statuses.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: StatusBox(
                  label: _statuses[i].label,
                  color: _statuses[i].color,
                  isActive: aiStatus == _statuses[i].key,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class StatusBox extends StatelessWidget {
  const StatusBox({
    super.key,
    required this.label,
    required this.color,
    required this.isActive,
  });

  final String label;
  final Color color;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.08) : AppColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color.withValues(alpha: 0.5) : AppColors.border,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? color : color.withValues(alpha: 0.35),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 11,
              letterSpacing: 0.5,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? AppColors.ink : AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
