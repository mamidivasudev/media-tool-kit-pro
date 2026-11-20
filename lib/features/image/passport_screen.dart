import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

import '../../providers/image/passport_provider.dart';
import '../../widgets/tool_widgets.dart';

class PassportScreen extends StatefulWidget {
  const PassportScreen({super.key});

  @override
  State<PassportScreen> createState() => _PassportScreenState();
}

class _PassportScreenState extends State<PassportScreen> {
  final _controller = CropController();

  @override
  Widget build(BuildContext context) {
    return ToolScaffold<PassportProvider>(
      title: 'Passport Photo',
      infoIcon: Icons.badge_rounded,
      infoText: 'Frame the face inside the box, pick the photo size, and get '
          'a print-ready sheet. Use a photo with a plain background.',
      progressMessage: 'Creating photo...',
      scrollable: false,
      children: (context, p) {
        if (p.state == ProcessingState.done && p.outputPath != null) {
          return [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ResultPanel(
                      title: p.output == PassportOutput.single
                          ? 'Passport photo ready!'
                          : 'Print sheet ready!',
                      detail: p.output == PassportOutput.single
                          ? '${p.size.label} · 300 dpi'
                          : '${p.copies} photos · ${p.size.label} · 300 dpi',
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
                      label: const Text('Adjust again'),
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
                        : const Text('Choose a photo to start'),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Crop(
                      key: ValueKey('${p.inputPath}-${p.size.name}'),
                      image: bytes,
                      controller: _controller,
                      aspectRatio: p.size.ratio,
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
                                content: Text('Could not crop this photo.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                        }
                      },
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          _ChipRow(
            children: [
              for (final s in PassportSize.values)
                ChoiceChip(
                  label: Text(s.label),
                  tooltip: s.note,
                  selected: p.size == s,
                  onSelected: p.isBusy ? null : (_) => p.setSize(s),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(p.size.note, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          _ChipRow(
            children: [
              for (final o in PassportOutput.values)
                ChoiceChip(
                  label: Text(o.label),
                  selected: p.output == o,
                  onSelected: p.isBusy ? null : (_) => p.setOutput(o),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: p.isBusy ? null : p.pickImage,
                  icon: const Icon(Icons.image_rounded),
                  label: Text(p.hasInput ? 'Change' : 'Select Photo'),
                  style:
                      OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed:
                      bytes != null && !p.isBusy ? _controller.crop : null,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Create'),
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

class _ChipRow extends StatelessWidget {
  final List<Widget> children;
  const _ChipRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final c in children)
            Padding(padding: const EdgeInsets.only(right: 8), child: c),
        ],
      ),
    );
  }
}
