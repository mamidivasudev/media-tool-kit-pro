import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';

import 'ffmpeg_service.dart';
import 'image_service.dart';

/// Where a watermark sits on the picture.
enum WatermarkPosition {
  topLeft('Top left'),
  topCenter('Top'),
  topRight('Top right'),
  centerLeft('Left'),
  center('Center'),
  centerRight('Right'),
  bottomLeft('Bottom left'),
  bottomCenter('Bottom'),
  bottomRight('Bottom right');

  final String label;
  const WatermarkPosition(this.label);
}

/// How the collage cells are arranged.
enum CollageLayout {
  horizontal('Side by side', 0),
  vertical('Stacked', 1),
  grid2('Grid, 2 columns', 2),
  grid3('Grid, 3 columns', 3);

  final String label;
  final int columns; // 0 = one row, 1 = one column
  const CollageLayout(this.label, this.columns);
}

/// Picture drawing done with Flutter's canvas. All inputs are expected to be
/// already normalised (see [ImageService.normalize]).
class ImageCanvas {
  ImageCanvas._();

  /// Normalises [path] with FFmpeg and decodes it.
  /// The temporary file is removed again.
  static Future<ui.Image> load(String path, {int maxSide = 4096}) async {
    final isPng = ImageFormat.of(path) != ImageFormat.jpg;
    final tmp =
        await ImageService.instance.tempPath(isPng ? 'png' : 'jpg', 'norm');
    try {
      final ok = await ImageService.instance
          .normalize(input: path, output: tmp, maxSide: maxSide);
      if (!ok) {
        throw StateError(FFmpegService.instance.lastError.isNotEmpty
            ? FFmpegService.instance.lastError
            : 'Could not read the image.');
      }
      final codec =
          await ui.instantiateImageCodec(await File(tmp).readAsBytes());
      final frame = await codec.getNextFrame();
      return frame.image;
    } finally {
      await File(tmp).delete().catchError((_) => File(tmp));
    }
  }

