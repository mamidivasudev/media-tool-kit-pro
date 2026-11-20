import 'dart:math' as math;
import '../core/utils/file_utils.dart';
import 'base_provider.dart';

/// Provider for the video to GIF tool.
class GifProvider extends BaseToolProvider {
  static const double maxGifSeconds = 15;
  static const List<int> fpsOptions = [8, 12, 15];
  static const List<int> widthOptions = [320, 480, 640];

  double _videoDuration = 0;
  double _start = 0;
  double _length = 5;
  int _fps = 12;
  int _width = 480;
  int _outputSize = 0;

  double get videoDuration => _videoDuration;
  double get start => _start;
  double get length => _length;
  int get fps => _fps;
  int get width => _width;
  String get outputSizeFormatted =>
      _outputSize > 0 ? FileUtils.formatFileSize(_outputSize) : '--';

  /// The longest clip allowed from the current start position.
  double get maxLength => math.min(maxGifSeconds, _videoDuration - _start);
  bool get canProcess => hasInput && _videoDuration > 0 && _length > 0;

  @override
  Future<void> onInputChanged(String path) async {
    final duration = await ffmpeg.getVideoDuration(path);
    _videoDuration = duration ?? 0;
    _start = 0;
    _length = math.min(5, _videoDuration);
    if (duration == null) {
      reportError(
          'Could not read this video. It may be damaged or unsupported.');
    }
  }

  void setStart(double value) {
    _start = value.clamp(0, math.max(0, _videoDuration - 0.5));
    if (_length > maxLength) _length = maxLength;
    notifyListeners();
  }

  void setLength(double value) {
    _length = value.clamp(0.5, math.max(0.5, maxLength));
    notifyListeners();
  }

  void setFps(int value) {
    _fps = value;
    notifyListeners();
  }

  void setWidth(int value) {
    _width = value;
    notifyListeners();
  }

  @override
  Future<void> onSuccess(String outputPath) async {
    _outputSize = await FileUtils.getFileSizeBytes(outputPath);
  }

  Future<void> process() {
    if (!canProcess) return Future.value();
    return runJob(
      suffix: 'gif',
      extension: 'gif',
      failMessage: 'GIF creation failed.',
      job: (out, onProgress) => ffmpeg.videoToGif(
        inputPath: inputPath!,
        outputPath: out,
        startSecs: _start,
        lengthSecs: _length,
        fps: _fps,
        width: _width,
        onProgress: onProgress,
      ),
    );
  }

  @override
  Future<bool> saveToGallery() async {
    final path = outputPath;
    if (path == null) return false;
    return storage.saveImageToGallery(path);
  }

  @override
  void onReset() {
    _videoDuration = 0;
    _start = 0;
    _length = 5;
    _outputSize = 0;
  }
}
