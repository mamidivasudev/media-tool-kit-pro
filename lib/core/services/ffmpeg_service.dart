import 'dart:async';
import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Basic facts about a media file, read with FFprobe.
class MediaInfo {
  final double durationSecs;
  final bool hasVideo;
  final bool hasAudio;
  final int width;
  final int height;
  final String videoCodec;
  final String audioCodec;
  final String frameRate;
  final String sampleRate;

  const MediaInfo({
    this.durationSecs = 0,
    this.hasVideo = false,
    this.hasAudio = false,
    this.width = 0,
    this.height = 0,
    this.videoCodec = '',
    this.audioCodec = '',
    this.frameRate = '',
    this.sampleRate = '',
  });

  /// True when [other] can be joined to this file with a stream copy.
  bool isConcatCompatibleWith(MediaInfo other) =>
      hasVideo == other.hasVideo &&
      hasAudio == other.hasAudio &&
      width == other.width &&
      height == other.height &&
      videoCodec == other.videoCodec &&
      audioCodec == other.audioCodec &&
      frameRate == other.frameRate &&
      sampleRate == other.sampleRate;
}

/// Output containers the converter can write.
enum VideoFormat {
  mp4('MP4', 'mp4'),
  mkv('MKV', 'mkv'),
  mov('MOV', 'mov'),
  webm('WEBM', 'webm'),
  avi('AVI', 'avi');

  final String label;
  final String extension;
  const VideoFormat(this.label, this.extension);
}

/// Audio formats that can be extracted from a video.
enum AudioFormat {
  mp3('MP3', 'mp3', 'audio/mpeg', true),
  m4a('M4A (AAC)', 'm4a', 'audio/mp4', true),
  wav('WAV', 'wav', 'audio/wav', false);

  final String label;
  final String extension;
  final String mimeType;
  final bool usesBitrate;
  const AudioFormat(
      this.label, this.extension, this.mimeType, this.usesBitrate);
}

/// How a video can be rotated or flipped.
enum RotateOption {
  cw90('Rotate 90° right', 'transpose=1'),
  ccw90('Rotate 90° left', 'transpose=2'),
  rotate180('Rotate 180°', 'hflip,vflip'),
  flipH('Flip horizontally', 'hflip'),
  flipV('Flip vertically', 'vflip');

  final String label;
  final String filter;
  const RotateOption(this.label, this.filter);
}

/// Core FFmpeg service that wraps all FFmpeg operations.
///
/// Only one job runs at a time. Every operation returns `true` on success.
/// On failure, [lastError] holds a readable reason, and [wasCancelled] tells
/// whether the user stopped the job.
class FFmpegService {
  FFmpegService._();
  static final FFmpegService instance = FFmpegService._();

  static const _filePrefix = 'vtpro_';

  String lastError = '';
  bool wasCancelled = false;
  bool _cancelRequested = false;

  // ─── Operations ───────────────────────────────────────────────────────────

  /// Joins videos in order. Uses a fast stream copy when every clip has
  /// identical settings, otherwise re-encodes them to a common size.
  Future<bool> mergeVideos({
    required List<String> inputPaths,
    required String outputPath,
    void Function(double progress)? onProgress,
  }) async {
    final infos = <MediaInfo>[];
    for (final path in inputPaths) {
      infos.add(await probe(path));
    }
    final total = infos.fold<double>(0, (sum, i) => sum + i.durationSecs);
    final compatible =
        infos.every((i) => i.isConcatCompatibleWith(infos.first));

    if (compatible) {
      final listFile = await _createConcatList(inputPaths);
      try {
        final ok = await _run(
          [
            '-f',
            'concat',
            '-safe',
            '0',
            '-i',
            listFile.path,
            '-c',
            'copy',
            '-movflags',
            '+faststart',
            outputPath
          ],
          expectedSecs: total,
          onProgress: onProgress,
        );
        if (ok) return true;
      } finally {
        await listFile.delete().catchError((_) => listFile);
      }
      if (wasCancelled) return false;
      // Stream copy failed; fall through to the re-encoding path.
    }

    // Re-encode: scale every clip to the first clip's size, then concat filter.
    final first = infos.first;
    final w = (first.width > 0 ? first.width : 1280) ~/ 2 * 2;
    final h = (first.height > 0 ? first.height : 720) ~/ 2 * 2;
    final args = <String>[];
    final filter = StringBuffer();
    for (var i = 0; i < inputPaths.length; i++) {
      args.addAll(['-i', inputPaths[i]]);
      filter.write('[$i:v]scale=$w:$h:force_original_aspect_ratio=decrease,'
          'pad=$w:$h:(ow-iw)/2:(oh-ih)/2,setsar=1,fps=30,format=yuv420p[v$i];');
      if (infos[i].hasAudio) {
        filter.write('[$i:a]aresample=44100,'
            'aformat=sample_fmts=fltp:channel_layouts=stereo[a$i];');
      } else {
        filter.write('anullsrc=r=44100:cl=stereo,'
            'atrim=duration=${infos[i].durationSecs.toStringAsFixed(3)}[a$i];');
      }
    }
    for (var i = 0; i < inputPaths.length; i++) {
      filter.write('[v$i][a$i]');
    }
    filter.write('concat=n=${inputPaths.length}:v=1:a=1[v][a]');
    args.addAll([
      '-filter_complex',
      filter.toString(),
      '-map',
      '[v]',
      '-map',
      '[a]',
      ..._h264Args(),
      outputPath,
    ]);
    return _run(args, expectedSecs: total, onProgress: onProgress);
  }

