import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'base_provider.dart';

/// What to do with the range chosen on the timeline.
enum TrimMode {
  /// Keep only the selected range.
  trim,

  /// Remove the selected range and join what is left.
  cutCenter,

  /// Save the part before the range and the part after it as two clips.
  twoClips,
}

/// Provider for the Video Trimmer / Cutter.
class TrimmerProvider extends BaseToolProvider {
  static const int filmstripCount = 8;
  static const double _minPiece = 0.3;

  double _videoDuration = 0;
  RangeValues _trimRange = const RangeValues(0, 0);
  TrimMode _mode = TrimMode.trim;
  List<String> _filmstrip = const [];
  List<String> _partPaths = [];

  double get videoDuration => _videoDuration;
  RangeValues get trimRange => _trimRange;
  TrimMode get mode => _mode;

  /// Small preview frames spread across the video, used by the timeline.
  List<String> get filmstrip => _filmstrip;

  /// The finished clips when a mode produced more than one file.
  List<String> get partPaths => List.unmodifiable(_partPaths);

  /// Length of the pieces that lie outside the selected range.
  double get beforeLength => _trimRange.start;
  double get afterLength => _videoDuration - _trimRange.end;

  bool get canProcess {
    if (!hasInput ||
        _videoDuration <= 0 ||
        _trimRange.end <= _trimRange.start) {
      return false;
    }
    switch (_mode) {
      case TrimMode.trim:
        return true;
      case TrimMode.cutCenter:
        return beforeLength >= _minPiece || afterLength >= _minPiece;
      case TrimMode.twoClips:
        return beforeLength >= _minPiece && afterLength >= _minPiece;
    }
  }

  /// A short explanation of what the current mode will export.
  String get modeHint {
    switch (_mode) {
      case TrimMode.trim:
        return 'Keeps only the part between Start and End.';
      case TrimMode.cutCenter:
        return 'Removes the part between Start and End and joins the rest.';
      case TrimMode.twoClips:
        return 'Saves the part before Start and the part after End as two '
            'separate clips.';
    }
  }

  @override
  Future<void> onInputChanged(String path) async {
    final duration = await ffmpeg.getVideoDuration(path);
    _videoDuration = duration ?? 0;
    _trimRange = RangeValues(0, _videoDuration);
    _partPaths = [];
    _filmstrip = const [];
    if (duration == null) {
      reportError(
          'Could not read this video. It may be damaged or unsupported.');
    } else {
      _loadFilmstrip(path, duration); // runs in the background
    }
  }

  Future<void> _loadFilmstrip(String path, double duration) async {
    try {
      final tmp = await getTemporaryDirectory();
      final dir = Directory(p.join(
          tmp.path, 'trim_strip_${DateTime.now().microsecondsSinceEpoch}'));
      await dir.create(recursive: true);
      final fps = filmstripCount / duration;
      final ok = await ffmpeg.runCommand([
        '-i',
        path,
        '-vf',
        'fps=$fps,scale=-2:120',
        '-frames:v',
        '$filmstripCount',
        '-q:v',
        '5',
        p.join(dir.path, 'f_%02d.jpg'),
      ], inputPath: path);
      if (!ok || inputPath != path) return;
      final files = dir
          .listSync()
          .whereType<File>()
          .map((f) => f.path)
          .toList()
        ..sort();
      _filmstrip = files;
      notifyListeners();
    } catch (_) {
      // The timeline just stays plain if frames cannot be made.
    }
  }

  void setMode(TrimMode mode) {
    _mode = mode;
    notifyListeners();
  }

  void setTrimRange(RangeValues range) {
    _trimRange = RangeValues(
      range.start.clamp(0, _videoDuration),
      range.end.clamp(0, _videoDuration),
    );
    notifyListeners();
  }

  /// Moves the start handle by [delta] seconds (used by the nudge buttons).
  void nudgeStart(double delta) => setTrimRange(RangeValues(
      (_trimRange.start + delta).clamp(0, _trimRange.end - 0.1),
      _trimRange.end));

