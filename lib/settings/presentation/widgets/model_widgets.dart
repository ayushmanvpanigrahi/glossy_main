import 'package:flutter/material.dart';
import '../../../../app_colors.dart';
import '../../data/models/settings_models.dart';

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

  Color _getProviderColor(ModelProvider p) {
    return switch (p) {
      ModelProvider.openRouter => AppColors.muted,
      ModelProvider.groq => const Color(0xFFF55036),
      ModelProvider.gemini => const Color(0xFF1A73E8),
    };
  }

  Color _getTypeColor(ModelType t) {
    return switch (t) {
      ModelType.text => AppColors.ink,
      ModelType.embedding => const Color(0xFF8E24AA),
      ModelType.other => const Color(0xFF00897B),
    };
  }

  @override
  Widget build(BuildContext context) {
    final effectiveProvider = model.effectiveProvider;
    final providerColor = _getProviderColor(effectiveProvider);
    final typeColor = _getTypeColor(model.type);

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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          model.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _TypeTag(type: model.type, color: typeColor),
                    ],
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
                    effectiveProvider.name.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: providerColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            PriceBadge(isFree: model.isFree, priceLabel: model.priceLabel),
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

class _TypeTag extends StatelessWidget {
  const _TypeTag({required this.type, required this.color});
  final ModelType type;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type.name.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 7,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
