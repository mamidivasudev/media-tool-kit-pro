import 'package:flutter/material.dart';

import '../../providers/speed_provider.dart';
import '../../widgets/tool_widgets.dart';

class SpeedScreen extends StatelessWidget {
  const SpeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ToolScaffold<SpeedProvider>(
      title: 'Speed Changer',
      infoIcon: Icons.speed_rounded,
      infoText: 'Make a video slow motion or fast forward. '
          'The audio pitch stays natural.',
      progressMessage: 'Changing speed...',
      children: (context, p) => [
        FilePickSection(
          path: p.inputPath,
          enabled: !p.isBusy,
          onPick: p.pickVideo,
        ),
        const SizedBox(height: 20),
        ChoiceSection<double>(
          title: 'Speed',
          values: SpeedProvider.speeds,
          selected: p.speed,
          labelOf: SpeedProvider.label,
          onSelected: p.setSpeed,
        ),
        const SizedBox(height: 20),
        ProcessButton(
          label: 'Apply ${SpeedProvider.label(p.speed)} Speed',
          icon: Icons.speed_rounded,
          enabled: p.hasInput && !p.isBusy,
          onPressed: p.process,
        ),
        if (p.state == ProcessingState.done && p.outputPath != null) ...[
          const SizedBox(height: 24),
          ResultPanel(
            title: 'Speed changed!',
            filePath: p.outputPath!,
            onSave: p.saveToGallery,
            onShare: p.share,
          ),
        ],
      ],
    );
  }
}
