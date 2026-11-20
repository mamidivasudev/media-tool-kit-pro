import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/image_service.dart';
import '../../providers/image/image_compress_provider.dart';
import '../../widgets/tool_widgets.dart';

class ImageCompressScreen extends StatelessWidget {
  const ImageCompressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ToolScaffold<ImageCompressProvider>(
      title: 'Image Compressor',
      infoIcon: Icons.compress_rounded,
      infoText: 'Make a picture smaller to upload or share. Choose a quality, '
          'or set the exact size you need, such as under 100 KB.',
      progressMessage: 'Compressing image...',
      children: (context, p) => [
        ImagePickSection(
          path: p.inputPath,
          details: [p.dimensionsText, p.inputSizeText]
              .where((e) => e.isNotEmpty && e != '--')
              .join(' · '),
          enabled: !p.isBusy,
          onPick: p.pickImage,
        ),
        if (p.isReady) ...[
          const SizedBox(height: 20),
          ChoiceSection<CompressMode>(
            title: 'Method',
            values: CompressMode.values,
            selected: p.mode,
            labelOf: (m) =>
                m == CompressMode.quality ? 'By quality' : 'To a size',
            onSelected: p.setMode,
          ),
          const SizedBox(height: 16),
          if (p.mode == CompressMode.quality)
            LabeledSlider(
              label: 'Quality',
              valueText: '${p.quality}%',
              value: p.quality.toDouble(),
              min: 10,
              max: 95,
              divisions: 17,
              onChanged: (v) => p.setQuality(v.round()),
            )
          else ...[
            ChoiceSection<int>(
              title: 'Make it smaller than',
              values: ImageCompressProvider.targetsKb,
              selected: p.targetKb,
              labelOf: ImageCompressProvider.targetLabel,
              onSelected: p.setTargetKb,
            ),
            const SizedBox(height: 12),
            _CustomKbField(value: p.targetKb, onChanged: p.setTargetKb),
          ],
          const SizedBox(height: 16),
          ChoiceSection<ImageFormat>(
            title: 'Save as',
            values: ImageCompressProvider.formats,
            selected: p.format,
            labelOf: (f) => f.label,
            onSelected: p.setFormat,
          ),
        ],
        const SizedBox(height: 20),
        ProcessButton(
          label: 'Compress Image',
          icon: Icons.compress_rounded,
          enabled: p.isReady && !p.isBusy,
          onPressed: p.process,
        ),
        if (p.state == ProcessingState.done && p.outputPath != null) ...[
          const SizedBox(height: 24),
          ResultPanel(
            title: p.savedPercent > 0
                ? 'Made ${p.savedPercent.toStringAsFixed(0)}% smaller!'
                : 'Compression finished',
            detail: '${p.inputSizeText} → ${p.outputSizeText}',
            filePath: p.outputPath!,
            kind: ResultKind.image,
            onSave: p.saveToGallery,
            onSaveToDevice: p.saveToDevice,
            onShare: p.share,
          ),
        ],
      ],
    );
  }
}

/// Lets the user type any target size in KB (e.g. 30).
class _CustomKbField extends StatefulWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _CustomKbField({required this.value, required this.onChanged});

  @override
  State<_CustomKbField> createState() => _CustomKbFieldState();
}

class _CustomKbFieldState extends State<_CustomKbField> {
  late final TextEditingController _controller =
      TextEditingController(text: '${widget.value}');

  @override
  void didUpdateWidget(covariant _CustomKbField old) {
    super.didUpdateWidget(old);
    // Sync when a preset is tapped, but never fight the user's typing.
    if (int.tryParse(_controller.text) != widget.value) {
      _controller.text = '${widget.value}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: const InputDecoration(
        labelText: 'Or type your own size',
        suffixText: 'KB',
        border: OutlineInputBorder(),
      ),
      onChanged: (text) {
        final kb = int.tryParse(text);
        if (kb != null && kb > 0) widget.onChanged(kb);
      },
    );
  }
}
