import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/services/ffmpeg_service.dart';
import '../../core/services/file_service.dart';
import '../../core/utils/file_utils.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Appearance'),
          _ThemeTile(),
          const Divider(indent: 16, endIndent: 16),
          const _SectionHeader('Storage'),
          const _CacheTile(),
          const Divider(indent: 16, endIndent: 16),
          const _SectionHeader('App'),
          _SettingsTile(
            icon: Icons.star_rounded,
            label: 'Rate App',
            subtitle: 'Enjoying the app? Leave a review',
            color: Colors.amber,
            onTap: () => _rateApp(context),
          ),
          _SettingsTile(
            icon: Icons.share_rounded,
            label: 'Share App',
            subtitle: 'Tell your friends about Media Toolkit Pro',
            color: Colors.blue,
            onTap: () => _shareApp(context),
          ),
          const Divider(indent: 16, endIndent: 16),
          const _SectionHeader('Legal'),
          _SettingsTile(
            icon: Icons.privacy_tip_rounded,
            label: 'Privacy Policy',
            subtitle: 'How we handle your data',
            color: Colors.green,
            onTap: () => _showPrivacyPolicy(context),
          ),
          _SettingsTile(
            icon: Icons.info_rounded,
            label: 'About',
            subtitle: 'Version 1.2.0',
            color: Colors.deepPurple,
            onTap: () => _showAbout(context),
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'Media Toolkit Pro v1.2.0\nBuilt with ❤️ using Flutter & FFmpeg',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5),
                  ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _rateApp(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rating would open Play Store in production.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _shareApp(BuildContext context) async {
    await Share.share(
      'Check out Media Toolkit Pro – a powerful offline video, audio & image kit for Android!\n'
      'Merge, trim, compress, extract audio and more – all on your device!',
      subject: 'Media Toolkit Pro',
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _PrivacyPolicySheet(),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Media Toolkit Pro',
      applicationVersion: '1.2.0',
      applicationLegalese: '© 2024 Media Toolkit Pro. All rights reserved.',
      children: [
        const SizedBox(height: 16),
        const Text(
          'A powerful offline video processing app built with Flutter and FFmpeg. '
          'Edit videos, audio and pictures, make PDFs and GIFs, and read text from images, all on your device '
          'without any cloud or internet connection required.',
        ),
      ],
    );
  }
}

class _ThemeTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, theme, _) {
        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.dark_mode_rounded, color: Colors.indigo),
          ),
          title: const Text('Dark Mode'),
          subtitle: const Text('Switch between light and dark theme'),
          trailing: Switch(
            value: theme.isDark,
            onChanged: theme.toggleDarkMode,
          ),
        );
      },
    );
  }
}

class _CacheTile extends StatefulWidget {
  const _CacheTile();

  @override
  State<_CacheTile> createState() => _CacheTileState();
}

class _CacheTileState extends State<_CacheTile> {
  late Future<int> _size = FFmpegService.instance.cacheSize();

  Future<void> _clear() async {
    final freed = await FFmpegService.instance.clearCache();
    await FileService.instance.clearPickedFiles();
    if (!mounted) return;
    setState(() => _size = FFmpegService.instance.cacheSize());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Freed ${FileUtils.formatFileSize(freed)}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _size,
      builder: (context, snap) => _SettingsTile(
        icon: Icons.cleaning_services_rounded,
        label: 'Clear temporary files',
        subtitle: snap.data == null
            ? 'Delete leftover processed videos'
            : 'Using ${FileUtils.formatFileSize(snap.data!)} of temporary space',
        color: Colors.orange,
        onTap: _clear,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(label),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _PrivacyPolicySheet extends StatelessWidget {
  const _PrivacyPolicySheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          AppBar(
            title: const Text('Privacy Policy'),
            leading: CloseButton(
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.all(16),
              children: const [
                _PolicySection(
                  title: 'Overview',
                  content:
                      'Media Toolkit Pro is a fully offline application. All video and audio '
                      'processing is performed entirely on your device using FFmpeg.',
                ),
                _PolicySection(
                  title: 'Data Collection',
                  content:
                      'We do not collect, store, or transmit any personal data, video files, '
                      'or usage information. Your files never leave your device.',
                ),
                _PolicySection(
                  title: 'Permissions',
                  content:
                      'Files are chosen with the system file picker, so the app does not need '
                      'broad access to your storage. When you save a result to your gallery, '
                      'Android may ask for permission to add it. '
                      'No permissions are used for any other purpose.',
                ),
                _PolicySection(
                  title: 'Third-Party Services',
                  content:
                      'This app does not use any third-party analytics, advertising, '
                      'or tracking services.',
                ),
                _PolicySection(
                  title: 'Contact',
                  content:
                      'For any privacy-related questions, please contact us via the app store listing.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String content;
  const _PolicySection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(content, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
