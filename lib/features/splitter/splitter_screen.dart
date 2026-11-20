import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/utils/duration_utils.dart';
import '../../providers/splitter_provider.dart';
import '../../widgets/parts_result.dart';
import '../../widgets/tool_widgets.dart';

class SplitterScreen extends StatelessWidget {
  const SplitterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ToolScaffold<SplitterProvider>(
      title: 'Video Splitter',
      infoIcon: Icons.content_cut_rounded,
      infoText: 'Play the video, tap "Add Split Point" where you want a cut, '
          'or split it into equal parts.',
      progressMessage: 'Splitting video...',
      children: (context, p) => [
        FilePickSection(
          path: p.inputPath,
          enabled: !p.isBusy,
          onPick: p.pickVideo,
        ),
        if (p.state == ProcessingState.loading) ...[
          const SizedBox(height: 24),
          const Center(child: CircularProgressIndicator()),
        ] else if (p.videoDuration > 0) ...[
          const SizedBox(height: 16),
          ChoiceSection<SplitMode>(
            title: 'Split by',
            values: SplitMode.values,
            selected: p.mode,
            labelOf: (m) =>
                m == SplitMode.points ? 'Split points' : 'Equal parts',
            onSelected: p.setMode,
          ),
          const SizedBox(height: 16),
          if (p.mode == SplitMode.points)
            _SplitEditor(key: ValueKey(p.inputPath), provider: p)
          else
            _EqualParts(provider: p),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Clip sequence'),
            subtitle: const Text(
                'Show the order on each video clip (e.g. 1/6). Re-encodes '
                'the clips, so it is slower.'),
            value: p.sequence,
            onChanged: p.setSequence,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Precise cuts'),
            subtitle: const Text(
                'Slower, but clips start exactly on time. Off = fast copy '
                'that may start a moment early.'),
            value: p.precise || p.sequence,
            onChanged: p.sequence ? null : p.setPrecise,
          ),
        ],
        const SizedBox(height: 12),
        ProcessButton(
          label: p.mode == SplitMode.points && p.points.isNotEmpty
              ? 'Split into ${p.segments.length} clips'
              : 'Split Video',
          icon: Icons.content_cut_rounded,
          enabled: p.canProcess && !p.isBusy,
          onPressed: p.process,
        ),
        if (p.state == ProcessingState.done && p.partPaths.isNotEmpty) ...[
          const SizedBox(height: 24),
          PartsResult(
            title: 'Video split into ${p.partPaths.length} clips!',
            partLabel: 'Clip',
            paths: p.partPaths,
            onSaveAll: p.saveAllToGallery,
            onShareAll: p.share,
            onSharePart: p.sharePart,
          ),
        ],
      ],
    );
  }
}

class _EqualParts extends StatelessWidget {
  final SplitterProvider provider;
  const _EqualParts({required this.provider});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final maxParts = provider.videoDuration
        .floor()
        .clamp(SplitterProvider.minParts, SplitterProvider.maxParts);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Duration: ${DurationUtils.formatSeconds(provider.videoDuration)}',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          LabeledSlider(
            label: 'Number of parts',
            valueText:
                '${provider.parts} × ${DurationUtils.formatSeconds(provider.partLength)}',
            value: provider.parts.toDouble(),
            min: SplitterProvider.minParts.toDouble(),
            max: maxParts.toDouble(),
            divisions: maxParts > SplitterProvider.minParts
                ? maxParts - SplitterProvider.minParts
                : null,
            onChanged: (v) => provider.setParts(v.round()),
          ),
        ],
      ),
    );
  }
}

/// Video player with a timeline, and an "Add Split Point" button that cuts
/// at the current playback position.
class _SplitEditor extends StatefulWidget {
  final SplitterProvider provider;
  const _SplitEditor({super.key, required this.provider});

  @override
  State<_SplitEditor> createState() => _SplitEditorState();
}

class _SplitEditorState extends State<_SplitEditor> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _failed = false;

  SplitterProvider get _p => widget.provider;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(_p.inputPath!));
    _controller.initialize().then((_) {
      if (mounted) setState(() => _ready = true);
    }).catchError((_) {
      if (mounted) setState(() => _failed = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _position => _controller.value.position.inMilliseconds / 1000;

  void _seek(double secs) {
    final t = secs.clamp(0.0, _p.videoDuration);
    _controller.seekTo(Duration(milliseconds: (t * 1000).round()));
  }

  void _togglePlay() {
    _controller.value.isPlaying ? _controller.pause() : _controller.play();
  }

  void _addPoint() {
    _controller.pause();
    final ok = _p.addPoint(_position);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Move the video a little: split points need at least '
            '0.5 s from the ends and from each other.'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final duration = _p.videoDuration;

    if (_failed) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('Preview is not available for this video.'),
      );
    }
    if (!_ready) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            color: Colors.black,
            height: 280,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
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
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Timeline with split markers.
        ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: _controller,
          builder: (context, value, _) {
            final pos = (value.position.inMilliseconds / 1000)
                .clamp(0.0, duration)
                .toDouble();
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DurationUtils.formatSeconds(pos),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(DurationUtils.formatSeconds(duration)),
                  ],
                ),
                SizedBox(
                  height: 40,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _MarkerPainter(
                              points: _p.points,
                              duration: duration,
                              color: Colors.pinkAccent,
                            ),
                          ),
                        ),
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          overlayShape: SliderComponentShape.noOverlay,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8),
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: pos,
                          min: 0,
                          max: duration,
                          onChanged: _seek,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: '-0.1 s',
              onPressed: () => _seek(_position - 0.1),
              icon: const Icon(Icons.skip_previous_rounded),
            ),
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: _controller,
              builder: (context, value, _) => IconButton.filledTonal(
                onPressed: _togglePlay,
                iconSize: 32,
                icon: Icon(value.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded),
              ),
            ),
            IconButton(
              tooltip: '+0.1 s',
              onPressed: () => _seek(_position + 0.1),
              icon: const Icon(Icons.skip_next_rounded),
            ),
          ],
        ),
        const SizedBox(height: 4),
        FilledButton.icon(
          onPressed: _addPoint,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Split Point'),
          style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52)),
        ),
        if (_p.points.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_p.points.length} split point'
                  '${_p.points.length == 1 ? '' : 's'} · '
                  '${_p.segments.length} clips',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: _p.clearPoints,
                child: const Text('Clear all'),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final point in _p.points)
                InputChip(
                  label: Text(DurationUtils.formatSeconds(point)),
                  avatar: Icon(Icons.content_cut_rounded,
                      size: 16, color: scheme.primary),
                  onPressed: () => _seek(point),
                  onDeleted: () => _p.removePoint(point),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Draws a small marker for every split point above the slider track.
class _MarkerPainter extends CustomPainter {
  final List<double> points;
  final double duration;
  final Color color;

  _MarkerPainter({
    required this.points,
    required this.duration,
    required this.color,
  });

  static const double _inset = 8; // matches the slider thumb radius

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final width = size.width - 2 * _inset;
    for (final point in points) {
      final x = _inset + width * (point / duration);
      canvas.drawLine(
          Offset(x, size.height / 2 - 14), Offset(x, size.height / 2 + 14), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MarkerPainter old) =>
      old.points != points || old.duration != duration;
}
