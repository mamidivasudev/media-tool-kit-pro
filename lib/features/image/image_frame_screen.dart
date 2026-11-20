import 'package:flutter/material.dart';

import '../../core/services/image_service.dart';
import '../../providers/image/image_frame_provider.dart';
import '../../widgets/tool_widgets.dart';

class ImageFrameScreen extends StatelessWidget {
  const ImageFrameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ToolScaffold<ImageFrameProvider>(
      title: 'Fit to Frame',
      infoIcon: Icons.crop_free_rounded,
      infoText: 'Fit a whole picture into a post or story shape without '
          'cropping it, or add a border around it.',
      progressMessage: 'Applying frame...',
      children: (context, p) => [
        ImagePickSection(
          path: p.inputPath,
          details: p.dimensionsText,
          enabled: !p.isBusy,
          onPick: p.pickImage,
        ),
        if (p.isReady) ...[
          const SizedBox(height: 20),
          ChoiceSection<FrameMode>(
            title: 'Style',
            values: FrameMode.values,
            selected: p.mode,
            labelOf: (m) =>
                m == FrameMode.fit ? 'Fit into frame' : 'Add border',
            onSelected: p.setMode,
          ),
          const SizedBox(height: 16),
          if (p.mode == FrameMode.fit) ...[
            ChoiceSection<FrameShape>(
              title: 'Shape',
              values: FrameShape.values,
              selected: p.shape,
              labelOf: (s) => s.label,
              onSelected: p.setShape,
            ),
            const SizedBox(height: 16),
            ChoiceSection<FrameBackground>(
              title: 'Background',
              values: FrameBackground.values,
              selected: p.background,
              labelOf: (b) => b.label,
              onSelected: p.setBackground,
            ),
          ] else ...[
            LabeledSlider(
              label: 'Border thickness',
              valueText: '${p.borderPercent.toStringAsFixed(0)}%',
              value: p.borderPercent,
              min: 1,
              max: 20,
              divisions: 19,
              onChanged: p.setBorderPercent,
            ),
            ChoiceSection<String>(
              title: 'Border colour',
              values: ImageFrameProvider.borderColors.keys.toList(),
              selected: p.borderColor,
              labelOf: (c) => c,
              onSelected: p.setBorderColor,
            ),
          ],
        ],
        const SizedBox(height: 20),
        ProcessButton(
          label: p.mode == FrameMode.fit ? 'Fit to Frame' : 'Add Border',
          icon: Icons.crop_free_rounded,
          enabled: p.isReady && !p.isBusy,
          onPressed: p.process,
        ),
        if (p.state == ProcessingState.done && p.outputPath != null) ...[
          const SizedBox(height: 24),
          ResultPanel(
            title: 'Done!',
            detail: p.outputSizeText,
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
