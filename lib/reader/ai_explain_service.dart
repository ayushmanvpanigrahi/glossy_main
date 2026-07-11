import 'dart:convert';
import 'package:http/http.dart' as http;
import '../settings/settings_service.dart';
import '../settings/settings_models.dart';
import '../rag/rag_service.dart';
import '../rag/embedding_service.dart';

class ExplainResult {
  const ExplainResult({
    required this.coreMeaning,
    required this.context,
    required this.example,
  });

  final String coreMeaning;
  final String context;
  final String example;

  factory ExplainResult.fromJson(Map<String, dynamic> json) => ExplainResult(
    coreMeaning: json['coreMeaning'] as String? ?? '',
    context: json['context'] as String? ?? '',
    example: json['example'] as String? ?? '',
  );
}

class ChatTurn {
  const ChatTurn({required this.role, required this.content});
  final String role; // 'user' | 'assistant'
  final String content;
}

class AiExplainService {
  AiExplainService({SettingsService? settingsService})
      : _settingsService = settingsService ?? SettingsService();

  final SettingsService _settingsService;
  static const _openRouterEndpoint = 'https://openrouter.ai/api/v1/chat/completions';
  static const _groqEndpoint = 'https://api.groq.com/openai/v1/chat/completions';

  static const _explainSystemPrompt = '''
You are Glossy AI, embedded in a book reader app. The user selected a
passage and wants a Hinglish (Hindi in Roman script mixed with English)
explanation.

Respond ONLY with a JSON object, no markdown fences, no preamble:
{"coreMeaning": "...", "context": "...", "example": "..."}

- coreMeaning: 1-2 short sentences restating the passage's meaning, in Hinglish.
- context: 1-2 sentences on how it fits the book's broader argument, in Hinglish.
- example: a short relatable real-life example, in Hinglish.
''';

  Future<ExplainResult> explain({
    required String selectedText,
    required String surroundingPageText,
  }) async {
    final saved = await _settingsService.loadSavedSettings();
    final modelId = saved.modelId;
    if (modelId == null) {
      throw AiExplainException('AI provider not configured yet.');
    }

    final (endpoint, apiKey) = _resolveEndpoint(saved);
    if (apiKey == null || apiKey.isEmpty) {
      throw AiExplainException('AI provider not configured yet.');
    }

    final messages = [
      {'role': 'system', 'content': _explainSystemPrompt},
      {
        'role': 'user',
        'content':
        'Page context:\n$surroundingPageText\n\nSelected passage:\n"$selectedText"',
      },
    ];

    // Ask for strict JSON mode first. Not every model/provider supports
    // response_format, so if the provider rejects the param (HTTP 400
    // mentioning it), retry once without it rather than failing outright.
    var response = await _postWithRetry(
      endpoint,
      apiKey,
      {'model': modelId, 'messages': messages, 'response_format': {'type': 'json_object'}},
    );

    if (response.statusCode == 400 && response.body.contains('response_format')) {
      response = await _postWithRetry(
        endpoint,
        apiKey,
        {'model': modelId, 'messages': messages},
      );
    }

    if (response.statusCode != 200) {
      throw AiExplainException('Explain failed (${response.statusCode})');
    }

    final raw = _extractContent(response.body);
    return ExplainResult.fromJson(_parseJsonLoosely(raw));
  }