  /// Removes the audio track from a video.
  Future<bool> removeAudio({
    required String inputPath,
    required String outputPath,
    void Function(double progress)? onProgress,
  }) {
    return _run(
      [
        '-i',
        inputPath,
        '-c',
        'copy',
        '-an',
        '-movflags',
        '+faststart',
        outputPath
      ],
      inputPath: inputPath,
      onProgress: onProgress,
    );
  }

  /// Extracts the audio track from a video.
  Future<bool> extractAudio({
    required String inputPath,
    required String outputPath,
    AudioFormat format = AudioFormat.mp3,
    int bitrateKbps = 192,
    void Function(double progress)? onProgress,
  }) async {
    final info = await probe(inputPath);
    if (!info.hasAudio) {
      lastError = 'This video has no audio track.';
      wasCancelled = false;
      return false;
    }
    final codec = switch (format) {
      AudioFormat.mp3 => ['-c:a', 'libmp3lame', '-b:a', '${bitrateKbps}k'],
      AudioFormat.m4a => ['-c:a', 'aac', '-b:a', '${bitrateKbps}k'],
      AudioFormat.wav => ['-c:a', 'pcm_s16le'],
    };
    return _run(
      ['-i', inputPath, '-vn', '-map', '0:a:0', ...codec, outputPath],
      expectedSecs: info.durationSecs,
      onProgress: onProgress,
    );
  }

  /// Cuts a segment. With [precise] the clip is re-encoded for frame-accurate
  /// cuts; otherwise it is a fast stream copy that snaps to keyframes.
  Future<bool> cutSegment({
    required String inputPath,
    required String outputPath,
    required double startSecs,
    required double endSecs,
    bool precise = false,
    String? overlayText,
    void Function(double progress)? onProgress,
  }) async {
    final length = endSecs - startSecs;
    String? overlayFilter;
    if (overlayText != null) {
      final font = await _findFont();
      if (font == null) {
        lastError = 'No system font found to draw the clip numbers.';
        wasCancelled = false;
        return false;
      }
      overlayFilter = "drawtext=fontfile=$font:text='$overlayText':"
          'x=w-tw-w/30:y=h/30:fontsize=h/24:fontcolor=white:'
          'box=1:boxcolor=black@0.5:boxborderw=8';
    }
    return _run(
      [
        '-ss',
        _formatTime(startSecs),
        '-i',
        inputPath,
        '-t',
        _formatTime(length),
        if (precise) ...[
          if (overlayFilter != null) ...['-vf', overlayFilter],
          ..._h264Args(),
        ]
        else ...[
          '-c',
          'copy',
          '-avoid_negative_ts',
          'make_zero',
          '-movflags',
          '+faststart',
        ],
        outputPath,
      ],
      expectedSecs: length,
      onProgress: onProgress,
    );
  }

  /// Finds a font file FFmpeg can use for text overlays.
  Future<String?> _findFont() async {
    for (final path in const [
      '/system/fonts/Roboto-Regular.ttf',
      '/system/fonts/RobotoStatic-Regular.ttf',
      '/system/fonts/DroidSans.ttf',
      '/system/fonts/NotoSans-Regular.ttf',
    ]) {
      if (await File(path).exists()) return path;
    }
    return null;
  }

