import 'package:flutter/material.dart';
import '../core/utils/file_utils.dart';

/// Displays a video file info card with name, size, and an optional thumbnail.
class VideoThumbnail extends StatelessWidget {
  final String filePath;
  final VoidCallback? onRemove;
  final Widget? trailing;

  const VideoThumbnail({
    super.key,
    required this.filePath,
    this.onRemove,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fileName = FileUtils.getFileName(filePath);
    final ext = FileUtils.getExtension(filePath).toUpperCase();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              ext,
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        title: Text(
          fileName,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: FutureBuilder<int>(
          future: FileUtils.getFileSizeBytes(filePath),
          builder: (context, snapshot) {
            final size = snapshot.data != null
                ? FileUtils.formatFileSize(snapshot.data!)
                : '--';
            return Text(
              size,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            );
          },
        ),
        trailing: onRemove != null
            ? IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: onRemove,
              )
            : trailing,
      ),
    );
  }
}
