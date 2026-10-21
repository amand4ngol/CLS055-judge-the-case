import 'package:flutter/widgets.dart';

/// A tappable area announced as a button to screen readers. The whole box
/// responds to taps, not just its painted pixels.
class TapTarget extends StatelessWidget {
  const TapTarget({
    super.key,
    required this.label,
    required this.child,
    this.onTap,
  });

  final String label;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: child,
      ),
    );
  }
}
