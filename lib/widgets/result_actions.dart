import 'package:flutter/material.dart';

/// Actions row shown after a successful processing operation.
class ResultActions extends StatelessWidget {
  final VoidCallback? onSave;
  final VoidCallback? onShare;
  final VoidCallback? onPreview;
  final bool isAudio;

  const ResultActions({
    super.key,
    this.onSave,
    this.onShare,
    this.onPreview,
    this.isAudio = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (onPreview != null && !isAudio)
          FilledButton.icon(
            onPressed: onPreview,
            icon: const Icon(Icons.play_circle_outline_rounded),
            label: const Text('Preview'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
          ),
        if (onSave != null) ...[
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: onSave,
            icon: Icon(
                isAudio ? Icons.audio_file_rounded : Icons.save_alt_rounded),
            label: const Text('Save to Gallery'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
          ),
        ],
        if (onShare != null) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onShare,
            icon: const Icon(Icons.share_rounded),
            label: const Text('Share'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
          ),
        ],
      ],
    );
  }
}
