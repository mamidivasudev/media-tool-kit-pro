import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'base_image_provider.dart';

enum PdfPageSize {
  a4('A4'),
  letter('Letter'),
  fit('Same as picture');

  final String label;
  const PdfPageSize(this.label);
}

enum PdfMargin {
  none('None', 0),
  small('Small', 18),
  large('Large', 40);

  final String label;
  final double points;
  const PdfMargin(this.label, this.points);
}

/// Provider that puts several pictures into one PDF.
class ImagesToPdfProvider extends MultiImageProvider {
  PdfPageSize _pageSize = PdfPageSize.a4;
  PdfMargin _margin = PdfMargin.small;
  int _pageCount = 0;

  PdfPageSize get pageSize => _pageSize;
  PdfMargin get margin => _margin;
  int get pageCount => _pageCount;

  void setPageSize(PdfPageSize value) {
    _pageSize = value;
    notifyListeners();
  }

  void setMargin(PdfMargin value) {
    _margin = value;
    notifyListeners();
  }

  Future<void> process() {
    if (!canProcess) return Future.value();
    final paths = List.of(images);
    final size = _pageSize;
    final margin = _margin.points;

    return runJob(
      suffix: 'images',
      extension: 'pdf',
      failMessage: 'Creating the PDF failed.',
      job: (out, onProgress) async {
        final doc = pw.Document();
        for (var i = 0; i < paths.length; i++) {
          // JPEG keeps the PDF small and works for every source format.
          final tmp = await imageTools.tempPath('jpg', 'pdfpage');
          try {
            final ok = await imageTools.toJpeg(
                input: paths[i], output: tmp, maxSide: 2480, quality: 88);
            if (!ok) return false;
            final image = pw.MemoryImage(await File(tmp).readAsBytes());
            final w = (image.width ?? 1000).toDouble();
            final h = (image.height ?? 1000).toDouble();
            final landscape = w > h;

            final PdfPageFormat format;
            switch (size) {
              case PdfPageSize.a4:
                format =
                    landscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4;
              case PdfPageSize.letter:
                format = landscape
                    ? PdfPageFormat.letter.landscape
                    : PdfPageFormat.letter;
              case PdfPageSize.fit:
                format = PdfPageFormat(w * 0.5, h * 0.5);
            }
            doc.addPage(pw.Page(
              pageFormat: format,
              margin: pw.EdgeInsets.all(size == PdfPageSize.fit ? 0 : margin),
              build: (_) => pw.Center(
                child: pw.Image(image, fit: pw.BoxFit.contain),
              ),
            ));
          } finally {
            await File(tmp).delete().catchError((_) => File(tmp));
          }
          onProgress((i + 1) / paths.length);
        }
        await File(out).writeAsBytes(await doc.save(), flush: true);
        _pageCount = paths.length;
        return true;
      },
    );
  }
}
