import 'dart:io';
import 'dart:math' as math;
import 'package:path/path.dart' as p;
import 'ffmpeg_service.dart';

/// Image file types the app can write.
enum ImageFormat {
  jpg('JPG', 'jpg'),
  png('PNG', 'png'),
  webp('WEBP', 'webp');

  final String label;
  final String extension;
  const ImageFormat(this.label, this.extension);

  /// The format that matches [path]'s extension (JPG when unknown).
  static ImageFormat of(String path) {
    switch (p.extension(path).toLowerCase()) {
      case '.png':
        return ImageFormat.png;
      case '.webp':
        return ImageFormat.webp;
      default:
        return ImageFormat.jpg;
    }
  }
}

/// Where the frame content goes inside a frame tool result.
enum FrameBackground {
  white('White'),
  black('Black'),
  gray('Gray'),
  blur('Blurred photo');

  final String label;
  const FrameBackground(this.label);
}

/// Colour looks for the adjust tool.
enum ImageLook {
  none('Original', ''),
  blackWhite('Black & White', 'hue=s=0'),
  sepia('Sepia',
      'colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131'),
  warm('Warm', 'colorbalance=rs=.12:gs=.02:bs=-.12:rm=.1:bm=-.1'),
  cool('Cool', 'colorbalance=rs=-.12:bs=.12:rm=-.1:bm=.1'),
  blur('Soft blur', 'gblur=sigma=4');

  final String label;
  final String filter;
  const ImageLook(this.label, this.filter);
}

/// FFmpeg based image operations. Every method returns true on success;
/// on failure read [FFmpegService.lastError].
class ImageService {
  ImageService._();
  static final ImageService instance = ImageService._();

  final _ff = FFmpegService.instance;

  // ─── Basic operations ────────────────────────────────────────────────────

  /// Re-encodes [input] as [target].
  Future<bool> convert({
    required String input,
    required String output,
    required ImageFormat target,
    int quality = 92,
  }) {
    return _process(input, output, target, quality: quality);
  }

  /// Scales to exactly [width] x [height].
  Future<bool> resize({
    required String input,
    required String output,
    required int width,
    required int height,
    ImageFormat? target,
    int quality = 92,
  }) {
    return _process(
      input,
      output,
      target ?? ImageFormat.of(output),
      ops: 'scale=$width:$height:flags=lanczos',
      quality: quality,
    );
  }

  /// Shrinks the file by lowering quality and optionally the pixel size.
  Future<bool> compress({
    required String input,
    required String output,
    required ImageFormat target,
    required int quality,
    double scale = 1.0,
  }) async {
    var ops = '';
    if (scale < 1.0) {
      final info = await _ff.probe(input);
      if (info.width > 0) {
        final w = math.max(16, (info.width * scale).round());
        final h = math.max(16, (info.height * scale).round());
        ops = 'scale=$w:$h:flags=lanczos';
      }
    }
    return _process(input, output, target, ops: ops, quality: quality);
  }

  /// Finds the best quality that keeps the file at or under [targetBytes].
  /// The image is also scaled down when quality alone is not enough.
  Future<bool> compressToTarget({
    required String input,
    required String output,
    required int targetBytes,
    ImageFormat target = ImageFormat.jpg,
    void Function(double progress)? onProgress,
  }) async {
    const scales = [1.0, 0.85, 0.7, 0.55, 0.4, 0.3, 0.2];
    const stepsPerScale = 6;
    final total = scales.length * (stepsPerScale + 1);
    var step = 0;

    for (final scale in scales) {
      var lo = 5, hi = 95, best = -1;
      for (var i = 0; i < stepsPerScale && lo <= hi; i++) {
        final mid = (lo + hi) ~/ 2;
        final ok = await compress(
            input: input,
            output: output,
            target: target,
            quality: mid,
            scale: scale);
        onProgress?.call((++step / total).clamp(0.0, 0.95));
        if (!ok) return false;
        if (await File(output).length() <= targetBytes) {
          best = mid;
          lo = mid + 1;
        } else {
          hi = mid - 1;
        }
      }
      if (best > 0) {
        // The last attempt may have been too big; write the best one again.
        return compress(
            input: input,
            output: output,
            target: target,
            quality: best,
            scale: scale);
      }
    }
    await File(output).delete().catchError((_) => File(output));
    _ff.lastError = 'The image could not be made small enough. '
        'Try a larger target size.';
    return false;
  }

