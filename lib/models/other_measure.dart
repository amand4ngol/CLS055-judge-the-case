import 'enums.dart';

/// A penalty or measure with no verdict button (driving ban, compensation…).
class OtherMeasure {
  const OtherMeasure({required this.type, required this.label});

  final MeasureType type;

  /// Text from the pipeline, e.g. "3-year driving ban, 1 year suspended".
  final String label;

  factory OtherMeasure.fromMap(Map<String, dynamic> map) => OtherMeasure(
        type: MeasureType.fromValue(map['type'] as String?),
        label: map['label'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {'type': type.value, 'label': label};
}
