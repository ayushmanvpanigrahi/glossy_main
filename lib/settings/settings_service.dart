import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'settings_models.dart';

// ---------------------------------------------------------------------------
// SettingsService
// ---------------------------------------------------------------------------
// Pulls together everything that talks to secure storage or the network:
// - reading/writing the saved API key + model
// - fetching & filtering the OpenRouter model list
// - validating an API key
//
// Kept free of Flutter UI (`Widget`, `BuildContext`, etc.) so it can be
// tested or reused independently of settings_screen.dart.
// ---------------------------------------------------------------------------

class SettingsService {
  SettingsService({FlutterSecureStorage? storage})
      : _secureStorage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;

  static const apiKeyStorageKey = 'openrouter_api_key';
  static const modelStorageKey  = 'openrouter_model';
  static const embeddingModeKey    = 'rag_embedding_mode';   // 'api' | 'local'
  static const indexingTriggerKey  = 'rag_indexing_trigger'; // 'onAdd' | 'lazy' | 'background'
  static const embeddingApiKeyKey  = 'gemini_embedding_api_key';
  static const groqApiKeyKey     = 'groq_api_key';
  static const modelProviderKey  = 'model_provider'; // 'openRouter' | 'groq'

  // ── Storage ────────────────────────────────────────────────────────────

  /// Reads the saved settings (API keys, model, provider) concurrently.
  Future<({String? apiKey, String? modelId, String? groqApiKey, ModelProvider modelProvider})>
      loadSavedSettings() async {
    final results = await Future.wait([
      _secureStorage.read(key: apiKeyStorageKey),
      _secureStorage.read(key: modelStorageKey),
      _secureStorage.read(key: groqApiKeyKey),
      _secureStorage.read(key: modelProviderKey),
    ]);
    return (
      apiKey: results[0],
      modelId: results[1],
      groqApiKey: results[2],
      modelProvider: results[3] == 'groq' ? ModelProvider.groq : ModelProvider.openRouter,
    );
  }

  Future<void> saveApiKey(String apiKey) =>
      _secureStorage.write(key: apiKeyStorageKey, value: apiKey);

  Future<void> deleteApiKey() =>
      _secureStorage.delete(key: apiKeyStorageKey);

  Future<void> saveModelId(String modelId) =>
      _secureStorage.write(key: modelStorageKey, value: modelId);

  Future<void> deleteModelId() =>
      _secureStorage.delete(key: modelStorageKey);

  Future<void> saveEmbeddingMode(String mode) =>
      _secureStorage.write(key: embeddingModeKey, value: mode);

  Future<void> saveIndexingTrigger(String trigger) =>
      _secureStorage.write(key: indexingTriggerKey, value: trigger);

  Future<void> saveEmbeddingApiKey(String key) =>
      _secureStorage.write(key: embeddingApiKeyKey, value: key);

  Future<void> saveGroqApiKey(String apiKey) =>
      _secureStorage.write(key: groqApiKeyKey, value: apiKey);

  Future<void> deleteGroqApiKey() =>
      _secureStorage.delete(key: groqApiKeyKey);

  Future<void> saveModelProvider(ModelProvider provider) =>
      _secureStorage.write(key: modelProviderKey, value: provider.name);

  Future<({String? embeddingMode, String? indexingTrigger, String? embeddingApiKey})>
      loadRagSettings() async {
    final results = await Future.wait([
      _secureStorage.read(key: embeddingModeKey),
      _secureStorage.read(key: indexingTriggerKey),
      _secureStorage.read(key: embeddingApiKeyKey),
    ]);
    return (
      embeddingMode: results[0],
      indexingTrigger: results[1],
      embeddingApiKey: results[2]
    );
  }

  // ── Model fetching ─────────────────────────────────────────────────────

