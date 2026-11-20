import 'package:flutter/material.dart';

import '../../core/services/image_service.dart';
import '../../providers/image/image_convert_provider.dart';
import '../../widgets/tool_widgets.dart';

class ImageConvertScreen extends StatelessWidget {
  const ImageConvertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ToolScaffold<ImageConvertProvider>(
      title: 'Image Converter',
      infoIcon: Icons.transform_rounded,
      infoText: 'Convert a picture to JPG, PNG or WEBP. '
          'PNG keeps transparency; JPG gives the smallest file for photos.',
      progressMessage: 'Converting image...',
      children: (context, p) => [
        ImagePickSection(
          path: p.inputPath,
          details: [p.dimensionsText, p.inputSizeText]
              .where((e) => e.isNotEmpty && e != '--')
              .join(' · '),
          enabled: !p.isBusy,
          onPick: p.pickImage,
        ),
        const SizedBox(height: 20),
        ChoiceSection<ImageFormat>(
          title: 'Convert to',
          values: ImageFormat.values,
          selected: p.format,
          labelOf: (f) => f.label,
          onSelected: p.setFormat,
        ),
        if (p.usesQuality) ...[
          const SizedBox(height: 16),
          LabeledSlider(
            label: 'Quality',
            valueText: '${p.quality}%',
            value: p.quality.toDouble(),
            min: 40,
            max: 100,
            divisions: 12,
            onChanged: (v) => p.setQuality(v.round()),
          ),
        ],
        const SizedBox(height: 20),
        ProcessButton(
          label: 'Convert to ${p.format.label}',
          icon: Icons.transform_rounded,
          enabled: p.isReady && !p.isBusy,
          onPressed: p.process,
        ),
        if (p.state == ProcessingState.done && p.outputPath != null) ...[
          const SizedBox(height: 24),
          ResultPanel(
            title: 'Converted to ${p.format.label}!',
            detail: '${p.inputSizeText} → ${p.outputSizeText}',
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
