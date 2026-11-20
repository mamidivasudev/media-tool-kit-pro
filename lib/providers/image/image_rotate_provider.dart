import 'base_image_provider.dart';

enum ImageTransform {
  cw90('Rotate 90° right', 'transpose=1'),
  ccw90('Rotate 90° left', 'transpose=2'),
  rotate180('Rotate 180°', 'hflip,vflip'),
  flipH('Flip horizontally', 'hflip'),
  flipV('Flip vertically', 'vflip'),
  custom('Custom angle', '');

  final String label;
  final String filter;
  const ImageTransform(this.label, this.filter);
}

/// Provider for rotating and flipping pictures.
class ImageRotateProvider extends BaseImageProvider {
  ImageTransform _transform = ImageTransform.cw90;
  double _angle = 0;

  ImageTransform get transform => _transform;
  double get angle => _angle;

  void setTransform(ImageTransform value) {
    _transform = value;
    notifyListeners();
  }

  void setAngle(double value) {
    _angle = value;
    notifyListeners();
  }

  bool get canProcess =>
      hasInput && (_transform != ImageTransform.custom || _angle != 0);

  Future<void> process() {
    if (!canProcess) return Future.value();
    final t = _transform;
    final angle = _angle;
    // A custom angle leaves empty corners, so JPEG is always used for it.
    final format = t == ImageTransform.custom ? null : sameFormat;
    return runJob(
      suffix: 'rotated',
      extension: (format ?? sameFormat).extension,
      failMessage: 'Rotate failed.',
      job: (out, onProgress) {
        if (t == ImageTransform.custom) {
          return imageTools.rotateByAngle(
              input: inputPath!,
              output: out,
              degrees: angle,
              target: sameFormat);
        }
        return imageTools.transform(
            input: inputPath!, output: out, filter: t.filter, target: format);
      },
    );
  }

  @override
  void onReset() {
    super.onReset();
    _angle = 0;
  }
}
