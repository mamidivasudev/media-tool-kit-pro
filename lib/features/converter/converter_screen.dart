import 'package:flutter/material.dart';

import '../../core/services/ffmpeg_service.dart';
import '../../core/utils/file_utils.dart';
import '../../providers/converter_provider.dart';
import '../../widgets/tool_widgets.dart';

class ConverterScreen extends StatelessWidget {
  const ConverterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ToolScaffold<ConverterProvider>(
      title: 'Video Converter',
      infoIcon: Icons.swap_horiz_rounded,
      infoText: 'Convert videos between MP4, MKV, MOV, WEBM and AVI. '
          'MP4 works on almost every device.',
      progressMessage: 'Converting video...',
      children: (context, p) => [
        FilePickSection(
          path: p.inputPath,
          label: 'Select Video File',
          changeLabel: 'Change File',
          icon: Icons.file_open_rounded,
          enabled: !p.isBusy,
          onPick: p.pickVideo,
        ),
        const SizedBox(height: 20),
        ChoiceSection<VideoFormat>(
          title: 'Convert to',
          values: VideoFormat.values,
          selected: p.format,
          labelOf: (f) => f.label,
          onSelected: p.setFormat,
        ),
        if (p.format == VideoFormat.webm) ...[
          const SizedBox(height: 8),
          Text(
            'WEBM encoding is slower than the other formats.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 20),
        ProcessButton(
          label: 'Convert to ${p.format.label}',
          icon: Icons.swap_horiz_rounded,
          enabled: p.hasInput && !p.isBusy,
          onPressed: p.process,
        ),
        if (p.state == ProcessingState.done && p.outputPath != null) ...[
          const SizedBox(height: 24),
          FutureBuilder<int>(
            future: FileUtils.getFileSizeBytes(p.outputPath!),
            builder: (context, snap) => ResultPanel(
              title:
                  'Converted to ${FileUtils.getExtension(p.outputPath!).toUpperCase()}!',
              detail: snap.data == null
                  ? null
                  : 'Output size: ${FileUtils.formatFileSize(snap.data!)}',
              filePath: p.outputPath!,
              onSave: p.saveToGallery,
              onShare: p.share,
            ),
          ),
        ],
      ],
    );
  }
}
