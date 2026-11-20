import '../core/services/ffmpeg_service.dart';
import '../core/utils/file_utils.dart';
import 'base_provider.dart';

/// Provider for the audio extraction feature (MP3, M4A or WAV).
class ExtractMp3Provider extends BaseToolProvider {
  AudioFormat _format = AudioFormat.mp3;
  int _bitrate = 192;
  int _outputSizeBytes = 0;

  AudioFormat get format => _format;
  int get bitrate => _bitrate;
  String get outputSizeFormatted =>
      _outputSizeBytes > 0 ? FileUtils.formatFileSize(_outputSizeBytes) : '--';

  void setFormat(AudioFormat format) {
    _format = format;
    notifyListeners();
  }

  void setBitrate(int kbps) {
    _bitrate = kbps;
    notifyListeners();
  }

  @override
  Future<void> onSuccess(String outputPath) async {
    _outputSizeBytes = await FileUtils.getFileSizeBytes(outputPath);
  }

  Future<void> process() {
    _outputSizeBytes = 0;
    final target = _format;
    return runJob(
      suffix: 'audio',
      extension: target.extension,
      failMessage: 'Audio extraction failed.',
      job: (out, onProgress) => ffmpeg.extractAudio(
        inputPath: inputPath!,
        outputPath: out,
        format: target,
        bitrateKbps: _bitrate,
        onProgress: onProgress,
      ),
    );
  }

  /// Lets the user save the audio file to a folder of their choice.
  Future<bool> saveToDevice() async {
    final path = outputPath;
    if (path == null) return false;
    return storage.saveToDevice(path);
  }

  @override
  Future<void> share() async {
    final path = outputPath;
    if (path == null) return;
    await storage.shareAudio(path);
  }

  @override
  void onReset() {
    _outputSizeBytes = 0;
  }
}
