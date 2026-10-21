import 'dart:convert';

import 'claude_client.dart';

/// Haiku's opinion on whether the texts shown before the verdict give the outcome away.
class LeakVerdict {
  const LeakVerdict({required this.revealsOutcome, required this.reason, required this.costUsd});

  final bool revealsOutcome;
  final String reason;
  final double costUsd;
}

/// Asked only when the word search flags a case, to tell real hints from false alarms.
class LeakJudge {
  LeakJudge(this.claude, {this.model = ClaudeModel.haiku});

  final ClaudeClient claude;
  final ClaudeModel model;

  static const _system = '''
You review cases for "Judge the Case", a game where players read a real criminal case, then guess the court's decision before seeing it.

You receive the texts shown BEFORE the player decides, the court's real decision, and words a simple filter flagged. Say whether the texts reveal or strongly hint at the outcome of this ruling.

It IS revealing:
- stating or implying that the defendant was convicted, acquitted, found guilty or not, or what penalty this court imposed;
- the court's own conclusions on disputed facts;
- in an appeal, what the lower court decided (conviction, acquittal or sentence).

It is NOT revealing:
- what the prosecution or the defence asked for (a demand for months in prison, a request for acquittal);
- the defendant's past convictions or penalties in other cases;
- durations or amounts unrelated to the sentence (a three-hour flight, money stolen).''';

  static const _schema = {
    'type': 'object',
    'additionalProperties': false,
    'required': ['revealsOutcome', 'reason'],
    'properties': {
      'revealsOutcome': {'type': 'boolean'},
      'reason': {'type': 'string'},
    },
  };

  Future<LeakVerdict> judge(Map<String, dynamic> caseJson, List<String> flaggedWords) async {
    final c = caseJson['case'] as Map;
    final v = caseJson['verdict'] as Map;
    final arguments = [for (final a in c['arguments'] as List) '- [${a['side']}] ${a['text']}'];
    final res = await claude.create(
      model: model,
      system: _system,
      messages: [
        {
          'role': 'user',
          'content': 'ECLI: ${caseJson['id']}\n\n'
              'SHOWN BEFORE THE DECISION\nCharges: ${(c['charges'] as List).join('; ')}\n'
              'Short summary: ${c['summaryShort']}\nLong summary: ${c['summaryLong']}\n'
              'Arguments:\n${arguments.join('\n')}\n\n'
              'REAL DECISION\nCourt ruled: ${(v['courtRuled'] as List).join(', ')}\n'
              'Actual sentence: ${v['actualSentence']}\n\n'
              'FLAGGED WORDS: ${flaggedWords.join(', ')}',
        },
      ],
      effort: 'medium',
      schema: _schema,
      maxTokens: 4000,
    );
    final text = res.text;
    final json = jsonDecode(text.substring(text.indexOf('{'), text.lastIndexOf('}') + 1)) as Map<String, dynamic>;
    return LeakVerdict(
      revealsOutcome: json['revealsOutcome'] != false,
      reason: json['reason'] as String? ?? '',
      costUsd: res.costUsd,
    );
  }
}
