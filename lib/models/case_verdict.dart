import 'enums.dart';
import 'firestore_parsing.dart';
import 'other_measure.dart';
import 'sentence.dart';

/// The court's real decision, read from Firestore `verdicts/{ecli}` after the
/// player delivers a verdict.
class CaseVerdict {
  const CaseVerdict({
    required this.caseId,
    required this.courtRuled,
    required this.sentence,
    required this.otherMeasures,
    required this.actualSentence,
    required this.courtReasoning,
  });

  /// Same ECLI as the [CourtCase].
  final String caseId;

  /// Verdict buttons matching the court's decision ("Court ruled").
  final Set<VerdictOption> courtRuled;
  final Sentence sentence;
  final List<OtherMeasure> otherMeasures;

  /// "Actual sentence".
  final String actualSentence;

  /// "Why the court decided this".
  final String courtReasoning;

  factory CaseVerdict.fromFirestore(String id, Map<String, dynamic> map) => CaseVerdict(
        caseId: id,
        courtRuled: parseStringList(map['courtRuled'])
            .map(VerdictOption.fromValue)
            .whereType<VerdictOption>()
            .toSet(),
        sentence: Sentence.fromMap(parseMap(map['sentence'])),
        otherMeasures: parseMapList(map['otherMeasures']).map(OtherMeasure.fromMap).toList(),
        actualSentence: map['actualSentence'] as String? ?? '',
        courtReasoning: map['courtReasoning'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'courtRuled': courtRuled.map((o) => o.value).toList(),
        'sentence': sentence.toMap(),
        'otherMeasures': otherMeasures.map((m) => m.toMap()).toList(),
        'actualSentence': actualSentence,
        'courtReasoning': courtReasoning,
      };
}
