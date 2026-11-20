import 'dart:io';
import 'package:path/path.dart' as p;

/// Utility functions for file operations.
class FileUtils {
  FileUtils._();

  /// Formats file size in bytes to a readable string (KB, MB, GB).
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Calculates the percentage reduction between original and compressed size.
  static double calculateSavedPercentage(int original, int compressed) {
    if (original == 0) return 0;
    return ((original - compressed) / original * 100).clamp(0, 100);
  }

  /// Extracts the filename from a full path.
  static String getFileName(String filePath) {
    return p.basename(filePath);
  }

  /// Extracts the file extension from a path (without the dot).
  static String getExtension(String filePath) {
    return p.extension(filePath).replaceFirst('.', '');
  }

  /// Returns the file size in bytes, or 0 if not found.
  static Future<int> getFileSizeBytes(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return 0;
      return await file.length();
    } catch (_) {
      return 0;
    }
  }

  /// Deletes a file if it exists.
  static Future<void> deleteIfExists(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