  /// Follow-up question inside an active explain session. Pulls extra
  /// context from the whole-book RAG index (not just the current page)
  /// so questions like "iska baaki book se connection kya hai" work too.
  ///
  /// FIX: this previously ALWAYS used the OpenRouter endpoint + `saved.apiKey`
  /// regardless of which provider the user had configured. If someone set up
  /// Groq only (no OpenRouter key), every follow-up failed instantly with
  /// "AI provider not configured yet" — which is exactly the silent
  /// "follow-up kaam nahi kar raha" bug reported. Now uses the same
  /// _resolveEndpoint() logic as explain().
  Future<String> askFollowUp({
    required String bookId,
    required String selectedText,
    required List<ChatTurn> history,
    required String question,
    void Function(bool ragUsed)? onRagStatus,
  }) async {
    final saved = await _settingsService.loadSavedSettings();
    final modelId = saved.modelId;
    if (modelId == null) {
      throw AiExplainException('AI provider not configured yet.');
    }

    final (endpoint, apiKey) = _resolveEndpoint(saved);
    if (apiKey == null || apiKey.isEmpty) {
      throw AiExplainException('AI provider not configured yet.');
    }

    var ragContext = '';
    try {
      final ragSettings = await _settingsService.loadRagSettings();
      final embeddingApiKey = ragSettings.embeddingApiKey;
      if ((ragSettings.embeddingMode ?? 'api') == 'api' &&
          embeddingApiKey != null &&
          embeddingApiKey.isNotEmpty) {
        final ragService = RagService(
          embeddingService: GeminiEmbeddingService(embeddingApiKey),
        );
        if (await ragService.isIndexed(bookId)) {
          ragContext = await ragService.retrieveContext(question, bookId: bookId);
        }
      }
    } catch (_) {
      // Best-effort — a RAG lookup failure shouldn't block the follow-up
      // from still getting an answer using page-level context alone.
    }
    onRagStatus?.call(ragContext.isNotEmpty);

    final messages = [
      {
        'role': 'system',
        'content':
        'You are Glossy AI, helping a reader understand a book. Reply '
            'in Hinglish, briefly. The reader selected this passage: '
            '"$selectedText".'
            '${ragContext.isNotEmpty ? '\n\nRelevant excerpts from elsewhere in the book:\n$ragContext' : ''}',
      },
      for (final turn in history) {'role': turn.role, 'content': turn.content},
      {'role': 'user', 'content': question},
    ];

    final response = await _postWithRetry(
      endpoint,
      apiKey,
      {'model': modelId, 'messages': messages},
    );

    if (response.statusCode != 200) {
      throw AiExplainException('Follow-up failed (${response.statusCode})');
    }
    return _extractContent(response.body);
  }

  /// POST with a single automatic retry on HTTP 429 (rate limit) — common
  /// with OpenRouter's free-tier models. Honors a `Retry-After` header if
  /// the provider sends one, otherwise waits a fixed short delay.
  Future<http.Response> _postWithRetry(
      String endpoint,
      String apiKey,
      Map<String, dynamic> body, {
        int maxRetries = 1,
      }) async {
    for (var attempt = 0; ; attempt++) {
      final response = await http
          .post(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 429 && attempt < maxRetries) {
        final retryAfter = int.tryParse(response.headers['retry-after'] ?? '');
        await Future.delayed(Duration(seconds: retryAfter ?? 2));
        continue;
      }
      return response;
    }
  }

  (String, String?) _resolveEndpoint(SavedSettings saved) {
    return saved.modelProvider == ModelProvider.groq
        ? (_groqEndpoint, saved.groqApiKey)
        : (_openRouterEndpoint, saved.apiKey);
  }

  String _extractContent(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;

    // Some providers return HTTP 200 but still embed an error object —
    // catch that before assuming the success shape.
    if (json['error'] != null) {
      final err = json['error'];
      final msg = err is Map ? (err['message']?.toString() ?? err.toString()) : err.toString();
      throw AiExplainException('Provider error: $msg');
    }

    final choices = json['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw AiExplainException('No response from model — try again or switch models.');
    }

    final message = choices.first['message'] as Map<String, dynamic>?;
    final content = message?['content'] as String?;
    if (content == null || content.trim().isEmpty) {
      throw AiExplainException('Model returned an empty response.');
    }

    return content.trim();
  }

  /// Strips markdown fences and, if the model still wrapped the JSON in
  /// stray prose, pulls out the first {...} block before parsing — some
  /// smaller/free models (like llama-3.2-3b) don't always respect
  /// "no preamble" instructions perfectly.
  Map<String, dynamic> _parseJsonLoosely(String raw) {
    final clean = raw.replaceAll(RegExp(r'```json|```'), '').trim();
    try {
      return jsonDecode(clean) as Map<String, dynamic>;
    } catch (_) {
      final match = RegExp(r'\{[\s\S]*\}').firstMatch(clean);
      if (match != null) {
        try {
          return jsonDecode(match.group(0)!) as Map<String, dynamic>;
        } catch (_) {
          // fall through
        }
      }
      throw AiExplainException('Model returned an unexpected format — try again.');
    }
  }
}

class AiExplainException implements Exception {
  AiExplainException(this.message);
  final String message;
  @override
  String toString() => message;
}