import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:gal/gal.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

/// Service for saving files to the gallery or device and sharing them.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  static const _mimeTypes = {
    '.mp4': 'video/mp4',
    '.mkv': 'video/x-matroska',
    '.mov': 'video/quicktime',
    '.webm': 'video/webm',
    '.avi': 'video/x-msvideo',
    '.gif': 'image/gif',
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.png': 'image/png',
    '.mp3': 'audio/mpeg',
    '.m4a': 'audio/mp4',
    '.wav': 'audio/wav',
    '.pdf': 'application/pdf',
    '.txt': 'text/plain',
    '.webp': 'image/webp',
  };

  /// Best-guess MIME type for [filePath], based on its extension.
  String mimeTypeFor(String filePath) =>
      _mimeTypes[p.extension(filePath).toLowerCase()] ??
      'application/octet-stream';

  /// Saves a video file to the device gallery.
  Future<bool> saveVideoToGallery(String filePath) =>
      _saveToGallery(filePath, (path) => Gal.putVideo(path));

  /// Saves an image file (JPEG, PNG, GIF) to the device gallery.
  Future<bool> saveImageToGallery(String filePath) =>
      _saveToGallery(filePath, (path) => Gal.putImage(path));

  Future<bool> _saveToGallery(
    String filePath,
    Future<void> Function(String path) put,
  ) async {
    try {
      if (!await File(filePath).exists()) return false;
      if (!await Gal.hasAccess(toAlbum: false)) {
        final granted = await Gal.requestAccess(toAlbum: false);
        if (!granted) return false;
      }
      await put(filePath);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Lets the user choose where to store a file (used for audio, which the
  /// gallery cannot hold). Returns true when the file was written.
  Future<bool> saveToDevice(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;
      final bytes = await file.readAsBytes();
      final saved = await FilePicker.platform.saveFile(
        dialogTitle: 'Save file',
        fileName: p.basename(filePath),
        bytes: bytes,
      );
      return saved != null;
    } catch (_) {
      return false;
    }
  }

  /// Shares a file using the system share sheet.
  Future<void> shareFile({
    required String filePath,
    required String mimeType,
    String subject = 'Shared from Media Toolkit Pro',
  }) async {
    if (!await File(filePath).exists()) return;
    await Share.shareXFiles(
      [XFile(filePath, mimeType: mimeType)],
      subject: subject,
      text: 'Created with Media Toolkit Pro',
    );
  }

  /// Shares any result file, choosing the MIME type from its extension.
  Future<void> shareFilePath(String filePath) =>
      shareFile(filePath: filePath, mimeType: mimeTypeFor(filePath));

  /// Shares several files at once.
  Future<void> shareFiles(List<String> filePaths) async {
    final existing = <XFile>[];
    for (final path in filePaths) {
      if (await File(path).exists()) {
        existing.add(XFile(path, mimeType: mimeTypeFor(path)));
      }
    }
    if (existing.isEmpty) return;
    await Share.shareXFiles(
      existing,
      subject: 'Shared from Media Toolkit Pro',
      text: 'Created with Media Toolkit Pro',
    );
  }

  /// Shares a video file.
  Future<void> shareVideo(String filePath) => shareFilePath(filePath);

  /// Shares an audio file.
  Future<void> shareAudio(String filePath) => shareFilePath(filePath);
}
