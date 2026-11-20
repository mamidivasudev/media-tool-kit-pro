import '../../core/services/image_service.dart';
import 'base_image_provider.dart';

enum CompressMode { quality, targetSize }

/// Provider for the image compressor.
class ImageCompressProvider extends BaseImageProvider {
  static const List<int> targetsKb = [20, 50, 100, 200, 500, 1024];
  static const List<ImageFormat> formats = [ImageFormat.jpg, ImageFormat.webp];

  CompressMode _mode = CompressMode.quality;
  ImageFormat _format = ImageFormat.jpg;
  int _quality = 70;
  int _targetKb = 100;

  CompressMode get mode => _mode;
  ImageFormat get format => _format;
  int get quality => _quality;
  int get targetKb => _targetKb;

  static String targetLabel(int kb) =>
      kb >= 1024 ? '${kb ~/ 1024} MB' : '$kb KB';

  /// Percent of the original size that was saved (negative if it grew).
  double get savedPercent =>
      inputBytes == 0 ? 0 : (inputBytes - outputBytes) / inputBytes * 100;

  void setMode(CompressMode mode) {
    _mode = mode;
    notifyListeners();
  }

  void setFormat(ImageFormat format) {
    _format = format;
    notifyListeners();
  }

  void setQuality(int value) {
    _quality = value;
    notifyListeners();
  }

  void setTargetKb(int kb) {
    _targetKb = kb;
    notifyListeners();
  }

  Future<void> process() {
    if (!hasInput) return Future.value();
    final format = _format;
    return runJob(
      suffix: 'compressed',
      extension: format.extension,
      failMessage: 'Image compression failed.',
      job: (out, onProgress) {
        if (_mode == CompressMode.targetSize) {
          return imageTools.compressToTarget(
            input: inputPath!,
            output: out,
            targetBytes: _targetKb * 1024,
            target: format,
            onProgress: onProgress,
          );
        }
        return imageTools.compress(
          input: inputPath!,
          output: out,
          target: format,
          quality: _quality,
        );
      },
    );
  }
}
