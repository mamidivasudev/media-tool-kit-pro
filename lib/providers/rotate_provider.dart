import '../core/services/ffmpeg_service.dart';
import 'base_provider.dart';

/// Provider for the rotate and flip tool.
class RotateProvider extends BaseToolProvider {
  RotateOption _option = RotateOption.cw90;

  RotateOption get option => _option;

  void setOption(RotateOption option) {
    _option = option;
    notifyListeners();
  }

  Future<void> process() {
    final chosen = _option;
    return runJob(
      suffix: 'rotated',
      extension: 'mp4',
      failMessage: 'Rotate failed.',
      job: (out, onProgress) => ffmpeg.rotateVideo(
        inputPath: inputPath!,
        outputPath: out,
        option: chosen,
        onProgress: onProgress,
      ),
    );
  }
}
