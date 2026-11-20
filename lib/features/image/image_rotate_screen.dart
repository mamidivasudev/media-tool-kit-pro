import 'package:flutter/material.dart';

import '../../providers/image/image_rotate_provider.dart';
import '../../widgets/tool_widgets.dart';

class ImageRotateScreen extends StatelessWidget {
  const ImageRotateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ToolScaffold<ImageRotateProvider>(
      title: 'Rotate & Flip Image',
      infoIcon: Icons.rotate_right_rounded,
      infoText: 'Turn a picture, mirror it, or straighten a tilted photo '
          'with a custom angle.',
      progressMessage: 'Rotating image...',
      children: (context, p) => [
        ImagePickSection(
          path: p.inputPath,
          details: p.dimensionsText,
          enabled: !p.isBusy,
          onPick: p.pickImage,
        ),
        if (p.isReady) ...[
          const SizedBox(height: 20),
          ChoiceSection<ImageTransform>(
            title: 'Action',
            values: ImageTransform.values,
            selected: p.transform,
            labelOf: (t) => t.label,
            onSelected: p.setTransform,
          ),
          if (p.transform == ImageTransform.custom) ...[
            const SizedBox(height: 12),
            LabeledSlider(
              label: 'Angle',
              valueText: '${p.angle.toStringAsFixed(1)}°',
              value: p.angle,
              min: -45,
              max: 45,
              divisions: 180,
              onChanged: p.setAngle,
            ),
            Text(
              'Empty corners are filled with white.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
        const SizedBox(height: 20),
        ProcessButton(
          label: 'Apply',
          icon: Icons.rotate_right_rounded,
          enabled: p.isReady && p.canProcess && !p.isBusy,
          onPressed: p.process,
        ),
        if (p.state == ProcessingState.done && p.outputPath != null) ...[
          const SizedBox(height: 24),
          ResultPanel(
            title: 'Image updated!',
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
