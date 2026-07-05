import 'package:flutter/material.dart';
import '../app_colors.dart';
import 'settings_models.dart';

// ---------------------------------------------------------------------------
// Scrollable model list (card style) + its supporting badges.
// ---------------------------------------------------------------------------

class ModelList extends StatelessWidget {
  const ModelList({
    super.key,
    required this.models,
    required this.selectedModelId,
    required this.onSelect,
  });

  final List<OpenRouterModel> models;
  final String? selectedModelId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    if (models.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.stage,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text(
            'No models match',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ),
      );
    }

    return Container(
      height: 260,
      decoration: BoxDecoration(
        color: AppColors.stage,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 6),
          itemCount: models.length,
          separatorBuilder: (context, i) => const Divider(
            height: 1,
            thickness: 1,
            indent: 16,
            endIndent: 16,
            color: AppColors.border,
          ),
          itemBuilder: (_, index) {
            final model = models[index];
            final selected = model.id == selectedModelId;
            return ModelCard(
              model: model,
              isSelected: selected,
              onTap: () => onSelect(model.id),
            );
          },
        ),
      ),
    );
  }
}

class ModelCard extends StatelessWidget {
  const ModelCard({
    super.key,
    required this.model,
    required this.isSelected,
    required this.onTap,
  });

  final OpenRouterModel model;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            // Model name + ID + provider tag
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    model.name,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    model.id,
                    style: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 10,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    model.provider == ModelProvider.groq
                        ? 'GROQ'
                        : 'OPENROUTER',
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: model.provider == ModelProvider.groq
                          ? AppColors.primary
                          : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // FREE / price badge
            PriceBadge(isFree: model.isFree, priceLabel: model.priceLabel),

            // Selected checkmark
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class PriceBadge extends StatelessWidget {
  const PriceBadge({super.key, required this.isFree, this.priceLabel});

  final bool isFree;
  final String? priceLabel;

  @override
  Widget build(BuildContext context) {
    final label = isFree ? 'FREE' : (priceLabel ?? 'PAID');
    final color = isFree ? AppColors.success : AppColors.muted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isFree
            ? AppColors.success.withValues(alpha: 0.12)
            : AppColors.muted.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isFree
              ? AppColors.success.withValues(alpha: 0.35)
              : AppColors.border,
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: color,
        ),
      ),
    );
  }
}
