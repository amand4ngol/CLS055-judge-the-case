import 'dart:convert';

import 'package:http/http.dart' as http;

/// A model the pipeline can call, with its prices in dollars per million tokens.
class ClaudeModel {
  const ClaudeModel(this.id, this.inputPrice, this.outputPrice, this.cacheReadPrice, {this.serverFallback = true});

  final String id;
  final double inputPrice;
  final double outputPrice;
  final double cacheReadPrice;

  /// Opus and Sonnet can retry a refused request on another model server-side; Haiku cannot.
  final bool serverFallback;

  double get cacheWritePrice => inputPrice * 1.25;

  static const opus = ClaudeModel('claude-opus-5-5', 4, 20, 0.20);
  static const sonnet = ClaudeModel('claude-sonnet-5-5', 2, 10, 0.20);
  static const haiku = ClaudeModel('claude-haiku-5-5', 0.10, 0.50, 0.01, serverFallback: false);
  static const all = [opus, sonnet, haiku];

  static ClaudeModel? byId(String id) => all.where((m) => m.id == id).firstOrNull;
}

/// Result of one Messages API call.
class ClaudeResponse {
  ClaudeResponse({
    required this.text,
    required this.content,
    required this.model,
    required this.stopReason,
    required this.costUsd,
  });

  /// Concatenated text blocks (thinking blocks excluded).
  final String text;

  /// Raw content blocks, sent back unchanged when asking for a correction.
  final List<dynamic> content;
  final String model;
  final String? stopReason;
  final double costUsd;
}

/// Raw HTTP client for the Claude Messages API (Dart has no official SDK). The key stays in memory.
class ClaudeClient {
  ClaudeClient({required this.apiKey, http.Client? client, this.retryDelay = const Duration(seconds: 5)})
      : _client = client ?? http.Client();

  final String apiKey;
  final http.Client _client;
  final Duration retryDelay;

  /// Number of requests sent, retries included.
  int calls = 0;

  /// Sends one request. The system prompt is cached; [schema] constrains the answer to JSON.
  Future<ClaudeResponse> create({
    required ClaudeModel model,
    required String system,
    required List<Map<String, dynamic>> messages,
    String effort = 'high',
    bool thinking = true,
    Map<String, dynamic>? schema,
    int maxTokens = 16000,
  }) async {
    final body = jsonEncode({
      'model': model.id,
      'max_tokens': maxTokens,
      'system': [
        {'type': 'text', 'text': system, 'cache_control': {'type': 'ephemeral'}},
      ],
      'messages': messages,
      'thinking': {'type': thinking ? 'adaptive' : 'disabled'},
      'output_config': {
        'effort': effort,
        if (schema != null) 'format': {'type': 'json_schema', 'schema': schema},
      },
      if (model.serverFallback) 'fallbacks': 'default',
    });
    final headers = {
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
      if (model.serverFallback) 'anthropic-beta': 'server-side-fallback-2026-07-01',
      'content-type': 'application/json',
    };

    for (var attempt = 1;; attempt++) {
      calls++;
      http.Response res;
      try {
        res = await _client
            .post(Uri.parse('https://api.anthropic.com/v1/messages'), headers: headers, body: body)
            .timeout(const Duration(minutes: 10));
      } on Exception {
        if (attempt >= 3) rethrow;
        await Future<void>.delayed(retryDelay * attempt);
        continue;
      }
      final retryable = res.statusCode == 429 || res.statusCode >= 500;
      if (retryable && attempt < 3) {
        await Future<void>.delayed(retryDelay * attempt);
        continue;
      }
      final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      if (res.statusCode != 200) {
        final err = json['error'] as Map<String, dynamic>?;
        throw Exception('Claude HTTP ${res.statusCode} : ${err?['type']} ${err?['message']}');
      }
      return _parse(json, model);
    }
  }

  static ClaudeResponse _parse(Map<String, dynamic> json, ClaudeModel requested) {
    final content = json['content'] as List<dynamic>;
    final usage = json['usage'] as Map<String, dynamic>? ?? const {};
    int tokens(String key) => (usage[key] as num?)?.toInt() ?? 0;
    final modelId = json['model'] as String? ?? requested.id;
    final m = ClaudeModel.byId(modelId) ?? requested;
    final cost = (tokens('input_tokens') * m.inputPrice +
            tokens('cache_creation_input_tokens') * m.cacheWritePrice +
            tokens('cache_read_input_tokens') * m.cacheReadPrice +
            tokens('output_tokens') * m.outputPrice) /
        1e6;
    return ClaudeResponse(
      text: content
          .whereType<Map<String, dynamic>>()
          .where((b) => b['type'] == 'text')
          .map((b) => b['text'] as String)
          .join(),
      content: content,
      model: modelId,
      stopReason: json['stop_reason'] as String?,
      costUsd: cost,
    );
  }
}