  static Future<void> writePng(ui.Image image, String path) async {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) throw StateError('Could not encode the image.');
    await File(path).writeAsBytes(data.buffer.asUint8List(), flush: true);
  }

  /// Draws a text and/or a logo on [base] and returns a PNG file path.
  static Future<String> watermark({
    required ui.Image base,
    String text = '',
    ui.Image? logo,
    required WatermarkPosition position,
    required double size, // fraction of the shorter side, 0.02 to 0.3
    required double opacity,
    required Color color,
    bool repeat = false,
  }) async {
    final w = base.width.toDouble(), h = base.height.toDouble();
    final shortSide = math.min(w, h);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImage(base, Offset.zero, Paint());

    final margin = shortSide * 0.03;
    final items = <_Mark>[];

    if (text.trim().isNotEmpty) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: color.withValues(alpha: opacity),
            fontSize: shortSide * size,
            fontWeight: FontWeight.w700,
            shadows: [
              Shadow(
                color: const Color(0xFF000000).withValues(alpha: opacity * 0.6),
                blurRadius: shortSide * size * 0.12,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
      )..layout(maxWidth: w - margin * 2);
      items.add(_Mark(painter.width, painter.height, (c, o) {
        painter.paint(c, o);
      }));
    }

    if (logo != null) {
      final target = shortSide * size * 2.2;
      final scale = target / math.max(logo.width, logo.height);
      final lw = logo.width * scale, lh = logo.height * scale;
      items.add(_Mark(lw, lh, (c, o) {
        c.drawImageRect(
          logo,
          Rect.fromLTWH(0, 0, logo.width.toDouble(), logo.height.toDouble()),
          Rect.fromLTWH(o.dx, o.dy, lw, lh),
          Paint()
            ..color = Color.fromRGBO(255, 255, 255, opacity)
            ..filterQuality = FilterQuality.high,
        );
      }));
    }

    if (items.isNotEmpty) {
      if (repeat) {
        _drawTiled(canvas, items, w, h, shortSide);
      } else {
        // Stack the text and the logo vertically at the chosen position.
        final gap = shortSide * 0.01;
        final blockW = items.map((i) => i.w).reduce(math.max);
        final blockH =
            items.fold<double>(0, (s, i) => s + i.h) + gap * (items.length - 1);
        final origin = _origin(position, w, h, blockW, blockH, margin);
        var y = origin.dy;
        for (final item in items) {
          final x = origin.dx + (blockW - item.w) / 2;
          item.draw(canvas, Offset(x, y));
          y += item.h + gap;
        }
      }
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(base.width, base.height);
    final out = await ImageService.instance.tempPath('png', 'wm');
    await writePng(image, out);
    image.dispose();
    return out;
  }

  static void _drawTiled(
      Canvas canvas, List<_Mark> items, double w, double h, double shortSide) {
    final item = items.first;
    final stepX = item.w + shortSide * 0.25;
    final stepY = item.h + shortSide * 0.25;
    canvas.save();
    canvas.translate(w / 2, h / 2);
    canvas.rotate(-math.pi / 8);
    canvas.translate(-w / 2, -h / 2);
    final extra = math.max(w, h) * 0.5;
    var row = 0;
    for (var y = -extra; y < h + extra; y += stepY, row++) {
      final shift = row.isOdd ? stepX / 2 : 0.0;
      for (var x = -extra + shift; x < w + extra; x += stepX) {
        item.draw(canvas, Offset(x, y));
      }
    }
    canvas.restore();
  }

  static Offset _origin(WatermarkPosition pos, double w, double h, double bw,
      double bh, double margin) {
    final col = pos.index % 3; // 0 left, 1 centre, 2 right
    final row = pos.index ~/ 3; // 0 top, 1 middle, 2 bottom
    final x = switch (col) {
      0 => margin,
      1 => (w - bw) / 2,
      _ => w - bw - margin,
    };
    final y = switch (row) {
      0 => margin,
      1 => (h - bh) / 2,
      _ => h - bh - margin,
    };
    return Offset(x, y);
  }

  /// Joins [paths] into one picture and returns a PNG file path.
  static Future<String> collage({
    required List<String> paths,
    required CollageLayout layout,
    required double gap, // pixels between pictures
    required Color background,
  }) async {
    final n = paths.length;
    final cols = switch (layout) {
      CollageLayout.horizontal => n,
      CollageLayout.vertical => 1,
      _ => math.min(layout.columns, n),
    };
    final rows = (n / cols).ceil();
    final cell =
        math.min(1080.0, 8000.0 / math.max(cols, rows)).floorToDouble();
    final width = cols * cell + (cols + 1) * gap;
    final height = rows * cell + (rows + 1) * gap;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
        Rect.fromLTWH(0, 0, width, height), Paint()..color = background);

    for (var i = 0; i < n; i++) {
      final image = await load(paths[i], maxSide: (cell * 2).round());
      final col = i % cols, row = i ~/ cols;
      // Pictures in the last, shorter row are centred.
      final inRow = row == rows - 1 ? n - row * cols : cols;
      final rowShift = (cols - inRow) * (cell + gap) / 2;
      final dst = Rect.fromLTWH(
        gap + col * (cell + gap) + rowShift,
        gap + row * (cell + gap),
        cell,
        cell,
      );
      canvas.drawImageRect(image, _coverRect(image, 1.0), dst,
          Paint()..filterQuality = FilterQuality.high);
      image.dispose();
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.round(), height.round());
    final out = await ImageService.instance.tempPath('png', 'collage');
    await writePng(image, out);
    image.dispose();
    return out;
  }

  /// Largest centred part of [image] that has the given width/height ratio.
  static Rect _coverRect(ui.Image image, double ratio) {
    final iw = image.width.toDouble(), ih = image.height.toDouble();
    if (iw / ih > ratio) {
      final w = ih * ratio;
      return Rect.fromLTWH((iw - w) / 2, 0, w, ih);
    }
    final h = iw / ratio;
    return Rect.fromLTWH(0, (ih - h) / 2, iw, h);
  }

  /// Repeats a [photoPath] picture over a print sheet. Returns a PNG path
  /// and how many copies fit.
  static Future<(String, int)> printSheet({
    required String photoPath,
    required int photoWidth,
    required int photoHeight,
    required int sheetWidth,
    required int sheetHeight,
  }) async {
    const gap = 24, margin = 36;
    final photo = await load(photoPath, maxSide: 8000);
    final cols =
        math.max(1, (sheetWidth - 2 * margin + gap) ~/ (photoWidth + gap));
    final rows =
        math.max(1, (sheetHeight - 2 * margin + gap) ~/ (photoHeight + gap));

    final usedW = cols * photoWidth + (cols - 1) * gap;
    final usedH = rows * photoHeight + (rows - 1) * gap;
    final startX = (sheetWidth - usedW) / 2;
    final startY = (sheetHeight - usedH) / 2;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, sheetWidth.toDouble(), sheetHeight.toDouble()),
      Paint()..color = const Color(0xFFFFFFFF),
    );
    final src =
        Rect.fromLTWH(0, 0, photo.width.toDouble(), photo.height.toDouble());
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFFBDBDBD);
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final dst = Rect.fromLTWH(
          startX + c * (photoWidth + gap),
          startY + r * (photoHeight + gap),
          photoWidth.toDouble(),
          photoHeight.toDouble(),
        );
        canvas.drawImageRect(
            photo, src, dst, Paint()..filterQuality = FilterQuality.high);
        canvas.drawRect(dst, outline);
      }
    }
    photo.dispose();

    final picture = recorder.endRecording();
    final image = await picture.toImage(sheetWidth, sheetHeight);
    final out = await ImageService.instance.tempPath('png', 'sheet');
    await writePng(image, out);
    image.dispose();
    return (out, cols * rows);
  }
}

class _Mark {
  final double w;
  final double h;
  final void Function(Canvas canvas, Offset origin) draw;
  _Mark(this.w, this.h, this.draw);
}
