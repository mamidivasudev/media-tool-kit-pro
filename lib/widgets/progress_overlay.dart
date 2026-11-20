import 'package:flutter/material.dart';
import '../core/services/ffmpeg_service.dart';

/// Full-screen progress overlay shown during FFmpeg processing.
class ProgressOverlay extends StatelessWidget {
  final double progress;
  final String message;

  const ProgressOverlay({
    super.key,
    required this.progress,
    this.message = 'Processing...',
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 24),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 300),
                builder: (context, value, _) {
                  return Column(
                    children: [
                      LinearProgressIndicator(
                        value: value > 0 ? value : null,
                        borderRadius: BorderRadius.circular(8),
                        minHeight: 8,
                      ),
                      if (value > 0) ...[
                        const SizedBox(height: 12),
                        Text(
                          '${(value * 100).toInt()}%',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Please wait, do not close the app',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => FFmpegService.instance.cancel(),
                icon: const Icon(Icons.close_rounded),
                label: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
