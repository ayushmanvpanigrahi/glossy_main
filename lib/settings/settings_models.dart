// ---------------------------------------------------------------------------
// Data models & enums used across the Settings feature.
// ---------------------------------------------------------------------------

enum ValidationResult { valid, invalid, networkError, unknown }
enum ModelProvider    { openRouter, groq }

// New: result of a live model ping
enum ModelPingResult  { success, emptyResponse, failed, unauthorized, networkError, noKey }

// New: per-key status shown in the UI
enum KeyStatus { idle, checking, valid, invalid, networkError }

class ModelFetchResult {
  const ModelFetchResult({required this.models, required this.errors});
  final List<OpenRouterModel> models;
  final List<String> errors;
}

// Replaces the inline record type from the old service
class SavedSettings {
  const SavedSettings({
    this.apiKey,
    this.modelId,
    this.groqApiKey,
    this.modelProvider = ModelProvider.openRouter,
  });
  final String? apiKey;
  final String? modelId;
  final String? groqApiKey;
  final ModelProvider modelProvider;
}

class RagSettings {
  const RagSettings({
    this.embeddingMode,
    this.indexingTrigger,
    this.embeddingApiKey,
  });
  final String? embeddingMode;
  final String? indexingTrigger;
  final String? embeddingApiKey;
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
  final String? priceLabel;
  final ModelProvider provider;

  factory OpenRouterModel.fromJson(Map<String, dynamic> json) {
    final id   = json['id'] as String? ?? '';
    final free = id.endsWith(':free');

    String? priceLabel;
    if (!free) {
      final pricing = json['pricing'] as Map<String, dynamic>?;
      if (pricing != null) {
        final rawPrompt      = pricing['prompt']?.toString() ?? '0';
        final rawCompletion  = pricing['completion']?.toString() ?? '0';
        final promptCost     = double.tryParse(rawPrompt) ?? 0.0;
        final completionCost = double.tryParse(rawCompletion) ?? 0.0;
        final cost = promptCost > 0 ? promptCost : completionCost;
        if (cost > 0) {
          final perMillion = cost * 1_000_000;
          priceLabel = perMillion < 1
              ? '\$${perMillion.toStringAsFixed(3)}/M'
              : '\$${perMillion.toStringAsFixed(2)}/M';
        }
      }
    }

    return OpenRouterModel(
      id:   id,
      name: json['name'] as String? ?? id,
      isFree: free,
      priceLabel: priceLabel,
    );
  }
}
