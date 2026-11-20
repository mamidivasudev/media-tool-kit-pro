import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/image_service.dart';
import '../../providers/image/exact_size_provider.dart';
import '../../widgets/tool_widgets.dart';

class ExactSizeScreen extends StatefulWidget {
  const ExactSizeScreen({super.key});

  @override
  State<ExactSizeScreen> createState() => _ExactSizeScreenState();
}

class _ExactSizeScreenState extends State<ExactSizeScreen> {
  final _widthCtrl = TextEditingController(text: '3.5');
  final _heightCtrl = TextEditingController(text: '4.5');
  final _kbCtrl = TextEditingController(text: '50');

  @override
  void dispose() {
    _widthCtrl.dispose();
    _heightCtrl.dispose();
    _kbCtrl.dispose();
    super.dispose();
  }

  /// A preset chip was tapped: show its number in the KB box.
  void _syncKb(ExactSizeProvider p) {
    final typed = int.tryParse(_kbCtrl.text);
    // An empty box is left alone so the user can clear it and type again.
    if (typed != null && typed != p.targetKb) {
      _kbCtrl.text = '${p.targetKb}';
    }
  }

  static String _unitLabel(SizeUnit u) => switch (u) {
    SizeUnit.px => 'Pixels',
    SizeUnit.cm => 'cm',
    SizeUnit.mm => 'mm',
  };

  @override
  Widget build(BuildContext context) {
    return ToolScaffold<ExactSizeProvider>(
      title: 'Exact Size',
      infoIcon: Icons.aspect_ratio_rounded,
      infoText:
          'For forms and applications: make a picture exactly the width '
          'and height they ask for (in pixels, cm or mm) and keep the file '
          'under a size such as 30 KB.',
      progressMessage: 'Making your image...',
      children: (context, p) {
        _syncKb(p);
        final unitName = _unitLabel(p.unit);
        return [
          ImagePickSection(
            path: p.inputPath,
            details: [
              p.dimensionsText,
              p.inputSizeText,
            ].where((e) => e.isNotEmpty && e != '--').join(' · '),
            enabled: !p.isBusy,
            onPick: p.pickImage,
          ),
          if (p.isReady) ...[
            const SizedBox(height: 20),
            ChoiceSection<SizeUnit>(
              title: 'Size unit',
              values: SizeUnit.values,
              selected: p.unit,
              labelOf: _unitLabel,
              onSelected: p.setUnit,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _widthCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Width ($unitName)',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (v) => p.setWidth(double.tryParse(v) ?? 0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _heightCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Height ($unitName)',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (v) => p.setHeight(double.tryParse(v) ?? 0),
                  ),
                ),
              ],
            ),
            if (p.unit != SizeUnit.px) ...[
              const SizedBox(height: 16),
              ChoiceSection<int>(
                title: 'Print quality (dpi) — 300 is the usual form standard',
                values: ExactSizeProvider.dpiChoices,
                selected: p.dpi,
                labelOf: (v) => '$v dpi',
                onSelected: p.setDpi,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              p.validSize
                  ? 'Result: ${p.pixelWidth} × ${p.pixelHeight} px'
                  : 'Enter a width and height (up to 12000 px).',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ChoiceSection<FitMode>(
              title: 'If the shape is different',
              values: FitMode.values,
              selected: p.fit,
              labelOf: (m) => switch (m) {
                FitMode.crop => 'Crop to fill',
                FitMode.pad => 'Fit with white',
                FitMode.stretch => 'Stretch',
              },
              onSelected: p.setFit,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Limit file size'),
              subtitle: const Text('Keep the file under a number of KB'),
              value: p.limitSize,
              onChanged: p.setLimitSize,
            ),
            if (p.limitSize) ...[
              ChoiceSection<int>(
                title: 'Smaller than',
                values: ExactSizeProvider.targetsKb,
                selected: p.targetKb,
                labelOf: (kb) => '$kb KB',
                onSelected: p.setTargetKb,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _kbCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Or type your own limit',
                  suffixText: 'KB',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) {
                  final kb = int.tryParse(v);
                  if (kb != null && kb > 0) p.setTargetKb(kb);
                },
              ),
            ],
            const SizedBox(height: 16),
            ChoiceSection<ImageFormat>(
              title: 'Save as',
              values: ExactSizeProvider.formats,
              selected: p.format,
              labelOf: (f) => f.label,
              onSelected: p.setFormat,
            ),
          ],
          const SizedBox(height: 20),
          ProcessButton(
            label: 'Make Image',
            icon: Icons.aspect_ratio_rounded,
            enabled: p.isReady && p.validSize && !p.isBusy,
            onPressed: p.process,
          ),
          if (p.state == ProcessingState.done && p.outputPath != null) ...[
            const SizedBox(height: 24),
            ResultPanel(
              title: 'Image ready!',
              detail:
                  '${p.pixelWidth} × ${p.pixelHeight} px '
                  '(${p.sizeText}) · ${p.outputSizeText}',
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
