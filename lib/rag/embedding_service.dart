import 'dart:convert';
import 'package:http/http.dart' as http;

abstract class EmbeddingService {
  Future<List<double>> embed(String text);
}

/// Google Gemini embedding API — generous free tier, separate key from
/// the OpenRouter key already used for chat completions.
class GeminiEmbeddingService implements EmbeddingService {
  GeminiEmbeddingService(this.apiKey);
  final String apiKey;

  static const _model = 'text-embedding-004';
  static const _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:embedContent';

  @override
  Future<List<double>> embed(String text) async {
    final uri = Uri.parse('$_endpoint?key=$apiKey');
    final response = await http
        .post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'model': 'models/$_model',
        'content': {
          'parts': [
            {'text': text}
          ]
        },
      }),
    )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw EmbeddingException('Embedding failed (${response.statusCode})');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final values = (json['embedding']['values'] as List).cast<num>();
    return values.map((n) => n.toDouble()).toList();
  }
}

/// Placeholder for on-device embeddings (tflite_flutter + a bundled
/// MiniLM/sentence-transformer model). Same interface, so RagService
/// doesn't need to change once this is wired up — just needs a model
/// asset (~25-90MB depending on model) bundled or downloaded on first use.
class LocalEmbeddingService implements EmbeddingService {
  const LocalEmbeddingService();

  @override
  Future<List<double>> embed(String text) {
    throw UnimplementedError(
      'Local embeddings model not bundled yet — see TODO in '
          'embedding_service.dart before enabling this mode.',
    );
  }
}

class EmbeddingException implements Exception {
  EmbeddingException(this.message);
  final String message;
  @override
  String toString() => message;
}