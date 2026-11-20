import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'base_image_provider.dart';

/// Provider that reads the text in a picture. Runs fully on the device.
class OcrProvider extends BaseImageProvider {
  String _text = '';

  String get text => _text;
  int get wordCount =>
      _text.trim().isEmpty ? 0 : _text.trim().split(RegExp(r'\s+')).length;

  Future<void> process() {
    if (!hasInput) return Future.value();
    _text = '';
    return runJob(
      suffix: 'text',
      extension: 'txt',
      failMessage: 'Reading the text failed.',
      job: (out, onProgress) async {
        // A JPEG of moderate size is read faster and works for every source.
        final tmp = await imageTools.tempPath('jpg', 'ocr');
        final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
        try {
          final ok = await imageTools.toJpeg(
              input: inputPath!, output: tmp, maxSide: 3000, quality: 92);
          if (!ok) return false;
          final result =
              await recognizer.processImage(InputImage.fromFilePath(tmp));
          _text = result.text.trim();
          await File(out).writeAsString(_text, flush: true);
          if (_text.isEmpty) {
            ffmpeg.lastError = 'No text was found in this picture.';
            return false;
          }
          return true;
        } finally {
          await recognizer.close();
          await File(tmp).delete().catchError((_) => File(tmp));
        }
      },
    );
  }

  @override
  void onReset() {
    super.onReset();
    _text = '';
  }
}
