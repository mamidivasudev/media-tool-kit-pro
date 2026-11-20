import 'package:flutter/material.dart';

import '../../providers/image/images_to_pdf_provider.dart';
import '../../widgets/tool_widgets.dart';

class ImagesToPdfScreen extends StatelessWidget {
  const ImagesToPdfScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ToolScaffold<ImagesToPdfProvider>(
      title: 'Images to PDF',
      infoIcon: Icons.picture_as_pdf_rounded,
      infoText: 'Put several pictures into one PDF, one picture per page. '
          'Drag to change the order.',
      progressMessage: 'Creating PDF...',
      children: (context, p) => [
        ImageListSection(
          images: p.images,
          maxImages: p.maxImages,
          enabled: !p.isBusy,
          hint: 'drag to reorder',
          onAdd: p.addImages,
          onRemove: p.removeImage,
          onReorder: p.reorderImages,
        ),
        if (p.hasImages) ...[
          const SizedBox(height: 20),
          ChoiceSection<PdfPageSize>(
            title: 'Page size',
            values: PdfPageSize.values,
            selected: p.pageSize,
            labelOf: (s) => s.label,
            onSelected: p.setPageSize,
          ),
          if (p.pageSize != PdfPageSize.fit) ...[
            const SizedBox(height: 16),
            ChoiceSection<PdfMargin>(
              title: 'Margin',
              values: PdfMargin.values,
              selected: p.margin,
              labelOf: (m) => m.label,
              onSelected: p.setMargin,
            ),
          ],
        ],
        const SizedBox(height: 20),
        ProcessButton(
          label: 'Create PDF',
          icon: Icons.picture_as_pdf_rounded,
          enabled: p.canProcess && !p.isBusy,
          onPressed: p.process,
        ),
        if (p.state == ProcessingState.done && p.outputPath != null) ...[
          const SizedBox(height: 24),
          ResultPanel(
            title: 'PDF created!',
            detail: '${p.pageCount} page${p.pageCount == 1 ? '' : 's'}',
            filePath: p.outputPath!,
            kind: ResultKind.document,
            onSaveToDevice: p.saveToDevice,
            onShare: p.share,
          ),
        ],
      ],
    );
  }
}
