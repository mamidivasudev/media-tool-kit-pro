import 'dart:io';
import 'package:flutter/foundation.dart';

import '../../core/services/image_service.dart';
import '../../core/utils/file_utils.dart';
import '../base_provider.dart';

/// Shared behaviour for tools that work on one picture.
abstract class BaseImageProvider extends BaseToolProvider {
  final imageTools = ImageService.instance;

  int _imageWidth = 0;
  int _imageHeight = 0;
  int _inputBytes = 0;
  int _outputBytes = 0;
  Uint8List? _workBytes;

  int get imageWidth => _imageWidth;
  int get imageHeight => _imageHeight;
  int get inputBytes => _inputBytes;
  int get outputBytes => _outputBytes;
  String get inputSizeText =>
      _inputBytes > 0 ? FileUtils.formatFileSize(_inputBytes) : '--';
  String get outputSizeText =>
      _outputBytes > 0 ? FileUtils.formatFileSize(_outputBytes) : '--';
  String get dimensionsText =>
      _imageWidth > 0 ? '$_imageWidth × $_imageHeight px' : '';

  /// True when a picture is chosen and could be read.
  bool get isReady => hasInput && _imageWidth > 0;

  /// The picture prepared for the crop widget (only for tools that need it).
  Uint8List? get workBytes => _workBytes;

  /// Tools with a crop screen return true to get [workBytes].
  @protected
  bool get needsWorkBytes => false;

  /// The file extension to use when the user did not choose a format.
  String get sameFormatExtension =>
      ImageFormat.of(inputPath ?? 'x.jpg').extension;

  ImageFormat get sameFormat => ImageFormat.of(inputPath ?? 'x.jpg');

  Future<void> pickImage() async {
    if (isBusy) return;
    final path = await fileService.pickImage();
    if (path == null) return;
    await setInput(path);
  }

  @override
  @mustCallSuper
  Future<void> onInputChanged(String path) async {
    _workBytes = null;
    _inputBytes = await FileUtils.getFileSizeBytes(path);
    final info = await ffmpeg.probe(path);
    _imageWidth = info.width;
    _imageHeight = info.height;
    if (info.width == 0) {
      reportError('This picture could not be read. It may be damaged or '
          'in an unsupported format such as HEIC.');
      return;
    }
    if (needsWorkBytes) {
      final tmp = await imageTools.tempPath('jpg', 'work');
      final ok = await imageTools.toJpeg(
          input: path, output: tmp, maxSide: 2560, quality: 95);
      if (ok) _workBytes = await File(tmp).readAsBytes();
      await File(tmp).delete().catchError((_) => File(tmp));
      if (!ok) reportError(ffmpeg.lastError);
    }
  }

  @override
  @mustCallSuper
  Future<void> onSuccess(String outputPath) async {
    _outputBytes = await FileUtils.getFileSizeBytes(outputPath);
  }

  @override
  @mustCallSuper
  void onReset() {
    _imageWidth = 0;
    _imageHeight = 0;
    _inputBytes = 0;
    _outputBytes = 0;
    _workBytes = null;
  }

  @override
  Future<bool> saveToGallery() async {
    final path = outputPath;
    if (path == null) return false;
    return storage.saveImageToGallery(path);
  }

  Future<bool> saveToDevice() async {
    final path = outputPath;
    if (path == null) return false;
    return storage.saveToDevice(path);
  }
}

/// Shared behaviour for tools that take a list of pictures.
abstract class MultiImageProvider extends BaseToolProvider {
  final imageTools = ImageService.instance;

  final List<String> _images = [];

  List<String> get images => List.unmodifiable(_images);
  bool get hasImages => _images.isNotEmpty;
  int get minImages => 1;
  int get maxImages => 30;
  bool get canProcess => _images.length >= minImages;

  Future<void> addImages() async {
    if (isBusy) return;
    final paths = await fileService.pickImages();
    if (paths == null || paths.isEmpty) return;
    final room = maxImages - _images.length;
    _images.addAll(paths.take(room));
    await discardResult();
  }

  void removeImage(int index) {
    if (isBusy) return;
    _images.removeAt(index);
    notifyListeners();
  }

  void reorderImages(int oldIndex, int newIndex) {
    if (isBusy) return;
    if (newIndex > oldIndex) newIndex--;
    final item = _images.removeAt(oldIndex);
    _images.insert(newIndex, item);
    notifyListeners();
  }

  void clearAll() {
    if (isBusy) return;
    _images.clear();
    reset();
  }

  @override
  void onReset() {
    _images.clear();
  }

  @override
  Future<bool> saveToGallery() async {
    final path = outputPath;
    if (path == null) return false;
    return storage.saveImageToGallery(path);
  }

  Future<bool> saveToDevice() async {
    final path = outputPath;
    if (path == null) return false;
    return storage.saveToDevice(path);
  }
}
