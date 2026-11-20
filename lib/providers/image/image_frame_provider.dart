import '../../core/services/image_service.dart';
import 'base_image_provider.dart';

enum FrameMode { fit, border }

enum FrameShape {
  square('1:1 Post', 1080, 1080),
  portrait('4:5 Portrait', 1080, 1350),
  tall('3:4', 1080, 1440),
  story('9:16 Story', 1080, 1920),
  wide('16:9 Wide', 1920, 1080);

  final String label;
  final int width;
  final int height;
  const FrameShape(this.label, this.width, this.height);
}

/// Provider for fitting a picture into a frame, or adding a border.
class ImageFrameProvider extends BaseImageProvider {
  static const Map<String, String> borderColors = {
    'White': 'white',
    'Black': 'black',
    'Gray': '0x808080',
    'Red': '0xE53935',
    'Blue': '0x1E88E5',
  };

  FrameMode _mode = FrameMode.fit;
  FrameShape _shape = FrameShape.square;
  FrameBackground _background = FrameBackground.blur;
  double _borderPercent = 5;
  String _borderColor = 'White';

  FrameMode get mode => _mode;
  FrameShape get shape => _shape;
  FrameBackground get background => _background;
  double get borderPercent => _borderPercent;
  String get borderColor => _borderColor;

  void setMode(FrameMode v) {
    _mode = v;
    notifyListeners();
  }

  void setShape(FrameShape v) {
    _shape = v;
    notifyListeners();
  }

  void setBackground(FrameBackground v) {
    _background = v;
    notifyListeners();
  }

  void setBorderPercent(double v) {
    _borderPercent = v;
    notifyListeners();
  }

  void setBorderColor(String v) {
    _borderColor = v;
    notifyListeners();
  }

  Future<void> process() {
    if (!hasInput || imageWidth == 0) return Future.value();
    final mode = _mode;
    return runJob(
      suffix: mode == FrameMode.fit ? 'framed' : 'border',
      extension: 'jpg',
      failMessage: 'Applying the frame failed.',
      job: (out, onProgress) {
        if (mode == FrameMode.fit) {
          return imageTools.fitToFrame(
            input: inputPath!,
            output: out,
            width: _shape.width,
            height: _shape.height,
            background: _background,
          );
        }
        final shorter = imageWidth < imageHeight ? imageWidth : imageHeight;
        final thickness =
            (shorter * _borderPercent / 100).round().clamp(1, 2000);
        return imageTools.addBorder(
          input: inputPath!,
          output: out,
          thickness: thickness,
          colorName: borderColors[_borderColor] ?? 'white',
        );
      },
    );
  }

  @override
  ImageFormat get sameFormat => ImageFormat.jpg;
}
