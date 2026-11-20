import 'package:flutter/material.dart';

import '../core/utils/file_utils.dart';
import 'video_preview.dart';

/// Result panel for tools that produce several video files (splitter,
/// "two clips" trimming): per-clip preview and share, plus save/share all.
class PartsResult extends StatefulWidget {
  final String title;
  final List<String> paths;
  final String partLabel;
  final Future<bool> Function() onSaveAll;
  final VoidCallback onShareAll;
  final void Function(String path) onSharePart;

  const PartsResult({
    super.key,
    required this.title,
    required this.paths,
    required this.onSaveAll,
    required this.onShareAll,
    required this.onSharePart,
    this.partLabel = 'Part',
  });

  @override
  State<PartsResult> createState() => _PartsResultState();
}

class _PartsResultState extends State<PartsResult> {
  String? _previewPath;
  bool _saving = false;

  Future<void> _saveAll() async {
    setState(() => _saving = true);
    final ok = await widget.onSaveAll();
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'All saved to gallery!' : 'Could not save all.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final parts = widget.paths;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.green, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.green,
                      ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < parts.length; i++)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(child: Text('${i + 1}')),
                  title: Text('${widget.partLabel} ${i + 1}'),
                  subtitle: FutureBuilder<int>(
                    future: FileUtils.getFileSizeBytes(parts[i]),
                    builder: (_, snap) => Text(snap.data == null
                        ? '--'
                        : FileUtils.formatFileSize(snap.data!)),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Preview',
                        icon: Icon(_previewPath == parts[i]
                            ? Icons.visibility_off_rounded
                            : Icons.play_circle_outline_rounded),
                        onPressed: () => setState(() => _previewPath =
                            _previewPath == parts[i] ? null : parts[i]),
                      ),
                      IconButton(
                        tooltip: 'Share',
                        icon: const Icon(Icons.share_rounded),
                        onPressed: () => widget.onSharePart(parts[i]),
                      ),
                    ],
                  ),
                ),
                if (_previewPath == parts[i])
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: VideoPreview(
                        key: ValueKey(parts[i]), filePath: parts[i]),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        FilledButton.tonalIcon(
          onPressed: _saving ? null : _saveAll,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save_alt_rounded),
          label: const Text('Save All to Gallery'),
          style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52)),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: widget.onShareAll,
          icon: const Icon(Icons.share_rounded),
          label: const Text('Share All'),
          style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52)),
        ),
      ],
    );
  }
}
