// Renders the PLACEHOLDER app icon artwork that the platform launcher icons
// are generated from. Skipped by default; run explicitly, then regenerate
// the Android, iOS and web icons:
//
//   flutter test test/tool/app_icon_test.dart --dart-define=UPDATE_APP_ICON=true
//   dart run flutter_launcher_icons
//
// The artwork is a plain envelope in SokoMail's colours. It is not, and must
// not be turned into, a SokoAerial Robotics logo. When the official artwork
// is supplied, replace the two files in assets/branding/ with it and run
// only the second command (see decisions.md, ADR-019).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sokomail/app/theme/app_colors.dart';

const _enabled = bool.fromEnvironment('UPDATE_APP_ICON');
const _outputDir = 'assets/branding';
const _size = 1024.0;

/// Draws the envelope centred on a [_size] square. With a [background] the
/// result is a full-bleed opaque icon (iOS, web, older Android). Without it
/// the envelope sits on transparency: the Android adaptive foreground and
/// monochrome (themed icon) layers, which only use its shape.
void _paintIcon(Canvas canvas, {Color? background}) {
  const square = Rect.fromLTWH(0, 0, _size, _size);
  if (background != null) {
    canvas.drawRect(square, Paint()..color = background);
  }
  final body = Rect.fromCenter(
    center: square.center,
    width: _size * 0.54,
    height: _size * 0.39,
  );
  const inset = _size * 0.075;
  final flap = Path()
    ..moveTo(body.left + inset, body.top + inset)
    ..lineTo(body.center.dx, body.top + body.height * 0.56)
    ..lineTo(body.right - inset, body.top + inset);

  // The flap is cut out of the envelope, so the same shape works on the
  // green background and as a single-colour themed icon.
  canvas
    ..saveLayer(square, Paint())
    ..drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(_size * 0.055)),
      Paint()..color = AppColors.darkOlive,
    )
    ..drawPath(
      flap,
      Paint()
        ..blendMode = BlendMode.clear
        ..style = PaintingStyle.stroke
        ..strokeWidth = _size * 0.045
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    )
    ..restore();
}

Future<void> _write(String name, {Color? background}) async {
  final recorder = ui.PictureRecorder();
  _paintIcon(Canvas(recorder), background: background);
  final image = await recorder.endRecording().toImage(
    _size.toInt(),
    _size.toInt(),
  );
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  Directory(_outputDir).createSync(recursive: true);
  File('$_outputDir/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
}

void main() {
  test(
    'renders the placeholder app icon artwork',
    () async {
      await _write('app_icon', background: AppColors.deepGreen);
      await _write('app_icon_foreground');
    },
    skip: _enabled ? false : 'Run with --dart-define=UPDATE_APP_ICON=true',
  );
}
