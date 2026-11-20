import 'dart:io';

import '../../core/services/image_canvas.dart';
import 'base_image_provider.dart';

/// Provider that removes location, camera and date data from a picture.
///
/// The picture is decoded and written again, so nothing from the original
/// file's metadata can survive.
class StripMetadataProvider extends BaseImageProvider {
  Future<void> process() {
    if (!hasInput) return Future.value();
    final target = sameFormat;
    return runJob(
      suffix: 'clean',
      extension: target.extension,
      failMessage: 'Removing metadata failed.',
      job: (out, onProgress) async {
        final image = await ImageCanvas.load(inputPath!, maxSide: 8000);
        final tmp = await imageTools.tempPath('png', 'clean');
        try {
          await ImageCanvas.writePng(image, tmp);
          image.dispose();
          return await imageTools.encodeClean(
              input: tmp, output: out, target: target);
        } finally {
          await File(tmp).delete().catchError((_) => File(tmp));
        }
      },
    );
  }
}
