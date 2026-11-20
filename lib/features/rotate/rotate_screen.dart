import 'package:flutter/material.dart';

import '../../core/services/ffmpeg_service.dart';
import '../../providers/rotate_provider.dart';
import '../../widgets/tool_widgets.dart';

class RotateScreen extends StatelessWidget {
  const RotateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ToolScaffold<RotateProvider>(
      title: 'Rotate & Flip',
      infoIcon: Icons.rotate_right_rounded,
      infoText: 'Fix a sideways video, or mirror it. The audio is kept as is.',
      progressMessage: 'Rotating video...',
      children: (context, p) => [
        FilePickSection(
          path: p.inputPath,
          enabled: !p.isBusy,
          onPick: p.pickVideo,
        ),
        const SizedBox(height: 20),
        ChoiceSection<RotateOption>(
          title: 'Action',
          values: RotateOption.values,
          selected: p.option,
          labelOf: (o) => o.label,
          onSelected: p.setOption,
        ),
        const SizedBox(height: 20),
        ProcessButton(
          label: 'Apply',
          icon: Icons.rotate_right_rounded,
          enabled: p.hasInput && !p.isBusy,
          onPressed: p.process,
        ),
        if (p.state == ProcessingState.done && p.outputPath != null) ...[
          const SizedBox(height: 24),
          ResultPanel(
            title: 'Video updated!',
            filePath: p.outputPath!,
            onSave: p.saveToGallery,
            onShare: p.share,
          ),
        ],
      ],
    );
  }
}
