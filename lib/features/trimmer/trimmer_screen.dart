import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../providers/trimmer_provider.dart';
import '../../providers/merger_provider.dart';
import '../../widgets/video_thumbnail.dart';
import '../../widgets/progress_overlay.dart';
import '../../widgets/video_preview.dart';
import '../../widgets/parts_result.dart';
import '../../core/utils/duration_utils.dart';
import '../merger/merger_screen.dart' show InfoBanner, ErrorCard;

class TrimmerScreen extends StatelessWidget {
  const TrimmerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Trimmer')),
      body: Consumer<TrimmerProvider>(
        builder: (context, provider, _) {
          return Stack(
            children: [
              _buildBody(context, provider),
              if (provider.state == ProcessingState.processing)
                ProgressOverlay(
                  progress: provider.progress,
                  message: 'Trimming video...',
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, TrimmerProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoBanner(
            icon: Icons.content_cut_rounded,
            text: 'Use the interactive timeline to select your trim range.',
          ),
          const SizedBox(height: 24),
          if (provider.inputPath != null) ...[
            Text(
              'Selected Video',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (provider.videoDuration > 0)
              _TrimPreview(
                key: ValueKey(provider.inputPath),
                filePath: provider.inputPath!,
                start: provider.trimRange.start,
                end: provider.trimRange.end,
              )
            else
              VideoThumbnail(filePath: provider.inputPath!),
            const SizedBox(height: 16),
          ],
          OutlinedButton.icon(
            onPressed: provider.state != ProcessingState.processing
                ? () => context.read<TrimmerProvider>().pickVideo()
                : null,
            icon: const Icon(Icons.video_file_rounded),
            label: Text(provider.hasInput ? 'Change Video' : 'Select Video'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
          ),
          if (provider.videoDuration > 0) ...[
            const SizedBox(height: 24),
            _TrimTimeline(provider: provider),
          ] else if (provider.state == ProcessingState.loading) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: provider.canProcess &&
                    provider.state != ProcessingState.processing
                ? () => context.read<TrimmerProvider>().process()
                : null,
            icon: const Icon(Icons.movie_creation_outlined),
            label: Text(switch (provider.mode) {
              TrimMode.trim => 'Export Trim',
              TrimMode.cutCenter => 'Cut Out Selection',
              TrimMode.twoClips => 'Export Two Clips',
            }),
          ),
          if (provider.state == ProcessingState.done &&
              provider.outputPath != null) ...[
            const SizedBox(height: 24),
            if (provider.partPaths.length > 1)
              PartsResult(
                title: 'Saved as ${provider.partPaths.length} clips!',
                partLabel: 'Clip',
                paths: provider.partPaths,
                onSaveAll: provider.saveAllToGallery,
                onShareAll: provider.share,
                onSharePart: provider.sharePart,
              )
            else
              _TrimmerResult(provider: provider),
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

class _TrimTimeline extends StatelessWidget {
  final TrimmerProvider provider;
  const _TrimTimeline({required this.provider});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final startLabel = DurationUtils.formatSeconds(provider.trimRange.start);
    final endLabel = DurationUtils.formatSeconds(provider.trimRange.end);
    final clipDuration = provider.trimRange.end - provider.trimRange.start;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<TrimMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: TrimMode.trim, label: Text('Trim')),
              ButtonSegment(
                  value: TrimMode.cutCenter, label: Text('Cut center')),
              ButtonSegment(
                  value: TrimMode.twoClips, label: Text('Two clips')),
            ],
            selected: {provider.mode},
            onSelectionChanged: (s) =>
                context.read<TrimmerProvider>().setMode(s.first),
          ),
          const SizedBox(height: 8),
          Text(
            provider.modeHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
          ),
          const SizedBox(height: 16),

          _FilmstripBar(provider: provider),
          const SizedBox(height: 12),

          // Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NudgeTime(
                label: 'Start',
                time: startLabel,
                onMinus: () => context.read<TrimmerProvider>().nudgeStart(-0.1),
                onPlus: () => context.read<TrimmerProvider>().nudgeStart(0.1),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  DurationUtils.formatSeconds(clipDuration),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              _NudgeTime(
                label: 'End',
                time: endLabel,
                onMinus: () => context.read<TrimmerProvider>().nudgeEnd(-0.1),
                onPlus: () => context.read<TrimmerProvider>().nudgeEnd(0.1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeLabel extends StatelessWidget {
  final String label;
  final String time;
  const _TimeLabel({required this.label, required this.time});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
        ),
        Text(
          time,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _TrimmerResult extends StatefulWidget {
  final TrimmerProvider provider;
  const _TrimmerResult({required this.provider});

  @override
  State<_TrimmerResult> createState() => _TrimmerResultState();
}

class _TrimmerResultState extends State<_TrimmerResult> {
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
            color: Colors.pink.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.pink.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.pink, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Video trimmed successfully!',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.pink,
                      ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => setState(() => _showPreview = !_showPreview),
          icon: Icon(_showPreview
              ? Icons.visibility_off_rounded
              : Icons.play_circle_outline_rounded),
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
                              ok ? 'Saved to gallery!' : 'Failed to save.'),
                          behavior: SnackBarBehavior.floating),
                    );
                  }
                },
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save_alt_rounded),
          label: const Text('Save to Gallery'),
          style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52)),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => widget.provider.share(),
          icon: const Icon(Icons.share_rounded),
          label: const Text('Share'),
          style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52)),
        ),
      ],
    );
  }
}

/// Live preview of the picked video that only plays the selected range.
/// Moving the Start handle shows the frame at the start; moving the End
/// handle shows a frame just before the end.
class _TrimPreview extends StatefulWidget {
  final String filePath;
  final double start;
  final double end;

