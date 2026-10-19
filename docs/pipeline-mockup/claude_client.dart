import 'dart:convert';

import 'package:http/http.dart' as http;

/// A model the mock-up can call, with its price per million tokens (USD).
class ClaudeModel {
  const ClaudeModel(this.id, this.label, this.inputPrice, this.outputPrice, {this.adaptive = true});

  final String id;
  final String label;
  final double inputPrice;
  final double outputPrice;

  /// Current models take adaptive thinking + effort; Haiku 4.5 does not.
  final bool adaptive;

  static const all = [
    ClaudeModel('claude-opus-5-5', 'Opus 5.5', 4, 20),
    ClaudeModel('claude-sonnet-5-5', 'Sonnet 5.5', 2, 10),
    ClaudeModel('claude-haiku-4-5', 'Haiku 4.5', 1, 5, adaptive: false),
  ];
}

/// Result of one Messages API call.
class ClaudeResponse {
  ClaudeResponse({
    required this.text,
    required this.content,
    required this.model,
    required this.stopReason,
    required this.inputTokens,
    required this.outputTokens,
  });

  /// Concatenated text blocks (thinking blocks excluded).
  final String text;

  /// Raw content blocks, sent back unchanged when we ask for a correction.
  final List<dynamic> content;
  final String model;
  final String? stopReason;
  final int inputTokens;
  final int outputTokens;
}

/// Raw HTTP client for the Claude Messages API (Dart has no official SDK).
/// The API key is only held in memory.
class ClaudeClient {
  ClaudeClient({required this.apiKey, http.Client? client}) : _client = client ?? http.Client();

  final String apiKey;
  final http.Client _client;

  Future<ClaudeResponse> create({
    required ClaudeModel model,
    required String system,
    required List<Map<String, dynamic>> messages,
    String effort = 'medium',
    int maxTokens = 16000,
  }) async {
    final body = <String, dynamic>{
      'model': model.id,
      'max_tokens': maxTokens,
      'system': system,
      'messages': messages,
      if (model.adaptive) 'thinking': {'type': 'adaptive'},
      if (model.adaptive) 'output_config': {'effort': effort},
      // If a safety classifier declines, retry server-side on the recommended model.
      if (model.adaptive) 'fallbacks': 'default',
    };
    final res = await _client
        .post(
          Uri.parse('https://api.anthropic.com/v1/messages'),
          headers: {
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
            if (model.adaptive) 'anthropic-beta': 'server-side-fallback-2026-07-01',
            'content-type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(minutes: 10));

    final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      final err = json['error'] as Map<String, dynamic>?;
      throw Exception('Claude HTTP ${res.statusCode}: ${err?['type']} ${err?['message']}');
    }
    final content = json['content'] as List<dynamic>;
    final text = content
        .whereType<Map<String, dynamic>>()
        .where((b) => b['type'] == 'text')
        .map((b) => b['text'] as String)
        .join();
    final usage = json['usage'] as Map<String, dynamic>? ?? const {};
    return ClaudeResponse(
      text: text,
      content: content,
      model: json['model'] as String? ?? model.id,
      stopReason: json['stop_reason'] as String?,
      inputTokens: (usage['input_tokens'] as num?)?.toInt() ?? 0,
      outputTokens: (usage['output_tokens'] as num?)?.toInt() ?? 0,
    );
  }
}
