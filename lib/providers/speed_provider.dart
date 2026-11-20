import 'base_provider.dart';

/// Provider for the speed changer (slow motion and fast forward).
class SpeedProvider extends BaseToolProvider {
  static const List<double> speeds = [0.25, 0.5, 0.75, 1.5, 2, 3, 4];

  double _speed = 2;

  double get speed => _speed;

  static String label(double speed) =>
      '${speed == speed.roundToDouble() ? speed.toInt() : speed}x';

  void setSpeed(double value) {
    _speed = value;
    notifyListeners();
  }

  Future<void> process() {
    final chosen = _speed;
    return runJob(
      suffix: '${label(chosen).replaceAll('.', '_')}_speed',
      extension: 'mp4',
      failMessage: 'Changing speed failed.',
      job: (out, onProgress) => ffmpeg.changeSpeed(
        inputPath: inputPath!,
        outputPath: out,
        speed: chosen,
        onProgress: onProgress,
      ),
    );
  }
}
