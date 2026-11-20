import 'package:flutter_test/flutter_test.dart';
import 'package:video_toolkit_pro/core/utils/duration_utils.dart';
import 'package:video_toolkit_pro/core/utils/file_utils.dart';
import 'package:video_toolkit_pro/core/services/ffmpeg_service.dart';

void main() {
  group('FileUtils', () {
    test('formats sizes', () {
      expect(FileUtils.formatFileSize(512), '512 B');
      expect(FileUtils.formatFileSize(2048), '2.0 KB');
      expect(FileUtils.formatFileSize(5 * 1024 * 1024), '5.0 MB');
    });

    test('saved percentage is clamped', () {
      expect(FileUtils.calculateSavedPercentage(100, 40), 60);
      expect(FileUtils.calculateSavedPercentage(100, 150), 0);
      expect(FileUtils.calculateSavedPercentage(0, 10), 0);
    });
  });

  group('DurationUtils', () {
    test('formats and parses', () {
      expect(DurationUtils.formatSeconds(65), '01:05');
      expect(DurationUtils.formatSeconds(3725), '01:02:05');
      expect(DurationUtils.parseToSeconds('01:02:05'), 3725);
    });
  });

  group('MediaInfo', () {
    const a = MediaInfo(
        hasVideo: true, hasAudio: true, width: 1920, height: 1080,
        videoCodec: 'h264', audioCodec: 'aac', frameRate: '30/1',
        sampleRate: '44100');

    test('identical clips can be joined without re-encoding', () {
      expect(a.isConcatCompatibleWith(a), isTrue);
    });

    test('different size needs re-encoding', () {
      const b = MediaInfo(
          hasVideo: true, hasAudio: true, width: 1280, height: 720,
          videoCodec: 'h264', audioCodec: 'aac', frameRate: '30/1',
          sampleRate: '44100');
      expect(a.isConcatCompatibleWith(b), isFalse);
    });
  });
}
