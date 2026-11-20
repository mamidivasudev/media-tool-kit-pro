import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

import '../../providers/image/image_crop_provider.dart';
import '../../widgets/tool_widgets.dart';

class ImageCropScreen extends StatefulWidget {
  const ImageCropScreen({super.key});

  @override
  State<ImageCropScreen> createState() => _ImageCropScreenState();
}

class _ImageCropScreenState extends State<ImageCropScreen> {
  final _controller = CropController();

  @override
  Widget build(BuildContext context) {
    return ToolScaffold<ImageCropProvider>(
      title: 'Crop Image',
      infoIcon: Icons.crop_rounded,
      infoText: 'Drag the corners to choose the part to keep, or pick a '
          'fixed shape such as 1:1 or 16:9.',
      progressMessage: 'Cropping image...',
      scrollable: false,
      children: (context, p) {
        if (p.state == ProcessingState.done && p.outputPath != null) {
          return [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ResultPanel(
                      title: 'Image cropped!',
                      detail: p.outputSizeText,
                      filePath: p.outputPath!,
                      kind: ResultKind.image,
                      onSave: p.saveToGallery,
                      onSaveToDevice: p.saveToDevice,
                      onShare: p.share,
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: p.discardResult,
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Crop again'),
                    ),
                  ],
                ),
              ),
            ),
          ];
        }

        final bytes = p.workBytes;
        return [
          Expanded(
            child: bytes == null
                ? Center(
                    child: p.state == ProcessingState.loading
                        ? const CircularProgressIndicator()
                        : Text(
                            'Choose a picture to start',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Crop(
                      key: ValueKey('${p.inputPath}-${p.ratio.name}'),
                      image: bytes,
                      controller: _controller,
                      aspectRatio: p.ratio.ratio,
                      baseColor: Theme.of(context).colorScheme.surface,
                      maskColor: Colors.black54,
                      progressIndicator: const CircularProgressIndicator(),
                      onCropped: (result) {
                        switch (result) {
                          case CropSuccess(:final croppedImage):
                            p.processCropped(croppedImage);
                          case CropFailure():
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Could not crop this picture.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                        }
                      },
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final r in CropRatio.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(r.label),
                      selected: p.ratio == r,
                      onSelected: p.isBusy ? null : (_) => p.setRatio(r),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: p.isBusy ? null : p.pickImage,
                  icon: const Icon(Icons.image_rounded),
                  label: Text(p.hasInput ? 'Change' : 'Select Image'),
                  style:
                      OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed:
                      bytes != null && !p.isBusy ? _controller.crop : null,
                  icon: const Icon(Icons.crop_rounded),
                  label: const Text('Crop'),
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                ),
              ),
            ],
          ),
        ];
      },
    );
  }
}
