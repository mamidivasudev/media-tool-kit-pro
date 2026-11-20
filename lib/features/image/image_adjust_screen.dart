import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../../core/services/image_service.dart';
import '../../providers/image/image_adjust_provider.dart';
import '../../widgets/tool_widgets.dart';

class ImageAdjustScreen extends StatelessWidget {
  const ImageAdjustScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ToolScaffold<ImageAdjustProvider>(
      title: 'Adjust & Filters',
      infoIcon: Icons.tune_rounded,
      infoText: 'Fix brightness, contrast and colour, or give the picture '
          'a look. The preview is a close match to the saved result.',
      progressMessage: 'Applying changes...',
      children: (context, p) => [
        if (p.inputPath == null)
          ImagePickSection(
            path: null,
            enabled: !p.isBusy,
            onPick: p.pickImage,
          )
        else ...[
          _LivePreview(provider: p),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: p.isBusy ? null : p.pickImage,
            icon: const Icon(Icons.image_rounded),
            label: const Text('Change Image'),
            style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48)),
          ),
        ],
        if (p.isReady) ...[
          const SizedBox(height: 20),
          ChoiceSection<ImageLook>(
            title: 'Look',
            values: ImageLook.values,
            selected: p.look,
            labelOf: (l) => l.label,
            onSelected: p.setLook,
          ),
          const SizedBox(height: 12),
          LabeledSlider(
            label: 'Brightness',
            valueText: p.brightness.toStringAsFixed(2),
            value: p.brightness,
            min: -0.5,
            max: 0.5,
            onChanged: p.setBrightness,
          ),
          LabeledSlider(
            label: 'Contrast',
            valueText: p.contrast.toStringAsFixed(2),
            value: p.contrast,
            min: 0.5,
            max: 1.5,
            onChanged: p.setContrast,
          ),
          LabeledSlider(
            label: 'Colour',
            valueText: p.saturation.toStringAsFixed(2),
            value: p.saturation,
            min: 0,
            max: 2,
            onChanged: p.setSaturation,
          ),
          LabeledSlider(
            label: 'Sharpness',
            valueText: p.sharpness.toStringAsFixed(2),
            value: p.sharpness,
            min: 0,
            max: 2,
            onChanged: p.setSharpness,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: p.hasChanges ? p.resetAdjustments : null,
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Reset'),
            ),
          ),
        ],
        const SizedBox(height: 12),
        ProcessButton(
          label: 'Save Changes',
          icon: Icons.check_rounded,
          enabled: p.isReady && p.hasChanges && !p.isBusy,
          onPressed: p.process,
        ),
        if (p.state == ProcessingState.done && p.outputPath != null) ...[
          const SizedBox(height: 24),
          ResultPanel(
            title: 'Changes applied!',
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

/// Shows the picture with the chosen changes using colour filters.
class _LivePreview extends StatelessWidget {
  final ImageAdjustProvider provider;
  const _LivePreview({required this.provider});

  @override
  Widget build(BuildContext context) {
    final p = provider;
    Widget image = Image.file(
      File(p.inputPath!),
      fit: BoxFit.contain,
      cacheWidth: 900,
      errorBuilder: (_, __, ___) =>
          const Center(child: Icon(Icons.broken_image_rounded, size: 48)),
    );
    image = ColorFiltered(
        colorFilter: ColorFilter.matrix(_saturation(p.saturation)),
        child: image);
    image = ColorFiltered(
        colorFilter:
            ColorFilter.matrix(_brightnessContrast(p.brightness, p.contrast)),
        child: image);
    final look = _lookMatrix(p.look);
    if (look != null) {
      image =
          ColorFiltered(colorFilter: ColorFilter.matrix(look), child: image);
    }
    if (p.look == ImageLook.blur) {
      image = ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4), child: image);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 260,
        width: double.infinity,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: image,
      ),
    );
  }

  static List<double> _saturation(double s) {
    const r = 0.2126, g = 0.7152, b = 0.0722;
    final sr = (1 - s) * r, sg = (1 - s) * g, sb = (1 - s) * b;
    return [
      sr + s,
      sg,
      sb,
      0,
      0,
      sr,
      sg + s,
      sb,
      0,
      0,
      sr,
      sg,
      sb + s,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  static List<double> _brightnessContrast(double brightness, double contrast) {
    final offset = (0.5 - 0.5 * contrast + brightness) * 255;
    return [
      contrast,
      0,
      0,
      0,
      offset,
      0,
      contrast,
      0,
      0,
      offset,
      0,
      0,
      contrast,
      0,
      offset,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  static List<double>? _lookMatrix(ImageLook look) {
    switch (look) {
      case ImageLook.blackWhite:
        return _saturation(0);
      case ImageLook.sepia:
        return [
          0.393,
          0.769,
          0.189,
          0,
          0,
          0.349,
          0.686,
          0.168,
          0,
          0,
          0.272,
          0.534,
          0.131,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ];
      case ImageLook.warm:
        return [
          1.1,
          0,
          0,
          0,
          8,
          0,
          1.0,
          0,
          0,
          0,
          0,
          0,
          0.88,
          0,
          -8,
          0,
          0,
          0,
          1,
          0,
        ];
      case ImageLook.cool:
        return [
          0.88,
          0,
          0,
          0,
          -8,
          0,
          1.0,
          0,
          0,
          0,
          0,
          0,
          1.1,
          0,
          8,
          0,
          0,
          0,
          1,
          0,
        ];
      case ImageLook.none:
      case ImageLook.blur:
        return null;
    }
  }
}
