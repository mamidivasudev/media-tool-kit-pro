import '../../core/services/image_service.dart';
import 'base_image_provider.dart';

/// Provider for brightness, contrast, colour and look adjustments.
class ImageAdjustProvider extends BaseImageProvider {
  double _brightness = 0; // -0.5 .. 0.5
  double _contrast = 1; // 0.5 .. 1.5
  double _saturation = 1; // 0 .. 2
  double _sharpness = 0; // 0 .. 2
  ImageLook _look = ImageLook.none;

  double get brightness => _brightness;
  double get contrast => _contrast;
  double get saturation => _saturation;
  double get sharpness => _sharpness;
  ImageLook get look => _look;

  bool get hasChanges =>
      _brightness != 0 ||
      _contrast != 1 ||
      _saturation != 1 ||
      _sharpness != 0 ||
      _look != ImageLook.none;

  void setBrightness(double v) {
    _brightness = v;
    notifyListeners();
  }

  void setContrast(double v) {
    _contrast = v;
    notifyListeners();
  }

  void setSaturation(double v) {
    _saturation = v;
    notifyListeners();
  }

  void setSharpness(double v) {
    _sharpness = v;
    notifyListeners();
  }

  void setLook(ImageLook v) {
    _look = v;
    notifyListeners();
  }

  void resetAdjustments() {
    _brightness = 0;
    _contrast = 1;
    _saturation = 1;
    _sharpness = 0;
    _look = ImageLook.none;
    notifyListeners();
  }

  Future<void> process() {
    if (!hasInput || !hasChanges) return Future.value();
    final format = sameFormat;
    return runJob(
      suffix: 'edited',
      extension: format.extension,
      failMessage: 'Applying changes failed.',
      job: (out, onProgress) => imageTools.adjust(
        input: inputPath!,
        output: out,
        brightness: _brightness,
        contrast: _contrast,
        saturation: _saturation,
        sharpness: _sharpness,
        look: _look,
        target: format,
      ),
    );
  }
}
