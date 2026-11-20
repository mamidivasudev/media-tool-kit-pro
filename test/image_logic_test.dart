import 'package:flutter_test/flutter_test.dart';
import 'package:video_toolkit_pro/core/services/image_service.dart';
import 'package:video_toolkit_pro/providers/image/image_compress_provider.dart';
import 'package:video_toolkit_pro/providers/image/image_crop_provider.dart';
import 'package:video_toolkit_pro/providers/image/passport_provider.dart';

void main() {
  group('ImageFormat.of', () {
    test('picks the format from the file extension', () {
      expect(ImageFormat.of('/a/b/photo.PNG'), ImageFormat.png);
      expect(ImageFormat.of('x.webp'), ImageFormat.webp);
      expect(ImageFormat.of('x.jpeg'), ImageFormat.jpg);
      expect(ImageFormat.of('x.heic'), ImageFormat.jpg);
    });
  });

  group('PassportSize', () {
    test('converts millimetres to pixels at 300 dpi', () {
      expect(PassportSize.mm3545.widthPx, 413);
      expect(PassportSize.mm3545.heightPx, 531);
      expect(PassportSize.us2x2.widthPx, 600);
      expect(PassportSize.us2x2.heightPx, 600);
    });

    test('ratio matches the size', () {
      expect(PassportSize.mm3545.ratio, closeTo(35 / 45, 0.0001));
    });
  });

  group('CropRatio', () {
    test('free has no fixed ratio', () {
      expect(CropRatio.free.ratio, isNull);
      expect(CropRatio.r169.ratio, closeTo(16 / 9, 0.0001));
    });
  });

  group('ImageCompressProvider', () {
    test('labels target sizes', () {
      expect(ImageCompressProvider.targetLabel(100), '100 KB');
      expect(ImageCompressProvider.targetLabel(1024), '1 MB');
    });
  });
}
