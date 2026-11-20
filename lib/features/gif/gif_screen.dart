import 'package:flutter/material.dart';

import '../../core/utils/duration_utils.dart';
import '../../providers/gif_provider.dart';
import '../../widgets/tool_widgets.dart';

class GifScreen extends StatelessWidget {
  const GifScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ToolScaffold<GifProvider>(
      title: 'Video to GIF',
      infoIcon: Icons.gif_box_rounded,
      infoText: 'Turn a short part of a video into an animated GIF '
          '(up to ${GifProvider.maxGifSeconds.toInt()} seconds).',
      progressMessage: 'Creating GIF...',
      children: (context, p) => [
        FilePickSection(
          path: p.inputPath,
          enabled: !p.isBusy,
          onPick: p.pickVideo,
        ),
        if (p.state == ProcessingState.loading) ...[
          const SizedBox(height: 24),
          const Center(child: CircularProgressIndicator()),
        ] else if (p.videoDuration > 0) ...[
          const SizedBox(height: 20),
          LabeledSlider(
            label: 'Start',
            valueText: DurationUtils.formatSeconds(p.start),
            value: p.start,
            min: 0,
            max: p.videoDuration,
            onChanged: p.setStart,
          ),
          LabeledSlider(
            label: 'Length',
            valueText: '${p.length.toStringAsFixed(1)} s',
            value: p.length,
            min: 0.5,
            max: p.maxLength,
            onChanged: p.setLength,
          ),
          const SizedBox(height: 8),
          ChoiceSection<int>(
            title: 'Frames per second',
            values: GifProvider.fpsOptions,
            selected: p.fps,
            labelOf: (v) => '$v fps',
            onSelected: p.setFps,
          ),
          const SizedBox(height: 16),
          ChoiceSection<int>(
            title: 'Width',
            values: GifProvider.widthOptions,
            selected: p.width,
            labelOf: (v) => '$v px',
            onSelected: p.setWidth,
          ),
        ],
        const SizedBox(height: 20),
        ProcessButton(
          label: 'Create GIF',
          icon: Icons.gif_box_rounded,
          enabled: p.canProcess && !p.isBusy,
          onPressed: p.process,
        ),
        if (p.state == ProcessingState.done && p.outputPath != null) ...[
          const SizedBox(height: 24),
          ResultPanel(
            title: 'GIF created!',
            detail: 'File size: ${p.outputSizeFormatted}',
            filePath: p.outputPath!,
            kind: ResultKind.image,
            onSave: p.saveToGallery,
            onShare: p.share,
          ),
        ],
      ],
    );
  }
}
