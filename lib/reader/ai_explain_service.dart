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
  static const _endpoint = 'https://openrouter.ai/api/v1/chat/completions';

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

    final response = await http
        .post(
          Uri.parse(endpoint),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': modelId,
            'messages': [
              {'role': 'system', 'content': _explainSystemPrompt},
              {
                'role': 'user',
                'content':
                    'Page context:\n$surroundingPageText\n\nSelected passage:\n"$selectedText"',
              },
            ],
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw AiExplainException('Explain failed (${response.statusCode})');
    }

    final clean = _extractContent(
      response.body,
    ).replaceAll(RegExp(r'```json|```'), '').trim();
    return ExplainResult.fromJson(jsonDecode(clean) as Map<String, dynamic>);
  }

  /// Follow-up question inside an active explain session. Pulls extra
  /// context from the whole-book RAG index (not just the current page)
  /// so questions like "iska baaki book se connection kya hai" work too.
  Future<String> askFollowUp({
    required String bookId,
    required String selectedText,
    required List<ChatTurn> history,
    required String question,
  }) async {
    final saved = await _settingsService.loadSavedSettings();
    final apiKey = saved.apiKey;
    final modelId = saved.modelId;
    if (apiKey == null || apiKey.isEmpty || modelId == null) {
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
          ragContext = await ragService.retrieveContext(
            question,
            bookId: bookId,
          );
        }
      }
    } catch (_) {
      // Best-effort — a RAG lookup failure shouldn't block the follow-up
      // from still getting an answer using page-level context alone.
    }

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

    final response = await http
        .post(
          Uri.parse(_endpoint),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'model': modelId, 'messages': messages}),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw AiExplainException('Follow-up failed (${response.statusCode})');
    }
    return _extractContent(response.body);
  }

  (String, String?) _resolveEndpoint(
      ({
        String? apiKey,
        String? modelId,
        String? groqApiKey,
        ModelProvider modelProvider
      }) saved) {
    return saved.modelProvider == ModelProvider.groq
        ? ('https://api.groq.com/openai/v1/chat/completions', saved.groqApiKey)
        : (_endpoint, saved.apiKey);
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
}

class AiExplainException implements Exception {
  AiExplainException(this.message);
  final String message;
  @override
  String toString() => message;
}