  /// Trims a video from [startSecs] to [endSecs] with re-encoding for accuracy.
  Future<bool> trimVideo({
    required String inputPath,
    required String outputPath,
    required double startSecs,
    required double endSecs,
    void Function(double progress)? onProgress,
  }) {
    return cutSegment(
      inputPath: inputPath,
      outputPath: outputPath,
      startSecs: startSecs,
      endSecs: endSecs,
      precise: true,
      onProgress: onProgress,
    );
  }

  /// Compresses a video. [maxHeight] of 0 keeps the original resolution.
  Future<bool> compressVideo({
    required String inputPath,
    required String outputPath,
    required int crf,
    int maxHeight = 0,
    void Function(double progress)? onProgress,
  }) {
    return _run(
      [
        '-i',
        inputPath,
        if (maxHeight > 0) ...['-vf', 'scale=-2:min($maxHeight\\,ih)'],
        ..._h264Args(crf: crf),
        outputPath,
      ],
      inputPath: inputPath,
      onProgress: onProgress,
    );
  }

  /// Converts a video to another container/codec combination.
  Future<bool> convertVideo({
    required String inputPath,
    required String outputPath,
    VideoFormat format = VideoFormat.mp4,
    void Function(double progress)? onProgress,
  }) {
    final codec = switch (format) {
      VideoFormat.mp4 || VideoFormat.mov => _h264Args(),
      VideoFormat.mkv => _h264Args(faststart: false),
      VideoFormat.webm => [
          '-c:v',
          'libvpx-vp9',
          '-crf',
          '33',
          '-b:v',
          '0',
          '-deadline',
          'realtime',
          '-cpu-used',
          '8',
          '-row-mt',
          '1',
          '-c:a',
          'libopus',
          '-b:a',
          '128k',
        ],
      VideoFormat.avi => [
          '-c:v',
          'mpeg4',
          '-q:v',
          '4',
          '-c:a',
          'libmp3lame',
          '-b:a',
          '192k',
        ],
    };
    return _run(
      ['-i', inputPath, ...codec, outputPath],
      inputPath: inputPath,
      onProgress: onProgress,
    );
  }

  /// Converts any supported video format to MP4.
  Future<bool> convertToMp4({
    required String inputPath,
    required String outputPath,
    void Function(double progress)? onProgress,
  }) {
    return convertVideo(
      inputPath: inputPath,
      outputPath: outputPath,
      onProgress: onProgress,
    );
  }

  /// Changes playback speed (0.25x to 4x), keeping audio pitch.
  Future<bool> changeSpeed({
    required String inputPath,
    required String outputPath,
    required double speed,
    void Function(double progress)? onProgress,
  }) async {
    final info = await probe(inputPath);
    final video = 'setpts=PTS/${speed.toStringAsFixed(4)}';
    final args = <String>['-i', inputPath];
    if (info.hasAudio) {
      args.addAll([
        '-filter_complex',
        '[0:v]$video[v];[0:a]${_atempoChain(speed)}[a]',
        '-map',
        '[v]',
        '-map',
        '[a]',
      ]);
    } else {
      args.addAll(['-vf', video, '-an']);
    }
    args.addAll([..._h264Args(audio: info.hasAudio), outputPath]);
    return _run(
      args,
      expectedSecs: info.durationSecs / speed,
      onProgress: onProgress,
    );
  }

  /// Rotates or flips a video.
  Future<bool> rotateVideo({
    required String inputPath,
    required String outputPath,
    required RotateOption option,
    void Function(double progress)? onProgress,
  }) {
    return _run(
      [
        '-i',
        inputPath,
        '-vf',
        option.filter,
        ..._h264Args(audio: false),
        '-c:a',
        'copy',
        outputPath,
      ],
      inputPath: inputPath,
      onProgress: onProgress,
    );
  }

  /// Replaces a video's audio with another audio file.
  Future<bool> replaceAudio({
    required String videoPath,
    required String audioPath,
    required String outputPath,
    void Function(double progress)? onProgress,
  }) async {
    final info = await probe(videoPath);
    return _run(
      [
        '-i',
        videoPath,
        '-i',
        audioPath,
        '-map',
        '0:v:0',
        '-map',
        '1:a:0',
        '-c:v',
        'copy',
        '-c:a',
        'aac',
        '-b:a',
        '192k',
        '-shortest',
        '-movflags',
        '+faststart',
        outputPath,
      ],
      expectedSecs: info.durationSecs,
      onProgress: onProgress,
    );
  }

