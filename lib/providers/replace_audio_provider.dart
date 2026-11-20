import 'base_provider.dart';

/// Provider for the tool that puts a new soundtrack on a video.
class ReplaceAudioProvider extends BaseToolProvider {
  String? _audioPath;

  String? get audioPath => _audioPath;
  bool get canProcess => hasInput && _audioPath != null;

  Future<void> pickAudio() async {
    if (isBusy) return;
    final path = await fileService.pickAudio();
    if (path == null) return;
    _audioPath = path;
    notifyListeners();
  }

  Future<void> process() {
    if (!canProcess) return Future.value();
    final audio = _audioPath!;
    return runJob(
      suffix: 'new_audio',
      extension: 'mp4',
      failMessage: 'Adding the audio failed.',
      job: (out, onProgress) => ffmpeg.replaceAudio(
        videoPath: inputPath!,
        audioPath: audio,
        outputPath: out,
        onProgress: onProgress,
      ),
    );
  }

  @override
  void onReset() {
    _audioPath = null;
  }
}