  const _TrimPreview({
    super.key,
    required this.filePath,
    required this.start,
    required this.end,
  });

  @override
  State<_TrimPreview> createState() => _TrimPreviewState();
}

class _TrimPreviewState extends State<_TrimPreview> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _failed = false;

  Duration _secs(double s) => Duration(milliseconds: (s * 1000).round());

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.filePath));
    _controller.addListener(_onTick);
    _controller.initialize().then((_) {
      if (!mounted) return;
      _controller.seekTo(_secs(widget.start));
      setState(() => _ready = true);
    }).catchError((_) {
      if (mounted) setState(() => _failed = true);
    });
  }

  /// Stop at the end of the selected range.
  void _onTick() {
    if (!_ready) return;
    final pos = _controller.value.position;
    if (_controller.value.isPlaying && pos >= _secs(widget.end)) {
      _controller.pause();
      _controller.seekTo(_secs(widget.start));
    }
  }

  @override
  void didUpdateWidget(covariant _TrimPreview old) {
    super.didUpdateWidget(old);
    if (!_ready) return;
    if (old.start != widget.start) {
      _controller.pause();
      _controller.seekTo(_secs(widget.start));
    } else if (old.end != widget.end) {
      _controller.pause();
      final target = (widget.end - 0.3).clamp(widget.start, widget.end);
      _controller.seekTo(_secs(target));
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_controller.value.isPlaying) {
      _controller.pause();
      return;
    }
    final pos = _controller.value.position;
    if (pos < _secs(widget.start) || pos >= _secs(widget.end)) {
      _controller.seekTo(_secs(widget.start));
    }
    _controller.play();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (_failed) return VideoThumbnail(filePath: widget.filePath);
    if (!_ready) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    final aspect = _controller.value.aspectRatio;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: Colors.black,
        height: 280,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: aspect,
                child: VideoPlayer(_controller),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _togglePlay,
              child: ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: _controller,
                builder: (context, value, _) => AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: value.isPlaying ? 0 : 1,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(12),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 40),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 10,
              bottom: 8,
              child: ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: _controller,
                builder: (context, value, _) => Text(
                  DurationUtils.formatSeconds(
                      value.position.inMilliseconds / 1000),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(blurRadius: 4)]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Time with small -/+ buttons for 0.1 s fine tuning.
class _NudgeTime extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _NudgeTime({
    required this.label,
    required this.time,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: onMinus,
          icon: const Icon(Icons.chevron_left_rounded),
          tooltip: '-0.1 s',
        ),
        _TimeLabel(label: label, time: time),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: onPlus,
          icon: const Icon(Icons.chevron_right_rounded),
          tooltip: '+0.1 s',
        ),
      ],
    );
  }
}

/// Filmstrip of video frames with draggable start / end handles.
class _FilmstripBar extends StatelessWidget {
  final TrimmerProvider provider;
  const _FilmstripBar({required this.provider});

  static const double _height = 64;
  static const double _handle = 16;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final duration = provider.videoDuration;
    final range = provider.trimRange;
    final frames = provider.filmstrip;

    return LayoutBuilder(builder: (context, constraints) {
      final inner = constraints.maxWidth - 2 * _handle;
      final startX = _handle + inner * (range.start / duration);
      final endX = _handle + inner * (range.end / duration);
      final read = context.read<TrimmerProvider>();

      Widget handle(double left, bool isStart) => Positioned(
            left: left,
            top: 0,
            width: _handle,
            height: _height,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: (d) {
                final delta = d.delta.dx / inner * duration;
                final r = provider.trimRange;
                read.setTrimRange(isStart
                    ? RangeValues(
                        (r.start + delta).clamp(0, r.end - 0.1), r.end)
                    : RangeValues(r.start,
                        (r.end + delta).clamp(r.start + 0.1, duration)));
              },
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(isStart ? 8 : 0),
                    right: Radius.circular(isStart ? 0 : 8),
                  ),
                ),
                child: const Icon(Icons.drag_indicator_rounded,
                    size: 14, color: Colors.white),
              ),
            ),
          );

      return SizedBox(
        height: _height,
        child: Stack(
          children: [
            Positioned(
              left: _handle,
              right: _handle,
              top: 0,
              bottom: 0,
              child: frames.isEmpty
                  ? Container(color: scheme.outline.withOpacity(0.25))
                  : Row(
                      children: [
                        for (final f in frames)
                          Expanded(
                            child: Image.file(File(f),
                                height: _height,
                                fit: BoxFit.cover,
                                gaplessPlayback: true),
                          ),
                      ],
                    ),
            ),
            // Dim the part that will be dropped: outside the range when
            // trimming, the selection itself when cutting it out.
            if (provider.mode == TrimMode.trim) ...[
              Positioned(
                left: _handle,
                width: startX - _handle,
                top: 0,
                bottom: 0,
                child: Container(color: Colors.black54),
              ),
              Positioned(
                left: endX,
                right: _handle,
                top: 0,
                bottom: 0,
                child: Container(color: Colors.black54),
              ),
            ] else
              Positioned(
                left: startX,
                width: endX - startX,
                top: 0,
                bottom: 0,
                child: Container(color: Colors.black54),
              ),
            // Border around the kept range.
            Positioned(
              left: startX,
              width: endX - startX,
              top: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.symmetric(
                      horizontal: BorderSide(color: scheme.primary, width: 3),
                    ),
                  ),
                ),
              ),
            ),
            handle(startX - _handle, true),
            handle(endX, false),
          ],
        ),
      );
    });
  }
}