  /// Creates an animated GIF from a section of a video.
  Future<bool> videoToGif({
    required String inputPath,
    required String outputPath,
    required double startSecs,
    required double lengthSecs,
    int fps = 12,
    int width = 480,
    void Function(double progress)? onProgress,
  }) {
    return _run(
      [
        '-ss',
        _formatTime(startSecs),
        '-t',
        _formatTime(lengthSecs),
        '-i',
        inputPath,
        '-vf',
        'fps=$fps,scale=$width:-1:flags=lanczos,split[s0][s1];'
            '[s0]palettegen[p];[s1][p]paletteuse',
        '-loop',
        '0',
        outputPath,
      ],
      expectedSecs: lengthSecs,
      onProgress: onProgress,
    );
  }

  /// Saves a single frame as a JPEG image.
  Future<bool> extractFrame({
    required String inputPath,
    required String outputPath,
    required double atSecs,
  }) {
    return _run(
      [
        '-ss',
        _formatTime(atSecs),
        '-i',
        inputPath,
        '-frames:v',
        '1',
        '-q:v',
        '2',
        outputPath
      ],
      inputPath: inputPath,
    );
  }

  /// Runs any FFmpeg command. Used by [ImageService].
  Future<bool> runCommand(
    List<String> args, {
    String? inputPath,
    double? expectedSecs,
    void Function(double progress)? onProgress,
  }) =>
      _run(args,
          inputPath: inputPath,
          expectedSecs: expectedSecs,
          onProgress: onProgress);

  // ─── Probing ──────────────────────────────────────────────────────────────

  /// Reads duration, size and stream details of [path].
  Future<MediaInfo> probe(String path) async {
    try {
      final session = await FFprobeKit.getMediaInformation(path);
      final info = session.getMediaInformation();
      if (info == null) return const MediaInfo();

      final duration = double.tryParse(info.getDuration() ?? '') ?? 0;
      var hasVideo = false, hasAudio = false;
      var width = 0, height = 0;
      var vCodec = '', aCodec = '', fps = '', rate = '';
      for (final s in info.getStreams()) {
        final type = s.getType();
        if (type == 'video' && !hasVideo) {
          hasVideo = true;
          width = s.getWidth() ?? 0;
          height = s.getHeight() ?? 0;
          vCodec = s.getCodec() ?? '';
          fps = s.getAverageFrameRate() ?? '';
        } else if (type == 'audio' && !hasAudio) {
          hasAudio = true;
          aCodec = s.getCodec() ?? '';
          rate = s.getSampleRate() ?? '';
        }
      }
      return MediaInfo(
        durationSecs: duration,
        hasVideo: hasVideo,
        hasAudio: hasAudio,
        width: width,
        height: height,
        videoCodec: vCodec,
        audioCodec: aCodec,
        frameRate: fps,
        sampleRate: rate,
      );
    } catch (_) {
      return const MediaInfo();
    }
  }

  /// Gets the duration of a media file in seconds, or null if unknown.
  Future<double?> getVideoDuration(String inputPath) async {
    final info = await probe(inputPath);
    return info.durationSecs > 0 ? info.durationSecs : null;
  }

  // ─── Files ────────────────────────────────────────────────────────────────

  /// Creates a unique output path in the app's cache directory.
  ///
  /// When [baseName] is given the file keeps the source name, for example
  /// `holiday_compressed.mp4`.
  Future<String> createOutputPath({
    required String suffix,
    required String extension,
    String? baseName,
  }) async {
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final base = baseName == null
        ? ''
        : '${_safeName(p.basenameWithoutExtension(baseName))}_';
    return p.join(dir.path, '$_filePrefix$base${suffix}_$stamp.$extension');
  }

  /// Deletes temporary files left over from earlier runs.
  Future<int> clearCache() async {
    var freed = 0;
    try {
      final dir = await getTemporaryDirectory();
      await for (final entity in dir.list()) {
        final name = p.basename(entity.path);
        if (entity is File &&
            (name.startsWith(_filePrefix) || name.startsWith('concat_'))) {
          freed += await entity.length();
          await entity.delete().catchError((_) => entity);
        }
      }
    } catch (_) {}
    return freed;
  }