  /// Fetches the OpenRouter model list, filters to text-in/text-out models,
  /// and sorts free models first then alphabetically.
  /// Throws on network/parse failure — caller decides how to surface it.
  Future<List<OpenRouterModel>> fetchModels() async {
    final response = await http
        .get(Uri.parse('https://openrouter.ai/api/v1/models'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw SettingsServiceException(
          'Failed to load models (${response.statusCode})');
    }

    final modelsJson =
        (jsonDecode(response.body)['data'] as List).cast<Map<String, dynamic>>();

    final textOnly = modelsJson
        .where(_isTextOnlyModel)
        .map(OpenRouterModel.fromJson)
        .toList()
      ..sort((a, b) {
        // Free models first, then alphabetical.
        if (a.isFree != b.isFree) return a.isFree ? -1 : 1;
        return a.name.compareTo(b.name);
      });

    return textOnly;
  }

  Future<List<OpenRouterModel>> fetchGroqModels(String apiKey) async {
    final response = await http.get(
      Uri.parse('https://api.groq.com/openai/v1/models'),
      headers: {'Authorization': 'Bearer $apiKey'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw SettingsServiceException(
          'Failed to load Groq models (${response.statusCode})');
    }

    final data =
        (jsonDecode(response.body)['data'] as List).cast<Map<String, dynamic>>();
    return data
        .where((m) => m['active'] != false)
        .map((m) => OpenRouterModel(
              id: m['id'] as String? ?? '',
              name: m['id'] as String? ?? '',
              isFree: true,
              provider: ModelProvider.groq,
            ))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  /// Fetches OpenRouter (always) + Groq (only if key provided) and merges
  /// them into one list. Partial failures don't block the other provider.
  Future<ModelFetchResult> fetchAllModels({String? groqApiKey}) async {
    final errors = <String>[];
    var openRouterModels = <OpenRouterModel>[];
    var groqModels = <OpenRouterModel>[];

    try {
      openRouterModels = await fetchModels();
    } on SettingsServiceException catch (e) {
      errors.add('OpenRouter: ${e.message}');
    } catch (_) {
      errors.add('OpenRouter: could not connect');
    }

    if (groqApiKey != null && groqApiKey.isNotEmpty) {
      try {
        groqModels = await fetchGroqModels(groqApiKey);
      } on SettingsServiceException catch (e) {
        errors.add('Groq: ${e.message}');
      } catch (_) {
        errors.add('Groq: could not connect');
      }
    }

    final combined = [...openRouterModels, ...groqModels]
      ..sort((a, b) {
        if (a.isFree != b.isFree) return a.isFree ? -1 : 1;
        return a.name.compareTo(b.name);
      });

    return ModelFetchResult(models: combined, errors: errors);
  }

  // Returns true only for text-in / text-out models.
  // Includes models whose input is text-only OR text+image,
  // and whose output contains text. This lets Claude, GPT-4o,
  // Gemini etc. appear while still excluding image/audio generators.
  bool _isTextOnlyModel(Map<String, dynamic> model) {
    final arch = model['architecture'];
    if (arch == null) return false;
    final inputMods  = (arch['input_modalities']  as List?) ?? const [];
    final outputMods = (arch['output_modalities'] as List?) ?? const [];

    // Must produce text output.
    if (!outputMods.contains('text')) return false;

    // Must not generate images or audio as output (e.g. DALL-E, TTS).
    if (outputMods.contains('image') || outputMods.contains('audio')) return false;

    // Input must include text (rules out audio-only / image-only inputs).
    if (!inputMods.contains('text')) return false;

    return true;
  }

  // ── Validation ─────────────────────────────────────────────────────────

  Future<ValidationResult> validateApiKey(String apiKey) async {
    try {
      final response = await http.get(
        Uri.parse('https://openrouter.ai/api/v1/key'),
        headers: {'Authorization': 'Bearer $apiKey'},
      );

      return switch (response.statusCode) {
        200 => ValidationResult.valid,
        401 => ValidationResult.invalid,
        _   => ValidationResult.unknown,
      };
    } on http.ClientException {
      return ValidationResult.networkError;
    } catch (_) {
      return ValidationResult.unknown;
    }
  }
}

/// Thrown by [SettingsService.fetchModels] on a non-200 response.
class SettingsServiceException implements Exception {
  SettingsServiceException(this.message);
  final String message;

  @override
  String toString() => message;
}
