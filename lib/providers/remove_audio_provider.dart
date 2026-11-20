import 'base_provider.dart';

/// Provider for the Remove Audio feature.
class RemoveAudioProvider extends BaseToolProvider {
  Future<void> process() {
    return runJob(
      suffix: 'silent',
      extension: 'mp4',
      failMessage: 'Removing audio failed.',
      job: (out, onProgress) => ffmpeg.removeAudio(
        inputPath: inputPath!,
        outputPath: out,
        onProgress: onProgress,
      ),
    );
  }
}
