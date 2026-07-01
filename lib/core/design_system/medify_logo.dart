import 'package:flutter/material.dart';

import 'app_colors.dart';

/// In-app recreation of the Medify mark (teal rounded-shield with a capsule
/// glyph) from the Figma file, so the logo needs no image asset and stays
/// theme-consistent. The app *launcher icon* still needs a real PNG exported
/// from Figma (see pubspec.yaml's commented-out flutter_launcher_icons block).
class MedifyLogo extends StatelessWidget {
  const MedifyLogo({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _ShieldCapsulePainter()),
    );
  }
}

class _ShieldCapsulePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final shieldPaint = Paint()..color = AppColors.primary;
    final shieldPath = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height * 0.22)
      ..lineTo(size.width, size.height * 0.55)
      ..cubicTo(
        size.width,
        size.height * 0.85,
        size.width * 0.75,
        size.height,
        size.width / 2,
        size.height,
      )
      ..cubicTo(
        size.width * 0.25,
        size.height,
        0,
        size.height * 0.85,
        0,
        size.height * 0.55,
      )
      ..lineTo(0, size.height * 0.22)
      ..close();
    canvas.drawPath(shieldPath, shieldPaint);

    // Capsule glyph in the center, tilted 45 degrees.
    final capsuleRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.5,
      height: size.height * 0.24,
    );
    canvas.save();
    canvas.translate(capsuleRect.center.dx, capsuleRect.center.dy);
    canvas.rotate(-0.785398); // -45 degrees
    canvas.translate(-capsuleRect.center.dx, -capsuleRect.center.dy);

    final capsulePaint = Paint()..color = Colors.white;
    final rrect = RRect.fromRectAndRadius(
      capsuleRect,
      Radius.circular(capsuleRect.height / 2),
    );
    canvas.drawRRect(rrect, capsulePaint);

    final halfPaint = Paint()..color = AppColors.primary;
    canvas.drawRect(
      Rect.fromLTWH(
        capsuleRect.left,
        capsuleRect.top,
        capsuleRect.width / 2,
        capsuleRect.height,
      ),
      halfPaint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
