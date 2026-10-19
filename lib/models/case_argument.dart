import 'enums.dart';

/// One swipeable "key argument" card.
class CaseArgument {
  const CaseArgument({required this.side, required this.text});

  final ArgumentSide side;
  final String text;

  factory CaseArgument.fromMap(Map<String, dynamic> map) => CaseArgument(
        side: ArgumentSide.fromValue(map['side'] as String?),
        text: map['text'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {'side': side.value, 'text': text};
}
