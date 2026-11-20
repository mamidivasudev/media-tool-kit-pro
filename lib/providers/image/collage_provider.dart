import 'dart:io';
import 'package:flutter/painting.dart';

import '../../core/services/image_canvas.dart';
import '../../core/services/image_service.dart';
import 'base_image_provider.dart';

/// Provider that joins several pictures into one collage.
class CollageProvider extends MultiImageProvider {
  static const Map<String, Color> backgrounds = {
    'White': Color(0xFFFFFFFF),
    'Black': Color(0xFF000000),
    'Gray': Color(0xFF9E9E9E),
  };

  CollageLayout _layout = CollageLayout.grid2;
  double _gap = 12;
  String _background = 'White';
  ImageFormat _format = ImageFormat.jpg;

  @override
  int get minImages => 2;
  @override
  int get maxImages => 9;

  CollageLayout get layout => _layout;
  double get gap => _gap;
  String get background => _background;
  ImageFormat get format => _format;

  void setLayout(CollageLayout v) {
    _layout = v;
    notifyListeners();
  }

  void setGap(double v) {
    _gap = v;
    notifyListeners();
  }

  void setBackground(String v) {
    _background = v;
    notifyListeners();
  }

  void setFormat(ImageFormat v) {
    _format = v;
    notifyListeners();
  }

  Future<void> process() {
    if (!canProcess) return Future.value();
    final paths = List.of(images);
    final target = _format;
    return runJob(
      suffix: 'collage',
      extension: target.extension,
      failMessage: 'Creating the collage failed.',
      job: (out, onProgress) async {
        final png = await ImageCanvas.collage(
          paths: paths,
          layout: _layout,
          gap: _gap,
          background: backgrounds[_background] ?? backgrounds['White']!,
        );
        try {
          return await imageTools.convert(
              input: png, output: out, target: target, quality: 94);
        } finally {
          await File(png).delete().catchError((_) => File(png));
        }
      },
    );
  }
}
