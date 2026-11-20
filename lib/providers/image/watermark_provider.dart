import 'dart:io';
import 'package:flutter/painting.dart';

import '../../core/services/image_canvas.dart';
import '../../core/services/image_service.dart';
import 'base_image_provider.dart';

/// Provider that adds a text and/or logo watermark to a picture.
class WatermarkProvider extends BaseImageProvider {
  static const Map<String, Color> colors = {
    'White': Color(0xFFFFFFFF),
    'Black': Color(0xFF000000),
    'Red': Color(0xFFE53935),
    'Yellow': Color(0xFFFDD835),
    'Blue': Color(0xFF1E88E5),
  };

  String _text = '';
  String? _logoPath;
  WatermarkPosition _position = WatermarkPosition.bottomRight;
  double _size = 0.06;
  double _opacity = 0.8;
  String _colorName = 'White';
  bool _repeat = false;
  ImageFormat _format = ImageFormat.jpg;

  String get text => _text;
  String? get logoPath => _logoPath;
  WatermarkPosition get position => _position;
  double get size => _size;
  double get opacity => _opacity;
  String get colorName => _colorName;
  bool get repeat => _repeat;
  ImageFormat get format => _format;
  bool get canProcess =>
      hasInput && (_text.trim().isNotEmpty || _logoPath != null);

  void setText(String v) {
    _text = v;
    notifyListeners();
  }

  void setPosition(WatermarkPosition v) {
    _position = v;
    notifyListeners();
  }

  void setSize(double v) {
    _size = v;
    notifyListeners();
  }

  void setOpacity(double v) {
    _opacity = v;
    notifyListeners();
  }

  void setColorName(String v) {
    _colorName = v;
    notifyListeners();
  }

  void setRepeat(bool v) {
    _repeat = v;
    notifyListeners();
  }

  void setFormat(ImageFormat v) {
    _format = v;
    notifyListeners();
  }

  Future<void> pickLogo() async {
    if (isBusy) return;
    final path = await fileService.pickImage();
    if (path == null) return;
    _logoPath = path;
    notifyListeners();
  }

  void removeLogo() {
    _logoPath = null;
    notifyListeners();
  }

  Future<void> process() {
    if (!canProcess) return Future.value();
    final target = _format;
    return runJob(
      suffix: 'watermarked',
      extension: target.extension,
      failMessage: 'Adding the watermark failed.',
      job: (out, onProgress) async {
        final base = await ImageCanvas.load(inputPath!, maxSide: 4096);
        final logo = _logoPath == null
            ? null
            : await ImageCanvas.load(_logoPath!, maxSide: 1024);
        final marked = await ImageCanvas.watermark(
          base: base,
          text: _text,
          logo: logo,
          position: _position,
          size: _size,
          opacity: _opacity,
          color: colors[_colorName] ?? colors['White']!,
          repeat: _repeat,
        );
        base.dispose();
        logo?.dispose();
        try {
          return await imageTools.convert(
              input: marked, output: out, target: target, quality: 94);
        } finally {
          await File(marked).delete().catchError((_) => File(marked));
        }
      },
    );
  }

  @override
  void onReset() {
    super.onReset();
    _logoPath = null;
  }
}
