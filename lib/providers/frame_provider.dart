import 'base_provider.dart';

/// Provider that saves a single frame of a video as a JPEG picture.
class FrameProvider extends BaseToolProvider {
  double _videoDuration = 0;
  double _position = 0;

  double get videoDuration => _videoDuration;
  double get position => _position;
  bool get canProcess => hasInput && _videoDuration > 0;

  @override
  Future<void> onInputChanged(String path) async {
    final duration = await ffmpeg.getVideoDuration(path);
    _videoDuration = duration ?? 0;
    _position = 0;
    if (duration == null) {
      reportError(
          'Could not read this video. It may be damaged or unsupported.');
    }
  }

  void setPosition(double value) {
    _position = value.clamp(0, _videoDuration);
    notifyListeners();
  }

  Future<void> process() {
    if (!canProcess) return Future.value();
    // Seeking exactly to the final instant can return no frame.
    final at =
        _position.clamp(0, (_videoDuration - 0.1).clamp(0, _videoDuration));
    return runJob(
      suffix: 'frame',
      extension: 'jpg',
      failMessage: 'Could not extract the frame.',
      job: (out, onProgress) => ffmpeg.extractFrame(
        inputPath: inputPath!,
        outputPath: out,
        atSecs: at.toDouble(),
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
    _position = 0;
  }
}
