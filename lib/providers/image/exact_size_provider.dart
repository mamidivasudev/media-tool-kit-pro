import 'dart:io';
import 'dart:math' as math;

import '../../core/services/image_service.dart';
import 'base_image_provider.dart';

enum SizeUnit { px, cm, mm }

enum FitMode { crop, pad, stretch }

/// A ready-made size, e.g. a passport photo.
class ExactPreset {
  final String label;
  final SizeUnit unit;
  final double width;
  final double height;

  /// Suggested file-size limit in KB, or null to leave the limit alone.
  final int? kb;

  const ExactPreset(this.label, this.unit, this.width, this.height, {this.kb});
}

/// Provider for "Exact Size": makes a picture an exact width x height (in
/// pixels, cm or mm) and, optionally, no bigger than a number of KB.
class ExactSizeProvider extends BaseImageProvider {
  static const List<ExactPreset> presets = [
    ExactPreset('Passport 35×45 mm', SizeUnit.mm, 35, 45),
    ExactPreset('Stamp size 25×35 mm', SizeUnit.mm, 25, 35),
    ExactPreset('US passport / visa 2×2 in', SizeUnit.mm, 51, 51, kb: 240),
    ExactPreset('Canada 50×70 mm', SizeUnit.mm, 50, 70),
    ExactPreset('China 33×48 mm', SizeUnit.mm, 33, 48),
    ExactPreset('Exam form 200×230 px', SizeUnit.px, 200, 230, kb: 50),
    ExactPreset('Signature 140×60 px', SizeUnit.px, 140, 60, kb: 30),
  ];

  static const List<int> dpiChoices = [72, 96, 150, 300];
  static const List<int> targetsKb = [20, 30, 50, 100, 200, 500];
  static const List<ImageFormat> formats = [ImageFormat.jpg, ImageFormat.webp];

  SizeUnit _unit = SizeUnit.cm;
  int _dpi = 300;
  double _width = 3.5;
  double _height = 4.5;
  FitMode _fit = FitMode.crop;
  bool _limitSize = true;
  int _targetKb = 50;
  ImageFormat _format = ImageFormat.jpg;

  SizeUnit get unit => _unit;
  int get dpi => _dpi;
  double get width => _width;
  double get height => _height;
  FitMode get fit => _fit;
  bool get limitSize => _limitSize;
  int get targetKb => _targetKb;
  ImageFormat get format => _format;

  int _toPx(double value) {
    final px = switch (_unit) {
      SizeUnit.px => value,
      SizeUnit.cm => value / 2.54 * _dpi,
      SizeUnit.mm => value / 25.4 * _dpi,
    };
    return math.max(1, px.round());
  }

  /// Width and height of the result, in pixels.
  int get pixelWidth => _toPx(_width);
  int get pixelHeight => _toPx(_height);

  /// Human readable size, e.g. "3.5 × 4.5 cm".
  String get sizeText {
    String n(double v) =>
        v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
    return switch (_unit) {
      SizeUnit.px => '${n(_width)} × ${n(_height)} px',
      SizeUnit.cm => '${n(_width)} × ${n(_height)} cm',
      SizeUnit.mm => '${n(_width)} × ${n(_height)} mm',
    };
  }

  bool get validSize =>
      _width > 0 && _height > 0 && pixelWidth <= 12000 && pixelHeight <= 12000;

  bool isPreset(ExactPreset p) =>
      p.unit == _unit && p.width == _width && p.height == _height;

  /// Fills in the unit and size (and file-size limit) from [preset].
  void applyPreset(ExactPreset preset) {
    _unit = preset.unit;
    _width = preset.width;
    _height = preset.height;
    if (preset.kb != null) {
      _limitSize = true;
      _targetKb = preset.kb!;
    }
    notifyListeners();
  }

  void setUnit(SizeUnit unit) {
    _unit = unit;
    notifyListeners();
  }

  void setDpi(int dpi) {
    _dpi = dpi;
    notifyListeners();
  }

  void setWidth(double value) {
    _width = value;
    notifyListeners();
  }

  void setHeight(double value) {
    _height = value;
    notifyListeners();
  }

  void setFit(FitMode fit) {
    _fit = fit;
    notifyListeners();
  }

  void setLimitSize(bool value) {
    _limitSize = value;
    notifyListeners();
  }

  void setTargetKb(int kb) {
    _targetKb = kb;
    notifyListeners();
  }

  void setFormat(ImageFormat format) {
    _format = format;
    notifyListeners();
  }

  Future<void> process() {
    if (!isReady || !validSize) return Future.value();
    final w = pixelWidth;
    final h = pixelHeight;
    final format = _format;
    final fit = switch (_fit) {
      FitMode.crop => 'crop',
      FitMode.pad => 'pad',
      FitMode.stretch => 'stretch',
    };
    final limit = _limitSize ? _targetKb * 1024 : 0;

    return runJob(
      suffix: 'exact',
      extension: format.extension,
      failMessage: 'Could not make the image.',
      job: (out, onProgress) async {
        // No size limit: one pass at good quality.
        if (limit == 0) {
          return imageTools.fitToSize(
            input: inputPath!,
            output: out,
            width: w,
            height: h,
            fit: fit,
            target: format,
          );
        }

        // Step 1: exact pixel size at high quality.
        final sized = await imageTools.tempPath(format.extension, 'exact_big');
        try {
          var ok = await imageTools.fitToSize(
            input: inputPath!,
            output: sized,
            width: w,
            height: h,
            fit: fit,
            target: format,
            quality: 95,
          );
          if (!ok) return false;
          onProgress(0.2);

          // Step 2: highest quality that still fits the KB limit. The pixel
          // size is never changed here.
          var lo = 3, hi = 95, best = -1;
          for (var i = 0; i < 7 && lo <= hi; i++) {
            final mid = (lo + hi) ~/ 2;
            ok = await imageTools.compress(
              input: sized,
              output: out,
              target: format,
              quality: mid,
            );
            onProgress(0.2 + 0.7 * (i + 1) / 7);
            if (!ok) return false;
            if (await File(out).length() <= limit) {
              best = mid;
              lo = mid + 1;
            } else {
              hi = mid - 1;
            }
          }
          if (best < 0) {
            await File(out).delete().catchError((_) => File(out));
            ffmpeg.lastError =
                ('Cannot fit $w × $h px under $_targetKb KB. Use a smaller '
                'size or a higher KB limit.');
            return false;
          }
          // The last attempt may have been too big; write the best one again.
          return imageTools.compress(
            input: sized,
            output: out,
            target: format,
            quality: best,
          );
        } finally {
          await File(sized).delete().catchError((_) => File(sized));
        }
      },
    );
  }
}
