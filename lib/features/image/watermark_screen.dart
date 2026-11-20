import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/image_canvas.dart';
import '../../core/services/image_service.dart';
import '../../core/utils/file_utils.dart';
import '../../providers/image/watermark_provider.dart';
import '../../widgets/tool_widgets.dart';

class WatermarkScreen extends StatefulWidget {
  const WatermarkScreen({super.key});

  @override
  State<WatermarkScreen> createState() => _WatermarkScreenState();
}

class _WatermarkScreenState extends State<WatermarkScreen> {
  late final TextEditingController _text;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: context.read<WatermarkProvider>().text);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold<WatermarkProvider>(
      title: 'Watermark',
      infoIcon: Icons.water_drop_rounded,
      infoText: 'Write your name or add a logo on a picture to protect it '
          'or brand it.',
      progressMessage: 'Adding watermark...',
      children: (context, p) => [
        ImagePickSection(
          path: p.inputPath,
          details: p.dimensionsText,
          enabled: !p.isBusy,
          onPick: p.pickImage,
        ),
        if (p.isReady) ...[
          const SizedBox(height: 20),
          TextField(
            controller: _text,
            enabled: !p.isBusy,
            maxLength: 60,
            decoration: const InputDecoration(
              labelText: 'Watermark text',
              hintText: 'for example © Your Name',
              border: OutlineInputBorder(),
            ),
            onChanged: p.setText,
          ),
          const SizedBox(height: 8),
          if (p.logoPath != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.image_rounded),
              title: Text(FileUtils.getFileName(p.logoPath!),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: p.removeLogo,
              ),
            ),
          OutlinedButton.icon(
            onPressed: p.isBusy ? null : p.pickLogo,
            icon: const Icon(Icons.add_photo_alternate_rounded),
            label: Text(
                p.logoPath == null ? 'Add a logo (optional)' : 'Change logo'),
            style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48)),
          ),
          const SizedBox(height: 20),
          const SectionTitle('Position'),
          const SizedBox(height: 8),
          _PositionGrid(provider: p),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Repeat across the picture'),
            subtitle: const Text('Hard to crop out'),
            value: p.repeat,
            onChanged: p.setRepeat,
          ),
          LabeledSlider(
            label: 'Size',
            valueText: '${(p.size * 100).round()}%',
            value: p.size,
            min: 0.02,
            max: 0.2,
            onChanged: p.setSize,
          ),
          LabeledSlider(
            label: 'Opacity',
            valueText: '${(p.opacity * 100).round()}%',
            value: p.opacity,
            min: 0.1,
            max: 1,
            onChanged: p.setOpacity,
          ),
          ChoiceSection<String>(
            title: 'Text colour',
            values: WatermarkProvider.colors.keys.toList(),
            selected: p.colorName,
            labelOf: (c) => c,
            onSelected: p.setColorName,
          ),
          const SizedBox(height: 16),
          ChoiceSection<ImageFormat>(
            title: 'Save as',
            values: const [ImageFormat.jpg, ImageFormat.png],
            selected: p.format,
            labelOf: (f) => f.label,
            onSelected: p.setFormat,
          ),
        ],
        const SizedBox(height: 20),
        ProcessButton(
          label: 'Add Watermark',
          icon: Icons.water_drop_rounded,
          enabled: p.isReady && p.canProcess && !p.isBusy,
          onPressed: p.process,
        ),
        if (p.state == ProcessingState.done && p.outputPath != null) ...[
          const SizedBox(height: 24),
          ResultPanel(
            title: 'Watermark added!',
            detail: p.outputSizeText,
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

/// A 3 x 3 grid to pick where the watermark goes.
class _PositionGrid extends StatelessWidget {
  final WatermarkProvider provider;
  const _PositionGrid({required this.provider});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 168,
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        children: [
          for (final pos in WatermarkPosition.values)
            Tooltip(
              message: pos.label,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: provider.isBusy ? null : () => provider.setPosition(pos),
                child: Container(
                  decoration: BoxDecoration(
                    color: provider.position == pos
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: provider.position == pos
                      ? Icon(Icons.water_drop_rounded,
                          size: 18, color: colorScheme.onPrimary)
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
