import 'package:flutter/material.dart';

import '../../providers/compressor_provider.dart';
import '../../widgets/tool_widgets.dart';

class CompressorScreen extends StatelessWidget {
  const CompressorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ToolScaffold<CompressorProvider>(
      title: 'Video Compressor',
      infoIcon: Icons.compress_rounded,
      infoText: 'Reduce video file size by choosing a quality level '
          'and, wjatoptionally, a smaller resolution.',
      progressMessage: 'Compressing video...',
      children: (context, p) => [
        FilePickSection(
          path: p.inputPath,
          enabled: !p.isBusy,
          onPick: p.pickVideo,
        ),
        if (p.hasInput) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.storage_rounded, size: 16),
              const SizedBox(width: 6),
              Text('Original size: ${p.originalSizeFormatted}',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 24),
          _LevelPicker(provider: p),
          const SizedBox(height: 20),
          ChoiceSection<CompressionResolution>(
            title: 'Resolution',
            values: CompressionResolution.values,
            selected: p.resolution,
            labelOf: (r) => r.label,
            onSelected: p.setResolution,
          ),
        ],
        const SizedBox(height: 20),
        ProcessButton(
          label: 'Compress Video',
          icon: Icons.compress_rounded,
          enabled: p.hasInput && !p.isBusy,
          onPressed: p.process,
        ),
        if (p.state == ProcessingState.done && p.outputPath != null) ...[
          const SizedBox(height: 24),
          _SizeComparison(provider: p),
          const SizedBox(height: 16),
          ResultPanel(
            title: 'Compression Complete!',
            filePath: p.outputPath!,
            color: Colors.blue,
            onSave: p.saveToGallery,
            onShare: p.share,
          ),
        ],
      ],
    );
  }
}

class _LevelPicker extends StatelessWidget {
  final CompressorProvider provider;
  const _LevelPicker({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Compression Level'),
        const SizedBox(height: 12),
        Row(
          children: [
            _LevelChip(
              label: 'Low',
              subtitle: 'Best quality',
              color: Colors.green,
              selected: provider.level == CompressionLevel.low,
              onTap: () => provider.setLevel(CompressionLevel.low),
            ),
            const SizedBox(width: 8),
            _LevelChip(
              label: 'Medium',
              subtitle: 'Balanced',
              color: Colors.orange,
              selected: provider.level == CompressionLevel.medium,
              onTap: () => provider.setLevel(CompressionLevel.medium),
            ),
            const SizedBox(width: 8),
            _LevelChip(
              label: 'High',
              subtitle: 'Smallest size',
              color: Colors.red,
              selected: provider.level == CompressionLevel.high,
              onTap: () => provider.setLevel(CompressionLevel.high),
            ),
          ],
        ),
      ],
    );
  }
}

class _LevelChip extends StatelessWidget {
  final String label;
  final String subtitle;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _LevelChip({
    required this.label,
    required this.subtitle,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color:
                selected ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : Colors.grey.withValues(alpha: 0.3),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected ? color : null,
                ),
              ),
              Text(
                subtitle,
                style: textTheme.bodySmall?.copyWith(fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SizeComparison extends StatelessWidget {
  final CompressorProvider provider;
  const _SizeComparison({required this.provider});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final grew = provider.grewInSize;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SizeRow(
              label: 'Original',
              value: provider.originalSizeFormatted,
              color: Colors.orange),
          const SizedBox(height: 6),
          _SizeRow(
              label: 'Compressed',
              value: provider.compressedSizeFormatted,
              color: Colors.blue),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (100 - provider.savedPercentage) / 100,
            color: Colors.blue,
            backgroundColor: Colors.orange.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 4),
          Text(
            grew
                ? 'The result is not smaller. Try a higher level or a lower resolution.'
                : '${provider.savedPercentage.toStringAsFixed(1)}% size reduction',
            style: textTheme.bodySmall?.copyWith(
              color: grew ? Colors.orange : Colors.blue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SizeRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SizeRow(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
