import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../providers/image/ocr_provider.dart';
import '../../widgets/tool_widgets.dart';

class OcrScreen extends StatelessWidget {
  const OcrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ToolScaffold<OcrProvider>(
      title: 'Text from Image',
      infoIcon: Icons.text_snippet_rounded,
      infoText: 'Read the text in a photo or screenshot and copy it. '
          'Works offline. Best with clear, printed text in English or '
          'other Latin-script languages.',
      progressMessage: 'Reading text...',
      children: (context, p) => [
        ImagePickSection(
          path: p.inputPath,
          details: p.dimensionsText,
          enabled: !p.isBusy,
          onPick: p.pickImage,
        ),
        const SizedBox(height: 20),
        ProcessButton(
          label: 'Read Text',
          icon: Icons.text_snippet_rounded,
          enabled: p.isReady && !p.isBusy,
          onPressed: p.process,
        ),
        if (p.state == ProcessingState.done && p.outputPath != null) ...[
          const SizedBox(height: 24),
          _TextResult(provider: p),
        ],
      ],
    );
  }
}

class _TextResult extends StatefulWidget {
  final OcrProvider provider;
  const _TextResult({required this.provider});

  @override
  State<_TextResult> createState() => _TextResultState();
}

class _TextResultState extends State<_TextResult> {
  bool _saving = false;

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.provider;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.green, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Found ${p.wordCount} words',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.green,
                      ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SelectableText(p.text),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: p.text));
            if (mounted) _snack('Text copied');
          },
          icon: const Icon(Icons.copy_rounded),
          label: const Text('Copy Text'),
        ),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: _saving
              ? null
              : () async {
                  setState(() => _saving = true);
                  final ok = await p.saveToDevice();
                  if (!mounted) return;
                  setState(() => _saving = false);
                  _snack(ok ? 'File saved!' : 'Could not save the file.');
                },
          icon: const Icon(Icons.folder_open_rounded),
          label: const Text('Save as Text File'),
          style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52)),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: p.share,
          icon: const Icon(Icons.share_rounded),
          label: const Text('Share'),
          style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52)),
        ),
      ],
    );
  }
}
