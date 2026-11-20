import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/remove_audio_provider.dart';
import '../../providers/merger_provider.dart';
import '../../widgets/video_thumbnail.dart';
import '../../widgets/progress_overlay.dart';
import '../../widgets/video_preview.dart';
import '../merger/merger_screen.dart' show InfoBanner, ErrorCard;

class RemoveAudioScreen extends StatelessWidget {
  const RemoveAudioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Remove Audio')),
      body: SafeArea(
        top: false,
        child: Consumer<RemoveAudioProvider>(
          builder: (context, provider, _) {
            return Stack(
              children: [
                _buildBody(context, provider),
                if (provider.state == ProcessingState.processing)
                  ProgressOverlay(
                    progress: provider.progress,
                    message: 'Removing audio...',
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, RemoveAudioProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoBanner(
            icon: Icons.volume_off_rounded,
            text:
                'Select a video and create a silent version with all audio removed.',
          ),
          const SizedBox(height: 24),

          // Input file
          if (provider.inputPath != null) ...[
            Text(
              'Selected Video',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            VideoThumbnail(filePath: provider.inputPath!),
            const SizedBox(height: 16),
          ],

          OutlinedButton.icon(
            onPressed: provider.state != ProcessingState.processing
                ? () => context.read<RemoveAudioProvider>().pickVideo()
                : null,
            icon: const Icon(Icons.video_file_rounded),
            label: Text(provider.hasInput ? 'Change Video' : 'Select Video'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
          ),
          const SizedBox(height: 16),

          FilledButton.icon(
            onPressed:
                provider.hasInput &&
                    provider.state != ProcessingState.processing
                ? () => context.read<RemoveAudioProvider>().process()
                : null,
            icon: const Icon(Icons.volume_off_rounded),
            label: const Text('Remove Audio'),
          ),

          // Result
          if (provider.state == ProcessingState.done &&
              provider.outputPath != null) ...[
            const SizedBox(height: 24),
            _RemoveAudioResult(provider: provider),
          ],

          if (provider.state == ProcessingState.error) ...[
            const SizedBox(height: 16),
            ErrorCard(message: provider.errorMessage),
          ],
        ],
      ),
    );
  }
}

class _RemoveAudioResult extends StatefulWidget {
  final RemoveAudioProvider provider;
  const _RemoveAudioResult({required this.provider});

  @override
  State<_RemoveAudioResult> createState() => _RemoveAudioResultState();
}

class _RemoveAudioResultState extends State<_RemoveAudioResult> {
  bool _showPreview = false;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Audio removed successfully!',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => setState(() => _showPreview = !_showPreview),
          icon: Icon(
            _showPreview
                ? Icons.visibility_off_rounded
                : Icons.play_circle_outline_rounded,
          ),
          label: Text(_showPreview ? 'Hide Preview' : 'Preview'),
        ),
        if (_showPreview) ...[
          const SizedBox(height: 12),
          VideoPreview(filePath: widget.provider.outputPath!),
        ],
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: _saving
              ? null
              : () async {
                  setState(() => _saving = true);
                  final ok = await widget.provider.saveToGallery();
                  setState(() => _saving = false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok ? 'Saved to gallery!' : 'Failed to save.',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_alt_rounded),
          label: const Text('Save to Gallery'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => widget.provider.share(),
          icon: const Icon(Icons.share_rounded),
          label: const Text('Share'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
          ),
        ),
      ],
    );
  }
}
