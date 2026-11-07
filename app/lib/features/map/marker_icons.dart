import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:kakao_map_sdk/kakao_map_sdk.dart' as km;

/// Asset fayl kerak bo'lmasligi uchun marker (pin) rasmini runtime'da chizamiz.
/// Native SDK [width]/[height] ni dp sifatida qabul qiladi, shuning uchun
/// bitmap'ni 3x o'lchamda chizamiz — har qanday ekranda tiniq chiqadi.
class MarkerIcons {
  MarkerIcons._();

  static const double width = 36;
  static const double height = 46;
  static const double _scale = 3;

  static final Map<String, Future<km.KImage>> _cache = {};

  static Future<km.KImage> pin(Color color, IconData icon, {bool selected = false}) {
    final key = '${color.toARGB32()}-${icon.codePoint}-$selected';
    return _cache[key] ??= _draw(color, icon, selected);
  }

  /// "Men shu yerdaman": ko'k nuqta + oq halqa + yumshoq halo. Markazdan bog'lanadi (anchor 0.5, 0.5).
  static Future<km.KImage> myLocation(Color color) => _cache['me-${color.toARGB32()}'] ??= _drawMe(color);

  static Future<km.KImage> _drawMe(Color color) async {
    const size = 34.0;
    final s = size * _scale;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final c = Offset(s / 2, s / 2);
    canvas.drawCircle(c, s / 2, Paint()..color = color.withValues(alpha: 0.18));
    canvas.drawCircle(c, s * 0.27, Paint()..color = Colors.black.withValues(alpha: 0.18));
    canvas.drawCircle(c, s * 0.25, Paint()..color = Colors.white);
    canvas.drawCircle(c, s * 0.18, Paint()..color = color);
    final image = await recorder.endRecording().toImage(s.round(), s.round());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return km.KImage.fromData(bytes!.buffer.asUint8List(), size.round(), size.round());
  }

  static Future<km.KImage> _draw(Color color, IconData icon, bool selected) async {
    final w = width * _scale, h = height * _scale;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final r = w / 2;

    // Soya
    canvas.drawCircle(Offset(r, h - 3 * _scale), 3 * _scale, Paint()..color = Colors.black.withValues(alpha: 0.25));

    // Pin shakli: doira + pastga uchli
    final path = Path()
      ..addOval(Rect.fromCircle(center: Offset(r, r), radius: r - _scale))
      ..moveTo(r - r * 0.55, r + r * 0.6)
      ..lineTo(r, h - 4 * _scale)
      ..lineTo(r + r * 0.55, r + r * 0.6)
      ..close();
    canvas.drawPath(path, Paint()..color = selected ? Colors.black : Colors.white);
    canvas.drawCircle(Offset(r, r), r - 4 * _scale, Paint()..color = color);

    // Ikonka
    final tp = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: r * 1.05,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.white,
        ),
      )
      ..layout();
    tp.paint(canvas, Offset(r - tp.width / 2, r - tp.height / 2));

    final image = await recorder.endRecording().toImage(w.round(), h.round());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return km.KImage.fromData(bytes!.buffer.asUint8List(), width.round(), height.round());
  }
}
