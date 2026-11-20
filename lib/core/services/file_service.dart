import 'dart:io';
import 'package:file_picker/file_picker.dart';

/// Service for picking files using the system file picker.
class FileService {
  FileService._();
  static final FileService instance = FileService._();

  /// Picks a single video file.
  Future<String?> pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );
    return result?.files.single.path;
  }

  /// Picks multiple video files.
  Future<List<String>?> pickMultipleVideos() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: true,
    );
    if (result == null) return null;
    return result.files
        .where((f) => f.path != null)
        .map((f) => f.path!)
        .toList();
  }

  /// Picks a single image.
  Future<String?> pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    return result?.files.single.path;
  }

  /// Picks several images.
  Future<List<String>?> pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (result == null) return null;
    return result.files
        .where((f) => f.path != null)
        .map((f) => f.path!)
        .toList();
  }

  /// Picks an audio file.
  Future<String?> pickAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );
    return result?.files.single.path;
  }

  /// Picks a video file of any supported format.
  Future<String?> pickAnyVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'mp4',
        'mkv',
        'avi',
        'mov',
        'wmv',
        'flv',
        'webm',
        'm4v',
        '3gp'
      ],
      allowMultiple: false,
    );
    return result?.files.single.path;
  }

  /// Deletes the copies the picker made of previously chosen files.
  Future<void> clearPickedFiles() async {
    try {
      await FilePicker.platform.clearTemporaryFiles();
    } catch (_) {}
  }

  /// Returns the file size of [path] in bytes, or null if not found.
  Future<int?> getFileSize(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;
    return await file.length();
  }

  /// Checks whether a file exists at [path].
  Future<bool> fileExists(String path) async {
    return await File(path).exists();
  }
}
