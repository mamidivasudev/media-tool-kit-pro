import 'package:flutter/material.dart';

import '../../core/services/ffmpeg_service.dart';
import '../../providers/extract_mp3_provider.dart';
import '../../widgets/tool_widgets.dart';

class ExtractMp3Screen extends StatelessWidget {
  const ExtractMp3Screen({super.key});

  static const _bitrates = [128, 192, 256, 320];

  @override
  Widget build(BuildContext context) {
    return ToolScaffold<ExtractMp3Provider>(
      title: 'Extract Audio',
      infoIcon: Icons.music_note_rounded,
      infoText: 'Pull the audio track out of a video and save it as '
          'MP3, M4A or WAV.',
      progressMessage: 'Extracting audio...',
      children: (context, p) => [
        FilePickSection(
          path: p.inputPath,
          enabled: !p.isBusy,
          onPick: p.pickVideo,
        ),
        const SizedBox(height: 20),
        ChoiceSection<AudioFormat>(
          title: 'Format',
          values: AudioFormat.values,
          selected: p.format,
          labelOf: (f) => f.label,
          onSelected: p.setFormat,
        ),
        if (p.format.usesBitrate) ...[
          const SizedBox(height: 16),
          ChoiceSection<int>(
            title: 'Quality',
            values: _bitrates,
            selected: p.bitrate,
            labelOf: (b) => '$b kbps',
            onSelected: p.setBitrate,
          ),
        ] else ...[
          const SizedBox(height: 8),
          Text(
            'WAV is uncompressed, so the file will be large.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 20),
        ProcessButton(
          label: 'Extract ${p.format.extension.toUpperCase()}',
          icon: Icons.audiotrack_rounded,
          enabled: p.hasInput && !p.isBusy,
          onPressed: p.process,
        ),
        if (p.state == ProcessingState.done && p.outputPath != null) ...[
          const SizedBox(height: 24),
          ResultPanel(
            title: 'Audio extracted!',
            detail: 'File size: ${p.outputSizeFormatted}',
            filePath: p.outputPath!,
            kind: ResultKind.audio,
            color: Colors.teal,
            onSaveToDevice: p.saveToDevice,
            onShare: p.share,
          ),
        ],
      ],
    );
  }
}
