import 'dart:convert';

import 'package:judge_the_case/models.dart';

import 'claude_client.dart';

/// What the cheap first pass decided about a ruling.
class Classification {
  const Classification({required this.category, required this.usable, required this.reason, required this.costUsd});

  final CaseCategory category;

  /// A criminal judgment on the merits that the game can use.
  final bool usable;
  final String reason;
  final double costUsd;
}

/// Sorts rulings with Haiku from their summary, before paying for the full analysis.
class RulingClassifier {
  RulingClassifier(this.claude, {this.model = ClaudeModel.haiku});

  final ClaudeClient claude;
  final ClaudeModel model;

  static const _system = '''
You sort Dutch criminal court rulings (Rechtspraak) for "Judge the Case", a game where players read a real criminal case and guess the sentence.

From the ruling's title and summary or opening text, return:
- usable: true only for a criminal judgment on the merits, where the court decides guilt and a sentence or an acquittal. False for procedural decisions, appeals declared inadmissible, confiscation-only orders (ontnemingsvordering), raadkamer decisions, Advocate General opinions, and anything that is not criminal.
- category: the best match for the main (most serious) charge:
  "homicide": murder, manslaughter, attempts, death by negligence outside traffic.
  "violence": assault, threats, stalking, kidnapping, robbery with violence, human trafficking.
  "sexual_offences": rape, sexual assault, child sexual abuse material.
  "theft": theft, burglary, receiving stolen goods, extortion.
  "fraud": scams, phishing, forgery, benefit fraud.
  "financial": money laundering, tax fraud, embezzlement, bribery, insider trading, bankruptcy fraud.
  "drugs": Opium Act offences, cannabis farms, drug trafficking.
  "traffic": Road Traffic Act offences, including death or injury caused by driving and drink-driving.
  "weapons": Weapons and Ammunition Act, explosives.
  "cybercrime": hacking, computer intrusion, ransomware, DDoS.
  "environmental": environment, waste, pollution, nature and animal welfare offences.
  "public_order": vandalism, arson, rioting, resisting or insulting officers.
  "other": anything else.
- reason: a few words explaining the choice.''';

  static final _schema = {
    'type': 'object',
    'additionalProperties': false,
    'required': ['usable', 'category', 'reason'],
    'properties': {
      'usable': {'type': 'boolean'},
      'category': {
        'enum': [for (final c in CaseCategory.values) c.value],
      },
      'reason': {'type': 'string'},
    },
  };

  Future<Classification> classify({required String ecli, required String title, required String text}) async {
    final res = await claude.create(
      model: model,
      system: _system,
      messages: [
        {'role': 'user', 'content': 'ECLI: $ecli\nTitle: $title\n\n$text'},
      ],
      effort: 'low',
      thinking: false,
      schema: _schema,
      maxTokens: 1024,
    );
    final json = _decode(res.text);
    return Classification(
      category: CaseCategory.fromValue(json['category'] as String?),
      usable: json['usable'] == true,
      reason: json['reason'] as String? ?? '',
      costUsd: res.costUsd,
    );
  }

  static Map<String, dynamic> _decode(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end <= start) throw FormatException('Unreadable pre-sort answer: $text');
    return Map<String, dynamic>.from(jsonDecode(text.substring(start, end + 1)) as Map);
  }
}
