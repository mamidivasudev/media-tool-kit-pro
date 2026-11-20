import 'package:flutter/material.dart';

import '../../core/utils/file_utils.dart';
import '../../providers/image/slideshow_provider.dart';
import '../../widgets/tool_widgets.dart';

class SlideshowScreen extends StatelessWidget {
  const SlideshowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ToolScaffold<SlideshowProvider>(
      title: 'Slideshow Maker',
      infoIcon: Icons.slideshow_rounded,
      infoText: 'Turn pictures into a video, with music if you like. '
          'Drag the list to change the order.',
      progressMessage: 'Creating slideshow...',
      children: (context, p) => [
        ImageListSection(
          images: p.images,
          maxImages: p.maxImages,
          enabled: !p.isBusy,
          hint: 'at least 2',
          onAdd: p.addImages,
          onRemove: p.removeImage,
          onReorder: p.reorderImages,
        ),
        if (p.hasImages) ...[
          const SizedBox(height: 20),
          ChoiceSection<double>(
            title: 'Seconds per picture',
            values: SlideshowProvider.durations,
            selected: p.secondsEach,
            labelOf: (d) => '${d.toInt()} s',
            onSelected: p.setSeconds,
          ),
          const SizedBox(height: 16),
          ChoiceSection<SlideshowSize>(
            title: 'Video shape',
            values: SlideshowSize.values,
            selected: p.size,
            labelOf: (s) => s.label,
            onSelected: p.setSize,
          ),
          const SizedBox(height: 16),
          const SectionTitle('Music (optional)'),
          const SizedBox(height: 8),
          if (p.audioPath != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.audio_file_rounded),
              title: Text(FileUtils.getFileName(p.audioPath!),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: p.removeAudio,
              ),
            ),
          OutlinedButton.icon(
            onPressed: p.isBusy ? null : p.pickAudio,
            icon: const Icon(Icons.audiotrack_rounded),
            label: Text(p.audioPath == null ? 'Add music' : 'Change music'),
            style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48)),
          ),
          const SizedBox(height: 8),
          Text(
            'Video length: ${p.totalSeconds.toStringAsFixed(0)} seconds',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 20),
        ProcessButton(
          label: 'Create Slideshow',
          icon: Icons.slideshow_rounded,
          enabled: p.canProcess && !p.isBusy,
          onPressed: p.process,
        ),
        if (p.state == ProcessingState.done && p.outputPath != null) ...[
          const SizedBox(height: 24),
          ResultPanel(
            title: 'Slideshow created!',
            filePath: p.outputPath!,
            onSave: p.saveToGallery,
            onShare: p.share,
          ),
        ],
      ],
    );
  }
}
