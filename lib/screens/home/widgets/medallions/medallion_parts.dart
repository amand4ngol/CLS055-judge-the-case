import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_svg.dart';

/// Size of the completed and locked medallions (the next-case one is 120).
const double kMedallionSize = 101.52;

/// Width of the light ring around the completed and locked medallions.
const double kMedallionRing = 6.542;

class InsetBottomShadowPainter extends CustomPainter {
  const InsetBottomShadowPainter(this.color, this.depth);

  final Color color;
  final double depth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final outer = Path()..addOval(rect);
    final inner = Path()..addOval(rect.shift(Offset(0, -depth)));
    canvas.drawPath(
      Path.combine(PathOperation.difference, outer, inner),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(InsetBottomShadowPainter old) =>
      old.color != color || old.depth != depth;
}

/// The case label stacked above an icon, centered inside a medallion.
class MedallionContent extends StatelessWidget {
  const MedallionContent({
    super.key,
    required this.label,
    required this.labelStyle,
    required this.icon,
  });

  final String label;
  final TextStyle labelStyle;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 1.88),
        icon,
      ],
    );
  }
}

class MedallionIcon extends StatelessWidget {
  const MedallionIcon({
    super.key,
    required this.assetPath,
    required this.fallbackIcon,
    required this.fallbackColor,
    required this.box,
    required this.offset,
    required this.size,
  });

  final String assetPath;
  final IconData fallbackIcon;
  final Color fallbackColor;
  final Size box;
  final Offset offset;
  final Size size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: box.width,
      height: box.height,
      alignment: Alignment.topLeft,
      padding: EdgeInsets.only(left: offset.dx, top: offset.dy),
      child: SizedBox.fromSize(
        size: size,
        child: AppSvg(
          assetPath,
          excludeFromSemantics: true,
          fallback: FittedBox(child: Icon(fallbackIcon, color: fallbackColor)),
        ),
      ),
    );
  }
}