  /// Moves the end handle by [delta] seconds.
  void nudgeEnd(double delta) => setTrimRange(RangeValues(_trimRange.start,
      (_trimRange.end + delta).clamp(_trimRange.start + 0.1, _videoDuration)));

  Future<void> process() {
    if (!canProcess) return Future.value();
    final mode = _mode;
    final start = _trimRange.start;
    final end = _trimRange.end;
    final total = _videoDuration;
    final hasBefore = start >= _minPiece;
    final hasAfter = total - end >= _minPiece;

    Future<String> tempPath(String suffix) => ffmpeg.createOutputPath(
        suffix: suffix, extension: 'mp4', baseName: inputPath);

    return runJob(
      suffix: switch (mode) {
        TrimMode.trim => 'trimmed',
        TrimMode.cutCenter => 'cut',
        TrimMode.twoClips => 'clip1',
      },
      extension: 'mp4',
      failMessage: switch (mode) {
        TrimMode.trim => 'Trim failed.',
        TrimMode.cutCenter => 'Cut failed.',
        TrimMode.twoClips => 'Split failed.',
      },
      job: (out, onProgress) async {
        final input = inputPath!;
        _partPaths = [];

        switch (mode) {
          case TrimMode.trim:
            return ffmpeg.trimVideo(
              inputPath: input,
              outputPath: out,
              startSecs: start,
              endSecs: end,
              onProgress: onProgress,
            );

          case TrimMode.cutCenter:
            // Only one side is left: it is a plain trim.
            if (hasBefore != hasAfter) {
              return ffmpeg.trimVideo(
                inputPath: input,
                outputPath: out,
                startSecs: hasBefore ? 0 : end,
                endSecs: hasBefore ? start : total,
                onProgress: onProgress,
              );
            }
            final first = await tempPath('cutA');
            final second = await tempPath('cutB');
            try {
              var ok = await ffmpeg.trimVideo(
                inputPath: input,
                outputPath: first,
                startSecs: 0,
                endSecs: start,
                onProgress: (v) => onProgress(v * 0.45),
              );
              if (!ok) return false;
              ok = await ffmpeg.trimVideo(
                inputPath: input,
                outputPath: second,
                startSecs: end,
                endSecs: total,
                onProgress: (v) => onProgress(0.45 + v * 0.45),
              );
              if (!ok) return false;
              return await ffmpeg.mergeVideos(
                inputPaths: [first, second],
                outputPath: out,
                onProgress: (v) => onProgress(0.9 + v * 0.1),
              );
            } finally {
              for (final f in [first, second]) {
                await File(f).delete().catchError((_) => File(f));
              }
            }

          case TrimMode.twoClips:
            final second = await tempPath('clip2');
            var ok = await ffmpeg.trimVideo(
              inputPath: input,
              outputPath: out,
              startSecs: 0,
              endSecs: start,
              onProgress: (v) => onProgress(v * 0.5),
            );
            if (ok) {
              ok = await ffmpeg.trimVideo(
                inputPath: input,
                outputPath: second,
                startSecs: end,
                endSecs: total,
                onProgress: (v) => onProgress(0.5 + v * 0.5),
              );
            }
            if (!ok) {
              await File(second).delete().catchError((_) => File(second));
              return false;
            }
            _partPaths = [out, second];
            return true;
        }
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
  Future<bool> saveToGallery() =>
      _partPaths.length > 1 ? saveAllToGallery() : super.saveToGallery();

  @override
  Future<void> share() =>
      _partPaths.length > 1 ? storage.shareFiles(_partPaths) : super.share();

  Future<void> sharePart(String path) => storage.shareFilePath(path);

  @override
  Future<void> onOutputDiscarded() async {
    // The first clip is deleted by the base class; remove the others here.
    for (final path in _partPaths.skip(1)) {
      await File(path).delete().catchError((_) => File(path));
    }
    _partPaths = [];
  }

  @override
  void onReset() {
    _videoDuration = 0;
    _trimRange = const RangeValues(0, 0);
    _filmstrip = const [];
    _partPaths = [];
  }
}
