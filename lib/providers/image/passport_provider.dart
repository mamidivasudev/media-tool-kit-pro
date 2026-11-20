import 'dart:io';
import 'dart:typed_data';

import '../../core/services/image_canvas.dart';
import '../../core/services/image_service.dart';
import 'base_image_provider.dart';

/// Common passport and ID photo sizes, in millimetres.
enum PassportSize {
  mm3545('35 × 45 mm', 'India, UK, EU, Australia', 35, 45),
  us2x2('2 × 2 in', 'USA, India visa', 50.8, 50.8),
  mm3348('33 × 48 mm', 'China', 33, 48),
  mm2535('25 × 35 mm', 'Small ID', 25, 35);

  final String label;
  final String note;
  final double widthMm;
  final double heightMm;
  const PassportSize(this.label, this.note, this.widthMm, this.heightMm);

  /// Pixel size at 300 dpi.
  int get widthPx => (widthMm / 25.4 * 300).round();
  int get heightPx => (heightMm / 25.4 * 300).round();
  double get ratio => widthMm / heightMm;
}

enum PassportOutput {
  single('Single photo', 0, 0),
  sheet4x6('4×6 in print sheet', 1200, 1800),
  sheetA4('A4 print sheet', 2480, 3508);

  final String label;
  final int sheetWidth;
  final int sheetHeight;
  const PassportOutput(this.label, this.sheetWidth, this.sheetHeight);
}

/// Provider that crops a photo to a passport size and can lay out copies
/// on a sheet for printing.
class PassportProvider extends BaseImageProvider {
  PassportSize _size = PassportSize.mm3545;
  PassportOutput _output = PassportOutput.sheet4x6;
  int _copies = 1;

  PassportSize get size => _size;
  PassportOutput get output => _output;

  /// Number of photos on the finished sheet (1 for a single photo).
  int get copies => _copies;

  @override
  bool get needsWorkBytes => true;

  void setSize(PassportSize v) {
    _size = v;
    notifyListeners();
  }

  void setOutput(PassportOutput v) {
    _output = v;
    notifyListeners();
  }

  Future<void> processCropped(Uint8List bytes) {
    final size = _size;
    final output = _output;
    return runJob(
      suffix: 'passport',
      extension: 'jpg',
      failMessage: 'Creating the photo failed.',
      job: (out, onProgress) async {
        final cropped = await imageTools.tempPath('png', 'pp_crop');
        final exact = await imageTools.tempPath('png', 'pp_exact');
        String? sheet;
        try {
          await File(cropped).writeAsBytes(bytes, flush: true);
          var ok = await imageTools.resize(
            input: cropped,
            output: exact,
            width: size.widthPx,
            height: size.heightPx,
            target: ImageFormat.png,
          );
          if (!ok) return false;

          if (output == PassportOutput.single) {
            _copies = 1;
            return await imageTools.convert(
                input: exact,
                output: out,
                target: ImageFormat.jpg,
                quality: 96);
          }
          final result = await ImageCanvas.printSheet(
            photoPath: exact,
            photoWidth: size.widthPx,
            photoHeight: size.heightPx,
            sheetWidth: output.sheetWidth,
            sheetHeight: output.sheetHeight,
          );
          sheet = result.$1;
          _copies = result.$2;
          ok = await imageTools.convert(
              input: sheet, output: out, target: ImageFormat.jpg, quality: 96);
          return ok;
        } finally {
          for (final path in [cropped, exact, if (sheet != null) sheet]) {
            await File(path).delete().catchError((_) => File(path));
          }
        }
      },
    );
  }

  @override
  void onReset() {
    super.onReset();
    _copies = 1;
  }
}
