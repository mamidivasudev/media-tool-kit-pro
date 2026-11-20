import 'dart:io';
import 'dart:typed_data';

import '../../core/services/image_service.dart';
import 'base_image_provider.dart';

/// Fixed shapes the crop frame can have. [ratio] null means free.
enum CropRatio {
  free('Free', null),
  square('1:1', 1.0),
  r43('4:3', 4 / 3),
  r34('3:4', 3 / 4),
  r169('16:9', 16 / 9),
  r916('9:16', 9 / 16);

  final String label;
  final double? ratio;
  const CropRatio(this.label, this.ratio);
}

/// Provider for the crop tool. The screen shows the crop frame and hands the
/// cropped bytes to [processCropped].
class ImageCropProvider extends BaseImageProvider {
  CropRatio _ratio = CropRatio.free;
  ImageFormat? _format;

  CropRatio get ratio => _ratio;
  ImageFormat get format => _format ?? sameFormat;

  @override
  bool get needsWorkBytes => true;

  void setRatio(CropRatio ratio) {
    _ratio = ratio;
    notifyListeners();
  }

  void setFormat(ImageFormat format) {
    _format = format;
    notifyListeners();
  }

  Future<void> processCropped(Uint8List bytes) {
    final target = format;
    return runJob(
      suffix: 'cropped',
      extension: target.extension,
      failMessage: 'Cropping failed.',
      job: (out, onProgress) async {
        final tmp = await imageTools.tempPath('png', 'crop');
        try {
          await File(tmp).writeAsBytes(bytes, flush: true);
          return await imageTools.convert(
              input: tmp, output: out, target: target, quality: 95);
        } finally {
          await File(tmp).delete().catchError((_) => File(tmp));
        }
      },
    );
  }

  @override
  void onReset() {
    super.onReset();
    _ratio = CropRatio.free;
    _format = null;
  }
}
