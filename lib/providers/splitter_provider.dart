import 'dart:io';
import 'base_provider.dart';

enum SplitMode { points, equal }

/// One piece of the video, in seconds.
typedef Segment = ({double start, double end});

/// Provider for Video Splitter: cuts a video at chosen split points, or into
/// equal parts.
class SplitterProvider extends BaseToolProvider {
  static const int minParts = 2;
  static const int maxParts = 10;
  static const double minSegment = 0.5;

  double _videoDuration = 0;
  SplitMode _mode = SplitMode.points;
  int _parts = 2;
  final List<double> _points = [];
  bool _precise = false;
  bool _sequence = false;
  List<String> _partPaths = [];

  double get videoDuration => _videoDuration;
  SplitMode get mode => _mode;
  int get parts => _parts;
  List<double> get points => List.unmodifiable(_points);
  bool get precise => _precise;
  bool get sequence => _sequence;
  List<String> get partPaths => List.unmodifiable(_partPaths);
  double get partLength => _videoDuration / _parts;

  /// The pieces that will be exported with the current settings.
  List<Segment> get segments {
    if (_videoDuration <= 0) return const [];
    if (_mode == SplitMode.equal) {
      final length = _videoDuration / _parts;
      return [
        for (var i = 0; i < _parts; i++)
          (
            start: i * length,
            end: i == _parts - 1 ? _videoDuration : (i + 1) * length
          ),
      ];
    }
    final bounds = [0.0, ..._points, _videoDuration];
    return [
      for (var i = 0; i < bounds.length - 1; i++)
        (start: bounds[i], end: bounds[i + 1]),
    ];
  }

  bool get canProcess {
    if (!hasInput || _videoDuration <= 0) return false;
    if (_mode == SplitMode.points && _points.isEmpty) return false;
    return segments.every((s) => s.end - s.start >= minSegment);
  }

  @override
  Future<void> onInputChanged(String path) async {
    final duration = await ffmpeg.getVideoDuration(path);
    _videoDuration = duration ?? 0;
    _partPaths = [];
    _points.clear();
    if (duration == null) {
      reportError(
          'Could not read this video. It may be damaged or unsupported.');
    } else {
      // Never offer more parts than the video can support.
      final most = _videoDuration.floor().clamp(minParts, maxParts);
      if (_parts > most) _parts = most;
    }
  }

  void setMode(SplitMode mode) {
    _mode = mode;
    notifyListeners();
  }

  void setParts(int value) {
    _parts = value.clamp(minParts, maxParts);
    notifyListeners();
  }

  /// Adds a split point at [seconds]. Returns false when it is too close to
  /// the start, the end or another point.
  bool addPoint(double seconds) {
    final t = double.parse(seconds.toStringAsFixed(1));
    if (t < minSegment || t > _videoDuration - minSegment) return false;
    if (_points.any((p) => (p - t).abs() < minSegment)) return false;
    _points
      ..add(t)
      ..sort();
    notifyListeners();
    return true;
  }

  void removePoint(double point) {
    _points.remove(point);
    notifyListeners();
  }

  void clearPoints() {
    _points.clear();
    notifyListeners();
  }

  void setPrecise(bool value) {
    _precise = value;
    notifyListeners();
  }

  void setSequence(bool value) {
    _sequence = value;
    notifyListeners();
  }

  Future<void> process() {
    if (!canProcess) return Future.value();
    final pieces = segments;
    final count = pieces.length;
    // Numbering is drawn onto the picture, which needs re-encoding.
    final precise = _precise || _sequence;
    final numbered = _sequence;
    final created = <String>[];

    return runJob(
      suffix: 'part1',
      extension: 'mp4',
      failMessage: 'Split failed.',
      job: (firstOut, onProgress) async {
        for (var i = 0; i < count; i++) {
          final out = i == 0
              ? firstOut
              : await ffmpeg.createOutputPath(
                  suffix: 'part${i + 1}',
                  extension: 'mp4',
                  baseName: inputPath,
                );
          final ok = await ffmpeg.cutSegment(
            inputPath: inputPath!,
            outputPath: out,
            startSecs: pieces[i].start,
            endSecs: pieces[i].end,
            precise: precise,
            overlayText: numbered ? '${i + 1}/$count' : null,
            onProgress: (p) => onProgress((i + p) / count),
          );
          if (!ok) {
            for (final path in created) {
              await File(path).delete().catchError((_) => File(path));
            }
            return false;
          }
          if (i > 0) created.add(out);
        }
        _partPaths = [firstOut, ...created];
        return true;
      },
    );
  }

  Future<bool> saveAllToGallery() async {
    var allOk = _partPaths.isNotEmpty;
    for (final path in _partPaths) {
      final ok = await storage.saveVideoToGallery(path);
      allOk = allOk && ok;
    }
    return allOk;
  }

  @override
  Future<bool> saveToGallery() => saveAllToGallery();

  @override
  Future<void> share() => storage.shareFiles(_partPaths);

  Future<void> sharePart(String path) => storage.shareFilePath(path);

  @override
  Future<void> onOutputDiscarded() async {
    // The first part is deleted by the base class; remove the rest here.
    for (final path in _partPaths.skip(1)) {
      await File(path).delete().catchError((_) => File(path));
    }
    _partPaths = [];
  }

  @override
  void onReset() {
    _videoDuration = 0;
    _partPaths = [];
    _points.clear();
  }
}
