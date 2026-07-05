// ---------------------------------------------------------------------------
// Data model & enum used across the Settings feature.
// ---------------------------------------------------------------------------

enum ValidationResult { valid, invalid, networkError, unknown }
enum ModelProvider { openRouter, groq }

class ModelFetchResult {
  const ModelFetchResult({required this.models, required this.errors});
  final List<OpenRouterModel> models;
  final List<String> errors;
}

class OpenRouterModel {
  const OpenRouterModel({
    required this.id,
    required this.name,
    required this.isFree,
    this.priceLabel,
    this.provider = ModelProvider.openRouter,
  });

  final String id;
  final String name;
  final bool isFree;

  /// Human-readable price label e.g. "$0.15/M". Null for free models.
  final String? priceLabel;
  final ModelProvider provider;

  factory OpenRouterModel.fromJson(Map<String, dynamic> json) {
    final id   = json['id'] as String? ?? '';
    final free = id.endsWith(':free');

    String? priceLabel;
    if (!free) {
      final pricing = json['pricing'] as Map<String, dynamic>?;
      if (pricing != null) {
        // Try prompt price first, fall back to completion price.
        final rawPrompt     = pricing['prompt']?.toString() ?? '0';
        final rawCompletion = pricing['completion']?.toString() ?? '0';
        final promptCost     = double.tryParse(rawPrompt) ?? 0.0;
        final completionCost = double.tryParse(rawCompletion) ?? 0.0;

        // Use whichever is non-zero (prompt price is standard).
        final cost = promptCost > 0 ? promptCost : completionCost;
        if (cost > 0) {
          final perMillion = cost * 1000000;
          // Format: remove trailing zeros — e.g. $0.15/M not $0.150000/M
          final formatted = perMillion < 1
              ? '\$${perMillion.toStringAsFixed(3)}/M'
              : '\$${perMillion.toStringAsFixed(2)}/M';
          priceLabel = formatted;
        }
      }
    }

    return OpenRouterModel(
      id: id,
      name: json['name'] as String? ?? id,
      isFree: free,
      priceLabel: priceLabel,
    );
  }
}
