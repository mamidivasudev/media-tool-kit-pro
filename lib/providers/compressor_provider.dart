import '../core/utils/file_utils.dart';
import 'base_provider.dart';

enum CompressionLevel { low, medium, high }

/// Maximum output height. [original] keeps the source resolution.
enum CompressionResolution {
  original('Original', 0),
  p1080('1080p', 1080),
  p720('720p', 720),
  p480('480p', 480);

  final String label;
  final int height;
  const CompressionResolution(this.label, this.height);
}

/// Provider for Video Compressor feature.
class CompressorProvider extends BaseToolProvider {
  CompressionLevel _level = CompressionLevel.medium;
  CompressionResolution _resolution = CompressionResolution.original;
  int _originalSize = 0;
  int _compressedSize = 0;

  CompressionLevel get level => _level;
  CompressionResolution get resolution => _resolution;

  String get originalSizeFormatted =>
      _originalSize > 0 ? FileUtils.formatFileSize(_originalSize) : '--';
  String get compressedSizeFormatted =>
      _compressedSize > 0 ? FileUtils.formatFileSize(_compressedSize) : '--';
  double get savedPercentage =>
      FileUtils.calculateSavedPercentage(_originalSize, _compressedSize);

  /// True when the result ended up larger than the original.
  bool get grewInSize =>
      _compressedSize > 0 &&
      _originalSize > 0 &&
      _compressedSize >= _originalSize;

  // CRF: lower = better quality and larger file; higher = smaller file.
  int get _crf {
    switch (_level) {
      case CompressionLevel.low:
        return 24; // light compression, near-original quality
      case CompressionLevel.medium:
        return 28;
      case CompressionLevel.high:
        return 33; // heavy compression, still watchable
    }
  }

  @override
  Future<void> onInputChanged(String path) async {
    _compressedSize = 0;
    _originalSize = await FileUtils.getFileSizeBytes(path);
  }

  @override
  Future<void> onSuccess(String outputPath) async {
    _compressedSize = await FileUtils.getFileSizeBytes(outputPath);
  }

  void setLevel(CompressionLevel level) {
    _level = level;
    notifyListeners();
  }

  void setResolution(CompressionResolution resolution) {
    _resolution = resolution;
    notifyListeners();
  }

  Future<void> process() {
    return runJob(
      suffix: 'compressed',
      extension: 'mp4',
      failMessage: 'Compression failed.',
      job: (out, onProgress) => ffmpeg.compressVideo(
        inputPath: inputPath!,
        outputPath: out,
        crf: _crf,
        maxHeight: _resolution.height,
        onProgress: onProgress,
      ),
    );
  }

  @override
  void onReset() {
    _originalSize = 0;
    _compressedSize = 0;
  }
}
