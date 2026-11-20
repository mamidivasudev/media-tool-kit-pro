import 'package:flutter/material.dart';

import '../../providers/image/strip_metadata_provider.dart';
import '../../widgets/tool_widgets.dart';

class StripMetadataScreen extends StatelessWidget {
  const StripMetadataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ToolScaffold<StripMetadataProvider>(
      title: 'Remove Metadata',
      infoIcon: Icons.shield_rounded,
      infoText: 'Photos can carry hidden details: where they were taken, '
          'the phone model and the date. Remove them before you share.',
      progressMessage: 'Cleaning image...',
      children: (context, p) => [
        ImagePickSection(
          path: p.inputPath,
          details: [p.dimensionsText, p.inputSizeText]
              .where((e) => e.isNotEmpty && e != '--')
              .join(' · '),
          enabled: !p.isBusy,
          onPick: p.pickImage,
        ),
        const SizedBox(height: 16),
        const _RemovedList(),
        const SizedBox(height: 20),
        ProcessButton(
          label: 'Remove Metadata',
          icon: Icons.shield_rounded,
          enabled: p.isReady && !p.isBusy,
          onPressed: p.process,
        ),
        if (p.state == ProcessingState.done && p.outputPath != null) ...[
          const SizedBox(height: 24),
          ResultPanel(
            title: 'Clean copy created!',
            detail:
                'Location, camera and date info removed · ${p.outputSizeText}',
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

class _RemovedList extends StatelessWidget {
  const _RemovedList();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.location_off_rounded, 'GPS location'),
      (Icons.phone_android_rounded, 'Phone and camera model'),
      (Icons.schedule_rounded, 'Date and time taken'),
      (Icons.tune_rounded, 'Camera settings and software'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('What gets removed'),
        const SizedBox(height: 8),
        for (final (icon, label) in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Icon(icon,
                    size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Text(label),
              ],
            ),
          ),
        const SizedBox(height: 6),
        Text(
          'The picture itself looks the same. Your original file is not changed.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