  /// Writes a JPEG of [input] (transparent areas become white), optionally
  /// scaled so the longest side is at most [maxSide].
  Future<bool> toJpeg({
    required String input,
    required String output,
    int maxSide = 0,
    int quality = 90,
  }) {
    return _process(
      input,
      output,
      ImageFormat.jpg,
      ops: maxSide > 0
          ? 'scale=min($maxSide\\,iw):min($maxSide\\,ih)'
              ':force_original_aspect_ratio=decrease'
          : '',
      quality: quality,
    );
  }

  /// Applies a rotate or flip filter such as `transpose=1` or `hflip`.
  Future<bool> transform({
    required String input,
    required String output,
    required String filter,
    ImageFormat? target,
  }) {
    return _process(input, output, target ?? ImageFormat.of(input),
        ops: filter, quality: 95);
  }

  /// Rotates by any [degrees]; the corners are filled with white.
  Future<bool> rotateByAngle({
    required String input,
    required String output,
    required double degrees,
    ImageFormat? target,
  }) {
    final a = (degrees * math.pi / 180).toStringAsFixed(5);
    return transform(
      input: input,
      output: output,
      filter: 'rotate=$a:ow=rotw($a):oh=roth($a):fillcolor=white',
      target: target ?? ImageFormat.jpg,
    );
  }

  /// Brightness, contrast, saturation, sharpness and a colour look.
  Future<bool> adjust({
    required String input,
    required String output,
    double brightness = 0,
    double contrast = 1,
    double saturation = 1,
    double sharpness = 0,
    ImageLook look = ImageLook.none,
    ImageFormat? target,
  }) {
    final ops = <String>[
      if (brightness != 0 || contrast != 1 || saturation != 1)
        'eq=brightness=${brightness.toStringAsFixed(3)}'
            ':contrast=${contrast.toStringAsFixed(3)}'
            ':saturation=${saturation.toStringAsFixed(3)}',
      if (look != ImageLook.none) look.filter,
      if (sharpness > 0) 'unsharp=5:5:${sharpness.toStringAsFixed(2)}:5:5:0',
    ];
    return _process(input, output, target ?? ImageFormat.of(input),
        ops: ops.join(','), quality: 95);
  }

  /// Fits the whole picture inside a [width] x [height] frame.
  Future<bool> fitToFrame({
    required String input,
    required String output,
    required int width,
    required int height,
    required FrameBackground background,
    ImageFormat target = ImageFormat.jpg,
  }) {
    if (background == FrameBackground.blur) {
      return _process(
        input,
        output,
        target,
        quality: 95,
        graph: '{in}split[a][b];'
            '[a]scale=$width:$height:force_original_aspect_ratio=increase,'
            'crop=$width:$height,boxblur=30:5[bg];'
            '[b]scale=$width:$height:force_original_aspect_ratio=decrease[fg];'
            '[bg][fg]overlay=(W-w)/2:(H-h)/2',
      );
    }
    final color = switch (background) {
      FrameBackground.white => 'white',
      FrameBackground.black => 'black',
      _ => '0x808080',
    };
    return _process(
      input,
      output,
      target,
      quality: 95,
      ops: 'scale=$width:$height:force_original_aspect_ratio=decrease,'
          'pad=$width:$height:(ow-iw)/2:(oh-ih)/2:color=$color',
    );
  }

  /// Adds a solid border of [thickness] pixels around the picture.
  Future<bool> addBorder({
    required String input,
    required String output,
    required int thickness,
    required String colorName,
    ImageFormat target = ImageFormat.jpg,
  }) {
    return _process(
      input,
      output,
      target,
      quality: 95,
      ops: 'pad=iw+${thickness * 2}:ih+${thickness * 2}:$thickness:$thickness'
          ':color=$colorName',
    );
  }

  /// Scales [input] down so its longest side is at most [maxSide].
  /// Keeps transparency for PNG output. Also bakes in the EXIF rotation.
  Future<bool> normalize({
    required String input,
    required String output,
    int maxSide = 4096,
  }) {
    return _process(
      input,
      output,
      ImageFormat.of(output),
      ops: 'scale=min($maxSide\\,iw):min($maxSide\\,ih)'
          ':force_original_aspect_ratio=decrease',
      quality: 97,
      keepAlpha: true,
    );
  }

