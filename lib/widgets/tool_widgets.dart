import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/base_provider.dart';

import 'progress_overlay.dart';
import 'shared_widgets.dart';
import 'video_preview.dart';
import 'video_thumbnail.dart';

export '../providers/base_provider.dart' show ProcessingState;

/// Page frame used by the single-video tools: app bar, scrolling body,
/// progress overlay while working, and an error card when something fails.
class ToolScaffold<T extends BaseToolProvider> extends StatelessWidget {
  final String title;
  final IconData infoIcon;
  final String infoText;
  final String progressMessage;
  final List<Widget> Function(BuildContext context, T provider) children;

  /// Set to false for screens that fill the page (for example with a crop
  /// area) and place an [Expanded] widget in [children].
  final bool scrollable;

  const ToolScaffold({
    super.key,
    required this.title,
    required this.infoIcon,
    required this.infoText,
    required this.progressMessage,
    required this.children,
    this.scrollable = true,
  });

  Widget _body(BuildContext context, T provider) {
    final content = <Widget>[
      InfoBanner(icon: infoIcon, text: infoText),
      const SizedBox(height: 20),
      ...children(context, provider),
      if (provider.state == ProcessingState.error) ...[
        const SizedBox(height: 16),
        ErrorCard(message: provider.errorMessage),
      ],
    ];
    if (scrollable) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: content,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: content,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        top: false,
        child: Consumer<T>(
          builder: (context, provider, _) {
            return Stack(
              children: [
                _body(context, provider),
                if (provider.isBusy)
                  Positioned.fill(
                    child: ProgressOverlay(
                      progress: provider.progress,
                      message: progressMessage,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Shows the chosen file and a button to pick or change it.
class FilePickSection extends StatelessWidget {
  final String? path;
  final String label;
  final String changeLabel;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPick;

  const FilePickSection({
    super.key,
    required this.path,
    required this.onPick,
    this.label = 'Select Video',
    this.changeLabel = 'Change Video',
    this.icon = Icons.video_file_rounded,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (path != null) ...[
          VideoThumbnail(filePath: path!),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          onPressed: enabled ? onPick : null,
          icon: Icon(icon),
          label: Text(path == null ? label : changeLabel),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
          ),
        ),
      ],
    );
  }
}

/// Shows the chosen picture and a button to pick or change it.
class ImagePickSection extends StatelessWidget {
  final String? path;
  final String? details;
  final bool enabled;
  final VoidCallback onPick;
  final String label;
  final String changeLabel;

  const ImagePickSection({
    super.key,
    required this.path,
    required this.onPick,
    this.details,
    this.enabled = true,
    this.label = 'Select Image',
    this.changeLabel = 'Change Image',
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (path != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 200,
              width: double.infinity,
              color: colorScheme.surfaceContainerHighest,
              child: Image.file(
                File(path!),
                fit: BoxFit.contain,
                cacheWidth: 900,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image_rounded, size: 48),
                ),
              ),
            ),
          ),
          if (details != null && details!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(details!, style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          onPressed: enabled ? onPick : null,
          icon: const Icon(Icons.image_rounded),
          label: Text(path == null ? label : changeLabel),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
          ),
        ),
      ],
    );
  }
}

/// A list of pictures that can be reordered and removed, with an add button.
class ImageListSection extends StatelessWidget {
  final List<String> images;
  final int maxImages;
  final bool enabled;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final void Function(int oldIndex, int newIndex) onReorder;
  final String? hint;

  const ImageListSection({
    super.key,
    required this.images,
    required this.maxImages,
    required this.onAdd,
    required this.onRemove,
    required this.onReorder,
    this.enabled = true,
    this.hint,
  });

  String _name(String path) => path.split(RegExp(r'[\\/]')).last;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (images.isNotEmpty) ...[
          Text(
            '${images.length} picture${images.length == 1 ? '' : 's'}'
            '${hint == null ? '' : ' · $hint'}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: enabled,
            itemCount: images.length,
            onReorder: enabled ? onReorder : (_, __) {},
            itemBuilder: (context, i) => Container(
              key: ValueKey('${images[i]}#$i'),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                dense: true,
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(images[i]),
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    cacheWidth: 150,
                    errorBuilder: (_, __, ___) =>
                        const SizedBox(width: 48, height: 48),
                  ),
                ),
                title: Text(
                  '${i + 1}. ${_name(images[i])}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: enabled ? () => onRemove(i) : null,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          onPressed: enabled && images.length < maxImages ? onAdd : null,
          icon: const Icon(Icons.add_photo_alternate_rounded),
          label: Text(images.isEmpty ? 'Select Images' : 'Add More Images'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
          ),
        ),
      ],
    );
  }
}

