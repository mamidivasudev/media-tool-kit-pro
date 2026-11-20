/// Formats a duration in seconds to a human-readable string.
class DurationUtils {
  DurationUtils._();

  /// Formats seconds as HH:MM:SS.
  static String formatSeconds(double totalSeconds) {
    final duration = Duration(milliseconds: (totalSeconds * 1000).round());
    return formatDuration(duration);
  }

  /// Formats a Duration to HH:MM:SS string.
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  /// Parses a HH:MM:SS or MM:SS string to seconds.
  static double parseToSeconds(String timeString) {
    final parts = timeString.split(':').map(double.tryParse).toList();
    if (parts.length == 3) {
      return (parts[0] ?? 0) * 3600 + (parts[1] ?? 0) * 60 + (parts[2] ?? 0);
    } else if (parts.length == 2) {
      return (parts[0] ?? 0) * 60 + (parts[1] ?? 0);
    }
    return 0;
  }
}
