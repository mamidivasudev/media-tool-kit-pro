import 'package:flutter/material.dart';

import '../../core/utils/file_utils.dart';
import '../../providers/replace_audio_provider.dart';
import '../../widgets/tool_widgets.dart';

class ReplaceAudioScreen extends StatelessWidget {
  const ReplaceAudioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ToolScaffold<ReplaceAudioProvider>(
      title: 'Add Audio',
      infoIcon: Icons.library_music_rounded,
      infoText: 'Replace a video\'s sound with a song or voice recording. '
          'The result ends when the shorter of the two ends.',
      progressMessage: 'Adding audio...',
      children: (context, p) => [
        const SectionTitle('1. Video'),
        const SizedBox(height: 8),
        FilePickSection(
          path: p.inputPath,
          enabled: !p.isBusy,
          onPick: p.pickVideo,
        ),
        const SizedBox(height: 20),
        const SectionTitle('2. Audio'),
        const SizedBox(height: 8),
        if (p.audioPath != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.audio_file_rounded),
            title: Text(FileUtils.getFileName(p.audioPath!),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        OutlinedButton.icon(
          onPressed: p.isBusy ? null : p.pickAudio,
          icon: const Icon(Icons.audiotrack_rounded),
          label: Text(p.audioPath == null ? 'Select Audio' : 'Change Audio'),
          style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52)),
        ),
        const SizedBox(height: 20),
        ProcessButton(
          label: 'Add Audio to Video',
          icon: Icons.library_music_rounded,
          enabled: p.canProcess && !p.isBusy,
          onPressed: p.process,
        ),
        if (p.state == ProcessingState.done && p.outputPath != null) ...[
          const SizedBox(height: 24),
          ResultPanel(
            title: 'Audio added!',
            filePath: p.outputPath!,
            onSave: p.saveToGallery,
            onShare: p.share,
          ),
        ],
      ],
    );
  }
}
