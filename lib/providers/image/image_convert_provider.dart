import '../../core/services/image_service.dart';
import 'base_image_provider.dart';

/// Provider for the image format converter.
class ImageConvertProvider extends BaseImageProvider {
  ImageFormat _format = ImageFormat.png;
  int _quality = 92;

  ImageFormat get format => _format;
  int get quality => _quality;
  bool get usesQuality => _format != ImageFormat.png;

  void setFormat(ImageFormat format) {
    _format = format;
    notifyListeners();
  }

  void setQuality(int value) {
    _quality = value;
    notifyListeners();
  }

  Future<void> process() {
    if (!hasInput) return Future.value();
    final format = _format;
    return runJob(
      suffix: 'converted',
      extension: format.extension,
      failMessage: 'Conversion failed.',
      job: (out, onProgress) => imageTools.convert(
        input: inputPath!,
        output: out,
        target: format,
        quality: _quality,
      ),
    );
  }
}
