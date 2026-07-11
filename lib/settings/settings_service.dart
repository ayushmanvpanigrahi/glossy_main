import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'settings_models.dart';

// ---------------------------------------------------------------------------
// SettingsService
// ---------------------------------------------------------------------------

class SettingsService {
  SettingsService({FlutterSecureStorage? storage})
      : _secureStorage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
            );

  final FlutterSecureStorage _secureStorage;

  static const apiKeyStorageKey    = 'openrouter_api_key';
  static const modelStorageKey     = 'openrouter_model';
  static const embeddingModeKey    = 'rag_embedding_mode';
  static const indexingTriggerKey  = 'rag_indexing_trigger';
  static const embeddingApiKeyKey  = 'gemini_embedding_api_key';
  static const groqApiKeyKey       = 'groq_api_key';
  static const modelProviderKey    = 'model_provider';

  // ── Storage ──────────────────────────────────────────────────────────────

  Future<SavedSettings> loadSavedSettings() async {
    final results = await Future.wait([
      _secureStorage.read(key: apiKeyStorageKey),
      _secureStorage.read(key: modelStorageKey),
      _secureStorage.read(key: groqApiKeyKey),
      _secureStorage.read(key: modelProviderKey),
    ]);
    return SavedSettings(
      apiKey:        results[0],
      modelId:       results[1],
      groqApiKey:    results[2],
      modelProvider: results[3] == 'groq'
          ? ModelProvider.groq
          : ModelProvider.openRouter,
    );
  }

  Future<RagSettings> loadRagSettings() async {
    final results = await Future.wait([
      _secureStorage.read(key: embeddingModeKey),
      _secureStorage.read(key: indexingTriggerKey),
      _secureStorage.read(key: embeddingApiKeyKey),
    ]);
    return RagSettings(
      embeddingMode:  results[0],
      indexingTrigger: results[1],
      embeddingApiKey: results[2],
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

  // ── Save all at once ──────────────────────────────────────────────────────

  Future<void> saveAllSettings({
    required String openRouterKey,
    required String groqKey,
    required String geminiKey,
    required String? modelId,
    required ModelProvider modelProvider,
    required String embeddingMode,
    required String indexingTrigger,
  }) async {
    final ops = <Future<void>>[];

    if (openRouterKey.isEmpty) {
      ops.add(deleteApiKey());
    } else {
      ops.add(saveApiKey(openRouterKey));
    }

    if (groqKey.isEmpty) {
      ops.add(deleteGroqApiKey());
    } else {
      ops.add(saveGroqApiKey(groqKey));
    }

    ops.add(saveEmbeddingApiKey(geminiKey));
    ops.add(saveEmbeddingMode(embeddingMode));
    ops.add(saveIndexingTrigger(indexingTrigger));
    ops.add(saveModelProvider(modelProvider));

    if (modelId != null && modelId.isNotEmpty) {
      ops.add(saveModelId(modelId));
    } else {
      ops.add(deleteModelId());
    }

    await Future.wait(ops);
  }

  // ── Model fetching ────────────────────────────────────────────────────────

  Future<List<OpenRouterModel>> fetchModels() async {
    final response = await http
        .get(Uri.parse('https://openrouter.ai/api/v1/models'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw SettingsServiceException(
          'Failed to load models (${response.statusCode})');
    }

    final modelsJson =
        (jsonDecode(response.body)['data'] as List)
            .cast<Map<String, dynamic>>();

    final textOnly = modelsJson
        .where(_isTextOnlyModel)
        .map(OpenRouterModel.fromJson)
        .toList()
      ..sort((a, b) {
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
        (jsonDecode(response.body)['data'] as List)
            .cast<Map<String, dynamic>>();

    return data
        .where((m) => m['active'] != false)
        .map((m) => OpenRouterModel(
              id:       m['id'] as String? ?? '',
              name:     m['id'] as String? ?? '',
              isFree:   true,
              provider: ModelProvider.groq,
            ))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<ModelFetchResult> fetchAllModels({String? groqApiKey}) async {
    final errors            = <String>[];
    var openRouterModels    = <OpenRouterModel>[];
    var groqModels          = <OpenRouterModel>[];

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

  bool _isTextOnlyModel(Map<String, dynamic> model) {
    final arch = model['architecture'];
    if (arch == null) return false;
    final inputMods  = (arch['input_modalities']  as List?) ?? const [];
    final outputMods = (arch['output_modalities'] as List?) ?? const [];
    if (!outputMods.contains('text')) return false;
    if (outputMods.contains('image') || outputMods.contains('audio')) {
      return false;
    }
    if (!inputMods.contains('text')) return false;
    return true;
  }

  // ── Validation ────────────────────────────────────────────────────────────

  Future<ValidationResult> validateOpenRouterKey(String apiKey) async {
    try {
      final response = await http.get(
        Uri.parse('https://openrouter.ai/api/v1/key'),
        headers: {'Authorization': 'Bearer $apiKey'},
      ).timeout(const Duration(seconds: 8));

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

  Future<ValidationResult> validateGroqKey(String apiKey) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.groq.com/openai/v1/models'),
        headers: {'Authorization': 'Bearer $apiKey'},
      ).timeout(const Duration(seconds: 8));

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

  /// Validates a Gemini API key by calling the embedContent endpoint with a
  /// tiny probe string. Returns valid/invalid/networkError/unknown.
  Future<ValidationResult> validateGeminiKey(String apiKey) async {
    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/'
        'text-embedding-004:embedContent?key=$apiKey',
      );
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': 'models/text-embedding-004',
              'content': {
                'parts': [
                  {'text': 'test'},
                ],
              },
            }),
          )
          .timeout(const Duration(seconds: 10));

      return switch (response.statusCode) {
        200 => ValidationResult.valid,
        400 => ValidationResult.valid,   // bad request but key was accepted
        401 => ValidationResult.invalid,
        403 => ValidationResult.invalid,
        _   => ValidationResult.unknown,
      };
    } on http.ClientException {
      return ValidationResult.networkError;
    } catch (_) {
      return ValidationResult.unknown;
    }
  }

  /// Sends a minimal chat completion to the selected model and returns true
  /// if a non-empty response comes back. Works for both OpenRouter and Groq.
  Future<ModelPingResult> pingModel({
    required String modelId,
    required ModelProvider provider,
    required String apiKey,
  }) async {
    if (apiKey.isEmpty) return ModelPingResult.noKey;

    try {
      final isGroq = provider == ModelProvider.groq;
      final url = Uri.parse(
        isGroq
            ? 'https://api.groq.com/openai/v1/chat/completions'
            : 'https://openrouter.ai/api/v1/chat/completions',
      );

      final response = await http
          .post(
            url,
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type':  'application/json',
            },
            body: jsonEncode({
              'model': modelId,
              'messages': [
                {'role': 'user', 'content': 'Hi'},
              ],
              'max_tokens': 5,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body    = jsonDecode(response.body);
        final content = body['choices']?[0]?['message']?['content'];
        if (content != null && (content as String).isNotEmpty) {
          return ModelPingResult.success;
        }
        return ModelPingResult.emptyResponse;
      }
      if (response.statusCode == 401) return ModelPingResult.unauthorized;
      return ModelPingResult.failed;
    } on http.ClientException {
      return ModelPingResult.networkError;
    } catch (_) {
      return ModelPingResult.failed;
    }
  }

  // Kept for backwards-compat with any existing callers.
  Future<ValidationResult> validateApiKey(String apiKey) =>
      validateOpenRouterKey(apiKey);
}

/// Thrown by [SettingsService.fetchModels] on a non-200 response.
class SettingsServiceException implements Exception {
  SettingsServiceException(this.message);
  final String message;

  @override
  String toString() => message;
}