  /// Size in bytes of the files [clearCache] would remove.
  Future<int> cacheSize() async {
    var total = 0;
    try {
      final dir = await getTemporaryDirectory();
      await for (final entity in dir.list()) {
        final name = p.basename(entity.path);
        if (entity is File &&
            (name.startsWith(_filePrefix) || name.startsWith('concat_'))) {
          total += await entity.length();
        }
      }
    } catch (_) {}
    return total;
  }

  /// Stops the job that is currently running.
  Future<void> cancel() async {
    _cancelRequested = true;
    await FFmpegKit.cancel();
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  List<String> _h264Args(
          {int crf = 23, bool audio = true, bool faststart = true}) =>
      [
        '-c:v',
        'libx264',
        '-crf',
        '$crf',
        '-preset',
        'fast',
        '-pix_fmt',
        'yuv420p',
        if (audio) ...['-c:a', 'aac', '-b:a', '128k'],
        if (faststart) ...['-movflags', '+faststart'],
      ];

  String _atempoChain(double speed) {
    final parts = <String>[];
    var remaining = speed;
    while (remaining > 2.0) {
      parts.add('atempo=2.0');
      remaining /= 2.0;
    }
    while (remaining < 0.5) {
      parts.add('atempo=0.5');
      remaining /= 0.5;
    }
    parts.add('atempo=${remaining.toStringAsFixed(4)}');
    return parts.join(',');
  }

  Future<File> _createConcatList(List<String> paths) async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(
        dir.path, 'concat_${DateTime.now().microsecondsSinceEpoch}.txt'));
    final buffer = StringBuffer();
    for (final path in paths) {
      buffer.writeln("file '${path.replaceAll("'", r"'\''")}'");
    }
    await file.writeAsString(buffer.toString());
    return file;
  }

  /// Runs FFmpeg with [args] and reports progress between 0 and 1.
  ///
  /// The expected output length comes from [expectedSecs], or is probed from
  /// [inputPath] when not given.
  Future<bool> _run(
    List<String> args, {
    String? inputPath,
    double? expectedSecs,
    void Function(double progress)? onProgress,
  }) async {
    lastError = '';
    wasCancelled = false;
    _cancelRequested = false;

    var totalMs = (expectedSecs ?? 0) * 1000;
    if (totalMs <= 0 && inputPath != null) {
      totalMs = (await probe(inputPath)).durationSecs * 1000;
    }

    final done = Completer<bool>();
    await FFmpegKit.executeWithArgumentsAsync(
      ['-y', '-hide_banner', ...args],
      (session) async {
        final rc = await session.getReturnCode();
        final ok = ReturnCode.isSuccess(rc);
        if (!ok) {
          if (_cancelRequested || ReturnCode.isCancel(rc)) {
            wasCancelled = true;
          } else {
            lastError = _readableError(await session.getAllLogsAsString());
          }
        }
        if (!done.isCompleted) done.complete(ok);
      },
      null,
      (stats) {
        if (onProgress != null && totalMs > 0) {
          onProgress((stats.getTime() / totalMs).clamp(0.0, 0.99));
        }
      },
    );
    final ok = await done.future;
    if (ok) onProgress?.call(1.0);
    return ok;
  }

  /// Picks the last meaningful lines of an FFmpeg log as an error message.
  String _readableError(String? logs) {
    if (logs == null || logs.trim().isEmpty) {
      return 'Processing failed. The file may be unsupported or damaged.';
    }
    final lines = logs
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final problems = lines.where((l) {
      final lower = l.toLowerCase();
      return lower.contains('error') ||
          lower.contains('invalid') ||
          lower.contains('no such file') ||
          lower.contains('not found') ||
          lower.contains('unsupported') ||
          lower.contains('permission denied') ||
          lower.contains('does not contain');
    }).toList();
    final source = problems.isNotEmpty ? problems : lines;
    final text = source.reversed.take(2).toList().reversed.join('\n');
    return text.length > 300 ? text.substring(text.length - 300) : text;
  }

  String _safeName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_');
    return cleaned.length > 40 ? cleaned.substring(0, 40) : cleaned;
  }

  String _formatTime(double seconds) {
    if (seconds < 0) seconds = 0;
    final h = (seconds / 3600).floor();
    final m = ((seconds % 3600) / 60).floor();
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toStringAsFixed(3).padLeft(6, '0')}';
  }
}
