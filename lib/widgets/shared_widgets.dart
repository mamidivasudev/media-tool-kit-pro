import 'package:flutter/material.dart';

/// A reusable info banner for feature screens.
class InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  const InfoBanner({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A reusable error card for feature screens.
class ErrorCard extends StatelessWidget {
  final String message;
  const ErrorCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message.isEmpty ? 'An error occurred.' : message,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// A reusable success banner.
class SuccessBanner extends StatelessWidget {
  final String message;
  final Color color;
  const SuccessBanner({
    super.key,
    required this.message,
    this.color = Colors.green,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            child: Text(
              message,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A reusable save-to-gallery + share button row.
class SaveShareRow extends StatefulWidget {
  final Future<bool> Function() onSave;
  final VoidCallback onShare;

  const SaveShareRow({
    super.key,
    required this.onSave,
    required this.onShare,
  });

  @override
  State<SaveShareRow> createState() => _SaveShareRowState();
}

class _SaveShareRowState extends State<SaveShareRow> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FilledButton.tonalIcon(
          onPressed: _saving
              ? null
              : () async {
                  setState(() => _saving = true);
                  final ok = await widget.onSave();
                  setState(() => _saving = false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text(ok ? 'Saved to gallery!' : 'Failed to save.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save_alt_rounded),
          label: const Text('Save to Gallery'),
          style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52)),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: widget.onShare,
          icon: const Icon(Icons.share_rounded),
          label: const Text('Share'),
          style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52)),
        ),
      ],
    );
  }
}