/// A titled group of options where exactly one can be selected.
class ChoiceSection<V> extends StatelessWidget {
  final String title;
  final List<V> values;
  final V selected;
  final String Function(V value) labelOf;
  final ValueChanged<V> onSelected;

  const ChoiceSection({
    super.key,
    required this.title,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final v in values)
              ChoiceChip(
                label: Text(labelOf(v)),
                selected: v == selected,
                onSelected: (_) => onSelected(v),
              ),
          ],
        ),
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .titleSmall
          ?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

/// Slider with a label and a value on the right.
class LabeledSlider extends StatelessWidget {
  final String label;
  final String valueText;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;

  const LabeledSlider({
    super.key,
    required this.label,
    required this.valueText,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
  });

  @override
  Widget build(BuildContext context) {
    final safeMax = max > min ? max : min + 0.001;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text(
              valueText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, safeMax),
          min: min,
          max: safeMax,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// A big primary button that disables itself while a job runs.
class ProcessButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  const ProcessButton({
    super.key,
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

enum ResultKind { video, image, audio, document }

/// Success banner, optional preview and the save and share buttons.
class ResultPanel extends StatefulWidget {
  final String title;
  final String? detail;
  final String filePath;
  final ResultKind kind;
  final Color color;
  final Future<bool> Function()? onSave;
  final Future<bool> Function()? onSaveToDevice;
  final Future<void> Function() onShare;
  final String saveLabel;

  const ResultPanel({
    super.key,
    required this.title,
    required this.filePath,
    required this.onShare,
    this.detail,
    this.kind = ResultKind.video,
    this.color = Colors.green,
    this.onSave,
    this.onSaveToDevice,
    this.saveLabel = 'Save to Gallery',
  });

  @override
  State<ResultPanel> createState() => _ResultPanelState();
}

class _ResultPanelState extends State<ResultPanel> {
  bool _showPreview = false;
  bool _saving = false;

  Future<void> _save(Future<bool> Function() action, String okText) async {
    setState(() => _saving = true);
    final ok = await action();
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? okText : 'Could not save the file.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    final textTheme = Theme.of(context).textTheme;
    const fullWidth = Size(double.infinity, 52);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700, color: color),
                    ),
                    if (widget.detail != null)
                      Text(widget.detail!, style: textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (widget.kind == ResultKind.document) ...[
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.picture_as_pdf_rounded,
                  size: 56, color: Colors.redAccent),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (widget.kind == ResultKind.image) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(File(widget.filePath), fit: BoxFit.contain),
          ),
          const SizedBox(height: 12),
        ],
        if (widget.kind == ResultKind.video) ...[
          FilledButton.icon(
            onPressed: () => setState(() => _showPreview = !_showPreview),
            icon: Icon(_showPreview
                ? Icons.visibility_off_rounded
                : Icons.play_circle_outline_rounded),
            label: Text(_showPreview ? 'Hide Preview' : 'Preview'),
          ),
          if (_showPreview) ...[
            const SizedBox(height: 12),
            VideoPreview(filePath: widget.filePath),
          ],
          const SizedBox(height: 12),
        ],
        if (widget.onSave != null)
          FilledButton.tonalIcon(
            onPressed: _saving
                ? null
                : () => _save(widget.onSave!, 'Saved to gallery!'),
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_alt_rounded),
            label: Text(widget.saveLabel),
            style: FilledButton.styleFrom(minimumSize: fullWidth),
          ),
        if (widget.onSaveToDevice != null)
          FilledButton.tonalIcon(
            onPressed: _saving
                ? null
                : () => _save(widget.onSaveToDevice!, 'File saved!'),
            icon: const Icon(Icons.folder_open_rounded),
            label: const Text('Save to Device'),
            style: FilledButton.styleFrom(minimumSize: fullWidth),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: widget.onShare,
          icon: const Icon(Icons.share_rounded),
          label: const Text('Share'),
          style: OutlinedButton.styleFrom(minimumSize: fullWidth),
        ),
      ],
    );
  }
}
