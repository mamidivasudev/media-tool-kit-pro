import 'dart:math' as math;
import 'base_image_provider.dart';

enum ResizeMode { percent, dimensions, preset }

/// A named maximum size, for example a social media post.
class ResizePreset {
  final String label;
  final int width;
  final int height;
  const ResizePreset(this.label, this.width, this.height);
}

/// Provider for the image resizer.
class ImageResizeProvider extends BaseImageProvider {
  static const List<int> percents = [75, 50, 25];
  static const List<ResizePreset> presets = [
    ResizePreset('Instagram post 1080×1080', 1080, 1080),
    ResizePreset('Instagram story 1080×1920', 1080, 1920),
    ResizePreset('WhatsApp DP 500×500', 500, 500),
    ResizePreset('Full HD 1920×1080', 1920, 1080),
    ResizePreset('HD 1280×720', 1280, 720),
    ResizePreset('Email / web 800×600', 800, 600),
    ResizePreset('Thumbnail 200×200', 200, 200),
  ];

  ResizeMode _mode = ResizeMode.percent;
  int _percent = 50;
  int _width = 0;
  int _height = 0;
  bool _keepAspect = true;
  ResizePreset _preset = presets.first;

  ResizeMode get mode => _mode;
  int get percent => _percent;
  int get width => _width;
  int get height => _height;
  bool get keepAspect => _keepAspect;
  ResizePreset get preset => _preset;

  @override
  Future<void> onInputChanged(String path) async {
    await super.onInputChanged(path);
    _width = imageWidth;
    _height = imageHeight;
  }

  void setMode(ResizeMode mode) {
    _mode = mode;
    notifyListeners();
  }

  void setPercent(int value) {
    _percent = value.clamp(5, 200);
    notifyListeners();
  }

  void setPreset(ResizePreset preset) {
    _preset = preset;
    notifyListeners();
  }

  void setKeepAspect(bool value) {
    _keepAspect = value;
    notifyListeners();
  }

  void setWidth(int value) {
    _width = value.clamp(1, 20000);
    if (_keepAspect && imageWidth > 0) {
      _height = math.max(1, (_width * imageHeight / imageWidth).round());
    }
    notifyListeners();
  }

  void setHeight(int value) {
    _height = value.clamp(1, 20000);
    if (_keepAspect && imageHeight > 0) {
      _width = math.max(1, (_height * imageWidth / imageHeight).round());
    }
    notifyListeners();
  }

  /// The size the result will have with the current options.
  (int, int) get targetSize {
    switch (_mode) {
      case ResizeMode.percent:
        return (
          math.max(1, (imageWidth * _percent / 100).round()),
          math.max(1, (imageHeight * _percent / 100).round()),
        );
      case ResizeMode.dimensions:
        return (_width, _height);
      case ResizeMode.preset:
        if (imageWidth == 0) return (_preset.width, _preset.height);
        final scale =
            math.min(_preset.width / imageWidth, _preset.height / imageHeight);
        return (
          math.max(1, (imageWidth * scale).round()),
          math.max(1, (imageHeight * scale).round()),
        );
    }
  }

  Future<void> process() {
    if (!hasInput || imageWidth == 0) return Future.value();
    final (w, h) = targetSize;
    final format = sameFormat;
    return runJob(
      suffix: 'resized',
      extension: format.extension,
      failMessage: 'Resize failed.',
      job: (out, onProgress) => imageTools.resize(
        input: inputPath!,
        output: out,
        width: w,
        height: h,
        target: format,
      ),
    );
  }

  @override
  void onReset() {
    super.onReset();
    _width = 0;
    _height = 0;
  }
}
