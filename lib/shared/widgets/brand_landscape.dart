import 'package:material_ui/material_ui.dart';
import 'package:sokomail/app/theme/app_colors.dart';

/// Decorative ridge-line landscape with a small quadcopter, drawn in flat
/// tones of the deep-green brand surface.
///
/// For branded areas only (sidebar footer, drawer footer, sign-in panel),
/// never behind message content. It is drawn in code (no image assets) and
/// is not a logo.
class BrandLandscape extends StatelessWidget {
  const BrandLandscape({super.key, this.height = 120, this.showDrone = true});

  final double height;
  final bool showDrone;

  @override
  Widget build(BuildContext context) {
    final brand = context.brandColors;
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _LandscapePainter(
            base: brand.header,
            tone: brand.onHeader,
            accent: brand.headerAccent,
            showDrone: showDrone,
          ),
        ),
      ),
    );
  }
}

class _LandscapePainter extends CustomPainter {
  const _LandscapePainter({
    required this.base,
    required this.tone,
    required this.accent,
    required this.showDrone,
  });

  final Color base;
  final Color tone;
  final Color accent;
  final bool showDrone;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Three ridge layers, farthest first, each a little more opaque.
    void ridge(List<Offset> peaks, double alpha, {Color? colour}) {
      final path = Path()..moveTo(0, h);
      path.lineTo(0, peaks.first.dy * h);
      for (var i = 1; i < peaks.length; i++) {
        final prev = peaks[i - 1];
        final next = peaks[i];
        final midX = (prev.dx + next.dx) / 2 * w;
        path.cubicTo(
          midX,
          prev.dy * h,
          midX,
          next.dy * h,
          next.dx * w,
          next.dy * h,
        );
      }
      path
        ..lineTo(w, h)
        ..close();
      canvas.drawPath(
        path,
        Paint()..color = (colour ?? tone).withValues(alpha: alpha),
      );
    }

    ridge(const [
      Offset(0, 0.55),
      Offset(0.22, 0.32),
      Offset(0.45, 0.5),
      Offset(0.7, 0.28),
      Offset(1, 0.48),
    ], 0.06);
    ridge(const [
      Offset(0, 0.7),
      Offset(0.28, 0.52),
      Offset(0.55, 0.66),
      Offset(0.8, 0.5),
      Offset(1, 0.62),
    ], 0.09);
    ridge(
      const [
        Offset(0, 0.86),
        Offset(0.3, 0.74),
        Offset(0.62, 0.84),
        Offset(1, 0.72),
      ],
      0.14,
      colour: accent,
    );

    if (showDrone) _drone(canvas, Offset(w * 0.62, h * 0.24));
  }

  /// Side view of a small quadcopter.
  void _drone(Canvas canvas, Offset centre) {
    final paint = Paint()..color = tone.withValues(alpha: 0.55);
    final thin = Paint()
      ..color = tone.withValues(alpha: 0.45)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    // Body.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: centre, width: 18, height: 6),
        const Radius.circular(3),
      ),
      paint,
    );
    // Arms.
    canvas.drawLine(centre.translate(-16, -1), centre.translate(16, -1), thin);
    // Rotors.
    for (final dx in [-16.0, 16.0]) {
      canvas
        ..drawLine(centre.translate(dx, -1), centre.translate(dx, -4), thin)
        ..drawLine(
          centre.translate(dx - 7, -4.5),
          centre.translate(dx + 7, -4.5),
          thin,
        );
    }
    // Landing legs.
    canvas
      ..drawLine(centre.translate(-5, 3), centre.translate(-8, 7), thin)
      ..drawLine(centre.translate(5, 3), centre.translate(8, 7), thin);
  }

  @override
  bool shouldRepaint(_LandscapePainter oldDelegate) =>
      oldDelegate.base != base ||
      oldDelegate.tone != tone ||
      oldDelegate.accent != accent ||
      oldDelegate.showDrone != showDrone;
}
