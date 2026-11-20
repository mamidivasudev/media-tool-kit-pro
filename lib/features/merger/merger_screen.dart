import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/merger_provider.dart';
import '../../widgets/video_thumbnail.dart';
import '../../widgets/progress_overlay.dart';
import '../../widgets/video_preview.dart';

class MergerScreen extends StatelessWidget {
  const MergerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Merger'),
        actions: [
          Consumer<MergerProvider>(
            builder: (context, provider, _) => TextButton(
              onPressed: provider.selectedVideos.isNotEmpty
                  ? () {
                      provider.clearAll();
                    }
                  : null,
              child: const Text('Clear'),
            ),
          ),
        ],
      ),
      body: Consumer<MergerProvider>(
        builder: (context, provider, _) {
          return Stack(
            children: [
              _buildBody(context, provider),
              if (provider.state == ProcessingState.processing)
                ProgressOverlay(
                  progress: provider.progress,
                  message: 'Merging videos...',
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, MergerProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoBanner(
            icon: Icons.info_outline_rounded,
            text:
                'Select at least 2 videos to merge. Drag to reorder the sequence.',
          ),
          const SizedBox(height: 16),

          // Video list
          if (provider.selectedVideos.isNotEmpty) ...[
            Text(
              'Selected Videos (${provider.selectedVideos.length})',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.selectedVideos.length,
              onReorder: provider.reorderVideos,
              itemBuilder: (context, index) {
                final path = provider.selectedVideos[index];
                return Dismissible(
                  key: ValueKey(path + index.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    color: Colors.red.withOpacity(0.2),
                    child: const Icon(Icons.delete_rounded, color: Colors.red),
                  ),
                  onDismissed: (_) => provider.removeVideo(index),
                  child: VideoThumbnail(
                    key: ValueKey('thumb_$path$index'),
                    filePath: path,
                    trailing: ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_handle_rounded),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],

          // Add video button
          OutlinedButton.icon(
            onPressed: provider.state != ProcessingState.processing
                ? () => context.read<MergerProvider>().pickVideos()
                : null,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Videos'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
          ),

          const SizedBox(height: 16),

          // Merge button
          FilledButton.icon(
            onPressed: provider.canMerge &&
                    provider.state != ProcessingState.processing
                ? () => context.read<MergerProvider>().mergeVideos()
                : null,
            icon: const Icon(Icons.merge_type_rounded),
            label: const Text('Merge Videos'),
          ),

          // Result section
          if (provider.state == ProcessingState.done &&
              provider.outputPath != null) ...[
            const SizedBox(height: 24),
            _ResultSection(provider: provider),
          ],

          // Error message
          if (provider.state == ProcessingState.error) ...[
            const SizedBox(height: 16),
            ErrorCard(message: provider.errorMessage),
          ],
        ],
      ),
    );
  }
}

class _ResultSection extends StatefulWidget {
  final MergerProvider provider;
  const _ResultSection({required this.provider});

  @override
  State<_ResultSection> createState() => _ResultSectionState();
}

class _ResultSectionState extends State<_ResultSection> {
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
              const Icon(Icons.check_circle_rounded,
                  color: Colors.green, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Merge Complete!',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.green,
                          ),
                    ),
                    Text(
                      'Your videos have been merged successfully.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
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

class InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  const InfoBanner({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class ErrorCard extends StatelessWidget {
  final String message;
  const ErrorCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message.isEmpty ? 'An error occurred.' : message,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
