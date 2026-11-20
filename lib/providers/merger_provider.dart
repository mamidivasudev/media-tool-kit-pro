import 'dart:io';
import 'package:flutter/material.dart';
import '../core/services/ffmpeg_service.dart';
import '../core/services/file_service.dart';
import '../core/services/storage_service.dart';
import 'base_provider.dart';

// Screens import ProcessingState from here.
export 'base_provider.dart' show ProcessingState;

/// Provider for Video Merger feature.
class MergerProvider extends ChangeNotifier {
  final _ffmpeg = FFmpegService.instance;
  final _fileService = FileService.instance;
  final _storage = StorageService.instance;

  final List<String> _selectedVideos = [];
  String? _outputPath;
  ProcessingState _state = ProcessingState.idle;
  double _progress = 0;
  String _errorMessage = '';

  List<String> get selectedVideos => List.unmodifiable(_selectedVideos);
  String? get outputPath => _outputPath;
  ProcessingState get state => _state;
  double get progress => _progress;
  String get errorMessage => _errorMessage;
  bool get canMerge => _selectedVideos.length >= 2;
  bool get hasOutput => _outputPath != null;

  Future<void> pickVideos() async {
    if (_state == ProcessingState.processing) return;
    final paths = await _fileService.pickMultipleVideos();
    if (paths != null && paths.isNotEmpty) {
      _selectedVideos.addAll(paths);
      await _discardOutput();
      _state = ProcessingState.idle;
      notifyListeners();
    }
  }

  void reorderVideos(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final item = _selectedVideos.removeAt(oldIndex);
    _selectedVideos.insert(newIndex, item);
    notifyListeners();
  }

  void removeVideo(int index) {
    _selectedVideos.removeAt(index);
    notifyListeners();
  }

  void clearAll() {
    if (_state == ProcessingState.processing) return;
    _selectedVideos.clear();
    _discardOutput();
    _state = ProcessingState.idle;
    _progress = 0;
    _errorMessage = '';
    notifyListeners();
  }

  Future<void> mergeVideos() async {
    if (!canMerge || _state == ProcessingState.processing) return;

    await _discardOutput();
    _state = ProcessingState.processing;
    _progress = 0;
    _errorMessage = '';
    notifyListeners();

    String? outPath;
    try {
      outPath = await _ffmpeg.createOutputPath(
        suffix: 'merged',
        extension: 'mp4',
      );

      final success = await _ffmpeg.mergeVideos(
        inputPaths: List.of(_selectedVideos),
        outputPath: outPath,
        onProgress: (p) {
          _progress = p;
          notifyListeners();
        },
      );

      if (success) {
        _outputPath = outPath;
        _state = ProcessingState.done;
      } else if (_ffmpeg.wasCancelled) {
        _state = ProcessingState.idle;
      } else {
        _state = ProcessingState.error;
        _errorMessage = _ffmpeg.lastError.isNotEmpty
            ? 'Merge failed.\n${_ffmpeg.lastError}'
            : 'Merge failed. Please try again.';
      }
    } catch (e) {
      _state = ProcessingState.error;
      _errorMessage = e.toString();
    }
    if (_outputPath == null && outPath != null) {
      await File(outPath).delete().catchError((_) => File(outPath!));
    }
    notifyListeners();
  }

  Future<void> cancel() => _ffmpeg.cancel();

  Future<bool> saveToGallery() async {
    if (_outputPath == null) return false;
    return await _storage.saveVideoToGallery(_outputPath!);
  }

  Future<void> share() async {
    if (_outputPath == null) return;
    await _storage.shareVideo(_outputPath!);
  }

  Future<void> _discardOutput() async {
    final old = _outputPath;
    _outputPath = null;
    if (old != null) {
      await File(old).delete().catchError((_) => File(old));
    }
  }
}
