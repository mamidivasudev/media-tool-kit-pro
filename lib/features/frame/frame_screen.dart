import 'package:flutter/material.dart';

import '../../core/utils/duration_utils.dart';
import '../../providers/frame_provider.dart';
import '../../widgets/tool_widgets.dart';

class FrameScreen extends StatelessWidget {
  const FrameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ToolScaffold<FrameProvider>(
      title: 'Extract Frame',
      infoIcon: Icons.photo_camera_back_rounded,
      infoText: 'Pick a moment in a video and save it as a picture.',
      progressMessage: 'Extracting frame...',
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
            label: 'Time',
            valueText:
                '${DurationUtils.formatSeconds(p.position)} / ${DurationUtils.formatSeconds(p.videoDuration)}',
            value: p.position,
            min: 0,
            max: p.videoDuration,
            onChanged: p.setPosition,
          ),
        ],
        const SizedBox(height: 20),
        ProcessButton(
          label: 'Extract Frame',
          icon: Icons.photo_camera_back_rounded,
          enabled: p.canProcess && !p.isBusy,
          onPressed: p.process,
        ),
        if (p.state == ProcessingState.done && p.outputPath != null) ...[
          const SizedBox(height: 24),
          ResultPanel(
            title: 'Frame saved as a picture!',
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