  /// Writes [input] to [output] with all metadata removed.
  /// [input] should already be free of EXIF (see ImageCanvas).
  Future<bool> encodeClean({
    required String input,
    required String output,
    required ImageFormat target,
  }) {
    return _process(input, output, target, quality: 96, stripMetadata: true);
  }

  /// Makes a video where each picture is shown for [secondsEach] seconds.
  Future<bool> slideshow({
    required List<String> images,
    required String output,
    required double secondsEach,
    required int width,
    required int height,
    String? audioPath,
    void Function(double progress)? onProgress,
  }) {
    final args = <String>[];
    final graph = StringBuffer();
    for (var i = 0; i < images.length; i++) {
      args.addAll(['-loop', '1', '-t', '$secondsEach', '-i', images[i]]);
      graph.write(
          '[$i:v]scale=$width:$height:force_original_aspect_ratio=decrease,'
          'pad=$width:$height:(ow-iw)/2:(oh-ih)/2:color=black,'
          'setsar=1,fps=30,format=yuv420p[v$i];');
    }
    for (var i = 0; i < images.length; i++) {
      graph.write('[v$i]');
    }
    graph.write('concat=n=${images.length}:v=1:a=0[v]');
    if (audioPath != null) args.addAll(['-i', audioPath]);

    args.addAll([
      '-filter_complex',
      graph.toString(),
      '-map',
      '[v]',
      if (audioPath != null) ...[
        '-map',
        '${images.length}:a:0',
        '-c:a',
        'aac',
        '-b:a',
        '192k',
        '-shortest',
      ],
      '-c:v',
      'libx264',
      '-crf',
      '23',
      '-preset',
      'fast',
      '-pix_fmt',
      'yuv420p',
      '-movflags',
      '+faststart',
      output,
    ]);
    return _ff.runCommand(
      args,
      expectedSecs: images.length * secondsEach,
      onProgress: onProgress,
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Future<String> tempPath(String extension, [String suffix = 'tmp']) =>
      _ff.createOutputPath(suffix: suffix, extension: extension);

  bool _mayHaveAlpha(String path) {
    final ext = p.extension(path).toLowerCase();
    return ext == '.png' || ext == '.webp' || ext == '.gif';
  }

  int _jpegQuality(int quality) =>
      (31 - (quality.clamp(1, 100) / 100) * 29).round().clamp(2, 31);

  List<String> _encodeArgs(ImageFormat format, int quality) {
    switch (format) {
      case ImageFormat.jpg:
        return ['-q:v', '${_jpegQuality(quality)}'];
      case ImageFormat.png:
        return ['-c:v', 'png', '-compression_level', '9'];
      case ImageFormat.webp:
        return ['-c:v', 'libwebp', '-quality', '${quality.clamp(1, 100)}'];
    }
  }

  /// Runs one single-image FFmpeg job.
  ///
  /// [ops] is a linear filter chain. [graph] is a full filter graph that starts
  /// with `{in}` and whose result is the output. JPEG output flattens
  /// transparent sources onto white.
  Future<bool> _process(
    String input,
    String output,
    ImageFormat target, {
    String ops = '',
    String? graph,
    int quality = 92,
    bool keepAlpha = false,
    bool stripMetadata = false,
  }) async {
    var flatten = false;
    var width = 0, height = 0;
    if (target == ImageFormat.jpg && !keepAlpha && _mayHaveAlpha(input)) {
      final info = await _ff.probe(input);
      if (info.width > 0) {
        flatten = true;
        width = info.width;
        height = info.height;
      }
    }

    final parts = <String>[];
    var source = '[0:v]';
    if (flatten) {
      parts.add('color=c=white:s=${width}x$height[bg];'
          '[0:v]format=rgba[fg];'
          '[bg][fg]overlay=format=auto:shortest=1[flat]');
      source = '[flat]';
    }
    if (graph != null) {
      parts.add('${graph.replaceAll('{in}', source)}[out]');
    } else if (ops.isNotEmpty || flatten) {
      parts.add('$source${ops.isEmpty ? 'null' : ops}[out]');
    }

    return _ff.runCommand([
      '-i',
      input,
      if (parts.isNotEmpty) ...[
        '-filter_complex',
        parts.join(';'),
        '-map',
        '[out]',
      ],
      '-frames:v',
      '1',
      if (stripMetadata) ...['-map_metadata', '-1'],
      ..._encodeArgs(target, quality),
      output,
    ]);
  }
}
