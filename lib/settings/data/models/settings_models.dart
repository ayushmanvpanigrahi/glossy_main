// ---------------------------------------------------------------------------
// Data models & enums used across the Settings feature.
// ---------------------------------------------------------------------------

enum ValidationResult { valid, invalid, networkError, unknown }

enum ModelProvider { openRouter, groq, gemini }

enum ModelType { text, embedding, other }

enum ModelPingResult {
  success,
  emptyResponse,
  failed,
  unauthorized,
  networkError,
  noKey,
}

enum KeyStatus { idle, checking, valid, invalid, networkError }

class ModelFetchResult {
  const ModelFetchResult({required this.models, required this.errors});
  final List<OpenRouterModel> models;
  final List<String> errors;
}

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
    this.type = ModelType.text,
  });

  final String id;
  final String name;
  final bool isFree;
  final String? priceLabel;
  final ModelProvider provider;
  final ModelType type;

  ModelProvider get effectiveProvider {
    if (provider == ModelProvider.groq) return ModelProvider.groq;
    if (provider == ModelProvider.gemini) return ModelProvider.gemini;
    if (id.startsWith('google/')) return ModelProvider.gemini;
    if (id.startsWith('groq/')) return ModelProvider.groq;
    return ModelProvider.openRouter;
  }

  factory OpenRouterModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    final free = id.endsWith(':free');

    ModelType type = ModelType.text;
    final arch = json['architecture'] as Map<String, dynamic>?;
    if (arch != null) {
      final outputMods = (arch['output_modalities'] as List?) ?? const [];

      if (outputMods.contains('embeddings') || id.contains('embedding')) {
        type = ModelType.embedding;
      } else if (outputMods.contains('text')) {
        if (outputMods.contains('image') || outputMods.contains('audio')) {
          type = ModelType.other;
        } else {
          type = ModelType.text;
        }
      } else {
        type = ModelType.other;
      }
    }

    String? priceLabel;
    if (!free) {
      final pricing = json['pricing'] as Map<String, dynamic>?;
      if (pricing != null) {
        final rawPrompt = pricing['prompt']?.toString() ?? '0';
        final rawCompletion = pricing['completion']?.toString() ?? '0';
        final promptCost = double.tryParse(rawPrompt) ?? 0.0;
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
      id: id,
      name: json['name'] as String? ?? id,
      isFree: free,
      priceLabel: priceLabel,
      type: type,
      provider: ModelProvider.openRouter,
    );
  }
}
