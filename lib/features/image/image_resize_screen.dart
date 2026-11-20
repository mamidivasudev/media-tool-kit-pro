import 'package:flutter/material.dart';

import '../../providers/image/image_resize_provider.dart';
import '../../widgets/tool_widgets.dart';

class ImageResizeScreen extends StatefulWidget {
  const ImageResizeScreen({super.key});

  @override
  State<ImageResizeScreen> createState() => _ImageResizeScreenState();
}

class _ImageResizeScreenState extends State<ImageResizeScreen> {
  final _widthCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();

  @override
  void dispose() {
    _widthCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  /// Keeps the text boxes in step with the provider without moving the cursor
  /// while the user types.
  void _sync(ImageResizeProvider p) {
    if (_widthCtrl.text != '${p.width}' && p.width > 0) {
      _widthCtrl.text = '${p.width}';
    }
    if (_heightCtrl.text != '${p.height}' && p.height > 0) {
      _heightCtrl.text = '${p.height}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold<ImageResizeProvider>(
      title: 'Resize Image',
      infoIcon: Icons.photo_size_select_large_rounded,
      infoText: 'Change the size of a picture by percent, by exact pixels, '
          'or to a ready-made size for social media.',
      progressMessage: 'Resizing image...',
      children: (context, p) {
        _sync(p);
        final (tw, th) = p.targetSize;
        return [
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
            ChoiceSection<ResizeMode>(
              title: 'Resize by',
              values: ResizeMode.values,
              selected: p.mode,
              labelOf: (m) => switch (m) {
                ResizeMode.percent => 'Percent',
                ResizeMode.dimensions => 'Pixels',
                ResizeMode.preset => 'Preset',
              },
              onSelected: p.setMode,
            ),
            const SizedBox(height: 16),
            if (p.mode == ResizeMode.percent) ...[
              ChoiceSection<int>(
                title: 'Quick choice',
                values: ImageResizeProvider.percents,
                selected: p.percent,
                labelOf: (v) => '$v%',
                onSelected: p.setPercent,
              ),
              LabeledSlider(
                label: 'Scale',
                valueText: '${p.percent}%',
                value: p.percent.clamp(10, 200).toDouble(),
                min: 10,
                max: 200,
                onChanged: (v) => p.setPercent(v.round()),
              ),
            ] else if (p.mode == ResizeMode.dimensions) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _widthCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Width (px)',
                          border: OutlineInputBorder()),
                      onChanged: (v) {
                        final n = int.tryParse(v);
                        if (n != null) p.setWidth(n);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _heightCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Height (px)',
                          border: OutlineInputBorder()),
                      onChanged: (v) {
                        final n = int.tryParse(v);
                        if (n != null) p.setHeight(n);
                      },
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Keep proportions'),
                value: p.keepAspect,
                onChanged: p.setKeepAspect,
              ),
            ] else
              ChoiceSection<ResizePreset>(
                title: 'Fit inside',
                values: ImageResizeProvider.presets,
                selected: p.preset,
                labelOf: (r) => r.label,
                onSelected: p.setPreset,
              ),
            const SizedBox(height: 8),
            Text('Result: $tw × $th px',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 20),
          ProcessButton(
            label: 'Resize Image',
            icon: Icons.photo_size_select_large_rounded,
            enabled: p.isReady && !p.isBusy,
            onPressed: p.process,
          ),
          if (p.state == ProcessingState.done && p.outputPath != null) ...[
            const SizedBox(height: 24),
            ResultPanel(
              title: 'Image resized!',
              detail: '$tw × $th px · ${p.outputSizeText}',
              filePath: p.outputPath!,
              kind: ResultKind.image,
              onSave: p.saveToGallery,
              onSaveToDevice: p.saveToDevice,
              onShare: p.share,
            ),
          ],
        ];
      },
    );
  }
}
