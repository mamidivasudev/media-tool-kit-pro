import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/services/ffmpeg_service.dart';
import '../core/services/file_service.dart';
import '../core/services/storage_service.dart';

enum ProcessingState { idle, loading, processing, done, error }

/// Shared behaviour for every single-input tool: picking a file, running one
/// FFmpeg job with progress, cancelling, saving and sharing the result.
abstract class BaseToolProvider extends ChangeNotifier {
  final ffmpeg = FFmpegService.instance;
  final fileService = FileService.instance;
  final storage = StorageService.instance;

  String? _inputPath;
  String? _outputPath;
  ProcessingState _state = ProcessingState.idle;
  double _progress = 0;
  String _errorMessage = '';
  bool _disposed = false;

  String? get inputPath => _inputPath;
  String? get outputPath => _outputPath;
  ProcessingState get state => _state;
  double get progress => _progress;
  String get errorMessage => _errorMessage;
  bool get hasInput => _inputPath != null;
  bool get hasOutput => _outputPath != null;
  bool get isBusy => _state == ProcessingState.processing;

  /// Called after a new input file has been chosen and reset.
  @protected
  Future<void> onInputChanged(String path) async {}

  /// Called by [reset] so subclasses can clear their own fields.
  @protected
  void onReset() {}

  Future<void> pickVideo() async {
    if (isBusy) return;
    final path = await fileService.pickVideo();
    if (path == null) return;
    await setInput(path);
  }

  /// Sets [path] as the input and clears any previous result.
  Future<void> setInput(String path) async {
    await _discardOutput();
    _inputPath = path;
    _state = ProcessingState.loading;
    _progress = 0;
    _errorMessage = '';
    notifyListeners();
    await onInputChanged(path);
    if (_state == ProcessingState.loading) _state = ProcessingState.idle;
    notifyListeners();
  }

  /// Runs [job] and stores its result. [job] gets the output path and a
  /// progress callback. It must return true when FFmpeg succeeded.
  Future<void> runJob({
    required String suffix,
    required String extension,
    required Future<bool> Function(
            String outputPath, void Function(double) onProgress)
        job,
    String failMessage = 'Processing failed. Please try again.',
  }) async {
    if (isBusy) return;

    // Jobs that do not use FFmpeg must not see stale results from the last one.
    ffmpeg.lastError = '';
    ffmpeg.wasCancelled = false;

    await _discardOutput();
    _state = ProcessingState.processing;
    _progress = 0;
    _errorMessage = '';
    notifyListeners();

    try {
      final outPath = await ffmpeg.createOutputPath(
        suffix: suffix,
        extension: extension,
        baseName: _inputPath,
      );
      var lastShown = -1;
      final ok = await job(outPath, (value) {
        final percent = (value * 100).floor();
        if (percent == lastShown) return;
        lastShown = percent;
        _progress = value;
        _notify();
      });

      if (ok && await File(outPath).exists()) {
        _outputPath = outPath;
        _state = ProcessingState.done;
        await onSuccess(outPath);
      } else if (ffmpeg.wasCancelled) {
        _state = ProcessingState.idle;
        await File(outPath).delete().catchError((_) => File(outPath));
      } else {
        _state = ProcessingState.error;
        _errorMessage = ffmpeg.lastError.isNotEmpty
            ? '$failMessage\n${ffmpeg.lastError}'
            : failMessage;
        await File(outPath).delete().catchError((_) => File(outPath));
      }
    } catch (e) {
      _state = ProcessingState.error;
      _errorMessage = e.toString();
    }
    _notify();
  }

  /// Puts the tool into the error state with [message].
  @protected
  void reportError(String message) {
    _state = ProcessingState.error;
    _errorMessage = message;
  }

  /// Hook for subclasses to read data from the finished output.
  @protected
  Future<void> onSuccess(String outputPath) async {}

  /// Removes the finished result so the tool's options can be edited again.
  Future<void> discardResult() async {
    if (isBusy) return;
    await _discardOutput();
    _state = ProcessingState.idle;
    _errorMessage = '';
    notifyListeners();
  }

  /// Stops the running job.
  Future<void> cancel() => ffmpeg.cancel();

  void reset() {
    _discardOutput();
    _inputPath = null;
    _state = ProcessingState.idle;
    _progress = 0;
    _errorMessage = '';
    onReset();
    notifyListeners();
  }

  Future<bool> saveToGallery() async {
    final path = _outputPath;
    if (path == null) return false;
    return storage.saveVideoToGallery(path);
  }

  Future<void> share() async {
    final path = _outputPath;
    if (path == null) return;
    await storage.shareFilePath(path);
  }

  /// Called when the finished output is thrown away (new input or new run),
  /// so subclasses can delete any extra files they created.
  @protected
  Future<void> onOutputDiscarded() async {}

  Future<void> _discardOutput() async {
    await onOutputDiscarded();
    final old = _outputPath;
    _outputPath = null;
    if (old != null) {
      await File(old).delete().catchError((_) => File(old));
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
