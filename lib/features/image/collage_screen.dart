import 'package:flutter/material.dart';

import '../../core/services/image_canvas.dart';
import '../../core/services/image_service.dart';
import '../../providers/image/collage_provider.dart';
import '../../widgets/tool_widgets.dart';

class CollageScreen extends StatelessWidget {
  const CollageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ToolScaffold<CollageProvider>(
      title: 'Collage Maker',
      infoIcon: Icons.dashboard_rounded,
      infoText: 'Combine 2 to 9 pictures into one. Drag the list to change '
          'the order.',
      progressMessage: 'Creating collage...',
      children: (context, p) => [
        ImageListSection(
          images: p.images,
          maxImages: p.maxImages,
          enabled: !p.isBusy,
          hint: 'at least 2',
          onAdd: p.addImages,
          onRemove: p.removeImage,
          onReorder: p.reorderImages,
        ),
        if (p.hasImages) ...[
          const SizedBox(height: 20),
          ChoiceSection<CollageLayout>(
            title: 'Layout',
            values: CollageLayout.values,
            selected: p.layout,
            labelOf: (l) => l.label,
            onSelected: p.setLayout,
          ),
          const SizedBox(height: 12),
          LabeledSlider(
            label: 'Space between pictures',
            valueText: '${p.gap.round()} px',
            value: p.gap,
            min: 0,
            max: 40,
            divisions: 20,
            onChanged: p.setGap,
          ),
          ChoiceSection<String>(
            title: 'Background',
            values: CollageProvider.backgrounds.keys.toList(),
            selected: p.background,
            labelOf: (c) => c,
            onSelected: p.setBackground,
          ),
          const SizedBox(height: 16),
          ChoiceSection<ImageFormat>(
            title: 'Save as',
            values: const [ImageFormat.jpg, ImageFormat.png],
            selected: p.format,
            labelOf: (f) => f.label,
            onSelected: p.setFormat,
          ),
        ],
        const SizedBox(height: 20),
        ProcessButton(
          label: 'Create Collage',
          icon: Icons.dashboard_rounded,
          enabled: p.canProcess && !p.isBusy,
          onPressed: p.process,
        ),
        if (p.state == ProcessingState.done && p.outputPath != null) ...[
          const SizedBox(height: 24),
          ResultPanel(
            title: 'Collage created!',
            filePath: p.outputPath!,
            kind: ResultKind.image,
            onSave: p.saveToGallery,
            onSaveToDevice: p.saveToDevice,
            onShare: p.share,
          ),
        ],
      ],
    );
  }
}
