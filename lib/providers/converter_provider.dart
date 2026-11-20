import '../core/services/ffmpeg_service.dart';
import 'base_provider.dart';

/// Provider for the video format converter.
class ConverterProvider extends BaseToolProvider {
  VideoFormat _format = VideoFormat.mp4;

  VideoFormat get format => _format;

  @override
  Future<void> pickVideo() async {
    if (isBusy) return;
    final path = await fileService.pickAnyVideo();
    if (path != null) await setInput(path);
  }

  void setFormat(VideoFormat format) {
    _format = format;
    notifyListeners();
  }

  Future<void> process() {
    final target = _format;
    return runJob(
      suffix: 'converted',
      extension: target.extension,
      failMessage: 'Conversion failed.',
      job: (out, onProgress) => ffmpeg.convertVideo(
        inputPath: inputPath!,
        outputPath: out,
        format: target,
        onProgress: onProgress,
      ),
    );
  }
}
