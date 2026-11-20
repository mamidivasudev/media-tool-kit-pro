import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';
import '../../widgets/feature_card.dart';
import '../merger/merger_screen.dart';
import '../remove_audio/remove_audio_screen.dart';
import '../extract_mp3/extract_mp3_screen.dart';
import '../splitter/splitter_screen.dart';
import '../compressor/compressor_screen.dart';
import '../trimmer/trimmer_screen.dart';
import '../converter/converter_screen.dart';
import '../speed/speed_screen.dart';
import '../rotate/rotate_screen.dart';
import '../gif/gif_screen.dart';
import '../frame/frame_screen.dart';
import '../replace_audio/replace_audio_screen.dart';
import '../image/image_compress_screen.dart';
import '../image/image_resize_screen.dart';
import '../image/exact_size_screen.dart';
import '../image/image_convert_screen.dart';
import '../image/images_to_pdf_screen.dart';
import '../image/image_crop_screen.dart';
import '../image/image_rotate_screen.dart';
import '../image/strip_metadata_screen.dart';
import '../image/image_adjust_screen.dart';
import '../image/watermark_screen.dart';
import '../image/collage_screen.dart';
import '../image/image_frame_screen.dart';
import '../image/slideshow_screen.dart';
import '../image/passport_screen.dart';
import '../image/ocr_screen.dart';
import '../settings/settings_screen.dart';

enum _Category {
  video('Video', Icons.movie_rounded),
  audio('Audio', Icons.music_note_rounded),
  image('Image', Icons.image_rounded);

  final String label;
  final IconData icon;
  const _Category(this.label, this.icon);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  _Category _category = _Category.video;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
            child: _buildCategorySelector(context),
          ),
          // PageView gives a smooth, finger-following swipe between tabs.
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _Category.values.length,
              onPageChanged: (i) => setState(() => _category = _Category.values[i]),
              itemBuilder: (context, i) => _buildPage(context, _Category.values[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(BuildContext context, _Category category) {
    final items = _features.where((f) => f.category == category).toList();
    if (items.isEmpty) return _ComingSoon(category: category);
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(
          12, 6, 12, 16 + MediaQuery.of(context).viewPadding.bottom),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.25,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildCard(context, items[index]),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppBar(
      toolbarHeight: 60,
      backgroundColor: colorScheme.primaryContainer,
      centerTitle: false,
      titleSpacing: 20,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Media Toolkit Pro',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          Text(
            'Offline video, audio & image tools',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onPrimaryContainer.withOpacity(0.7),
            ),
          ),
        ],
      ),
      actions: [
        Consumer<ThemeProvider>(
          builder: (context, theme, _) => IconButton(
            icon: Icon(
              theme.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
            onPressed: () => theme.toggleDarkMode(!theme.isDark),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.settings_rounded),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector(BuildContext context) {
    return SegmentedButton<_Category>(
      showSelectedIcon: false,
      expandedInsets: EdgeInsets.zero,
      segments: [
        for (final c in _Category.values)
          ButtonSegment(value: c, label: Text(c.label), icon: Icon(c.icon)),
      ],
      selected: {_category},
      onSelectionChanged: (set) => _pageController.animateToPage(
        set.first.index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
    );
  }

  Widget _buildCard(BuildContext context, _FeatureItem feature) {
    return FeatureCard(
      emoji: feature.emoji,
      title: feature.title,
      subtitle: feature.subtitle,
      color: feature.color,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => feature.screen),
      ),
    );
  }

  List<_FeatureItem> get _features => [
    _FeatureItem(
      emoji: '🎬',
      title: 'Video Merger',
      category: _Category.video,
      subtitle: 'Join multiple videos into one',
      color: Colors.deepPurple,
      screen: const MergerScreen(),
    ),
    _FeatureItem(
      emoji: '🔇',
      title: 'Remove Audio',
      category: _Category.audio,
      subtitle: 'Create a silent video',
      color: Colors.indigo,
      screen: const RemoveAudioScreen(),
    ),
    _FeatureItem(
      emoji: '🎵',
      title: 'Extract Audio',
      category: _Category.audio,
      subtitle: 'Save MP3, M4A or WAV',
      color: Colors.teal,
      screen: const ExtractMp3Screen(),
    ),
    _FeatureItem(
      emoji: '✂️',
      title: 'Video Splitter',
      category: _Category.video,
      subtitle: 'Cut into equal parts',
      color: Colors.orange,
      screen: const SplitterScreen(),
    ),
    _FeatureItem(
      emoji: '📦',
      title: 'Video Compressor',
      category: _Category.video,
      subtitle: 'Reduce video file size',
      color: Colors.blue,
      screen: const CompressorScreen(),
    ),
    _FeatureItem(
      emoji: '🎞️',
      title: 'Video Trimmer',
      category: _Category.video,
      subtitle: 'Interactive trim timeline',
      color: Colors.pink,
      screen: const TrimmerScreen(),
    ),
    _FeatureItem(
      emoji: '🔄',
      title: 'Video Converter',
      category: _Category.video,
      subtitle: 'MP4, MKV, MOV, WEBM, AVI',
      color: Colors.green,
      screen: const ConverterScreen(),
    ),
    _FeatureItem(
      emoji: '⏩',
      title: 'Speed Changer',
      category: _Category.video,
      subtitle: 'Slow motion or fast forward',
      color: Colors.red,
      screen: const SpeedScreen(),
    ),
    _FeatureItem(
      emoji: '🔃',
      title: 'Rotate & Flip',
      category: _Category.video,
      subtitle: 'Fix sideways videos',
      color: Colors.cyan,
      screen: const RotateScreen(),
    ),
    _FeatureItem(
      emoji: '🖼️',
      title: 'Video to GIF',
      category: _Category.video,
      subtitle: 'Make an animated GIF',
      color: Colors.amber,
      screen: const GifScreen(),
    ),
    _FeatureItem(
      emoji: '📸',
      title: 'Extract Frame',
      category: _Category.video,
      subtitle: 'Save a moment as a picture',
      color: Colors.lightGreen,
      screen: const FrameScreen(),
    ),
    _FeatureItem(
      emoji: '🎶',
      title: 'Add Audio',
      category: _Category.audio,
      subtitle: 'Put new sound on a video',
      color: Colors.deepOrange,
      screen: const ReplaceAudioScreen(),
    ),
    _FeatureItem(
      emoji: '🗜️',
      title: 'Image Compressor',
      category: _Category.image,
      subtitle: 'Make pictures smaller',
      color: Colors.blue,
      screen: const ImageCompressScreen(),
    ),
    _FeatureItem(
      emoji: '📐',
      title: 'Resize Image',
      category: _Category.image,
      subtitle: 'Pixels, percent or presets',
      color: Colors.indigo,
      screen: const ImageResizeScreen(),
    ),
    _FeatureItem(
      emoji: '📏',
      title: 'Exact Size',
      category: _Category.image,
      subtitle: 'Size in px or cm + KB limit',
      color: Colors.teal,
      screen: const ExactSizeScreen(),
    ),
    _FeatureItem(
      emoji: '🔁',
      title: 'Image Converter',
      category: _Category.image,
      subtitle: 'JPG, PNG, WEBP',
      color: Colors.green,
      screen: const ImageConvertScreen(),
    ),
    _FeatureItem(
      emoji: '📄',
      title: 'Images to PDF',
      category: _Category.image,
      subtitle: 'Many pictures, one PDF',
      color: Colors.red,
      screen: const ImagesToPdfScreen(),
    ),
    _FeatureItem(
      emoji: '✂️',
      title: 'Crop Image',
      category: _Category.image,
      subtitle: 'Free or fixed shapes',
      color: Colors.orange,
      screen: const ImageCropScreen(),
    ),
    _FeatureItem(
      emoji: '🔃',
      title: 'Rotate & Flip',
      category: _Category.image,
      subtitle: 'Turn, mirror, straighten',
      color: Colors.cyan,
      screen: const ImageRotateScreen(),
    ),
    _FeatureItem(
      emoji: '🛡️',
      title: 'Remove Metadata',
      category: _Category.image,
      subtitle: 'Hide location and camera info',
      color: Colors.teal,
      screen: const StripMetadataScreen(),
    ),
    _FeatureItem(
      emoji: '🎨',
      title: 'Adjust & Filters',
      category: _Category.image,
      subtitle: 'Brightness, colour, looks',
      color: Colors.pink,
      screen: const ImageAdjustScreen(),
    ),
    _FeatureItem(
      emoji: '💧',
      title: 'Watermark',
      category: _Category.image,
      subtitle: 'Add text or a logo',
      color: Colors.lightBlue,
      screen: const WatermarkScreen(),
    ),
    _FeatureItem(
      emoji: '🧩',
      title: 'Collage Maker',
      category: _Category.image,
      subtitle: 'Join pictures into one',
      color: Colors.deepPurple,
      screen: const CollageScreen(),
    ),
    _FeatureItem(
      emoji: '🔲',
      title: 'Fit to Frame',
      category: _Category.image,
      subtitle: 'Square, story, border',
      color: Colors.amber,
      screen: const ImageFrameScreen(),
    ),
    _FeatureItem(
      emoji: '🎞️',
      title: 'Slideshow Maker',
      category: _Category.image,
      subtitle: 'Pictures to a video',
      color: Colors.deepOrange,
      screen: const SlideshowScreen(),
    ),
    _FeatureItem(
      emoji: '🪪',
      title: 'Passport Photo',
      category: _Category.image,
      subtitle: 'Crop and print sheet',
      color: Colors.brown,
      screen: const PassportScreen(),
    ),
    _FeatureItem(
      emoji: '🔤',
      title: 'Text from Image',
      category: _Category.image,
      subtitle: 'Read and copy text',
      color: Colors.lightGreen,
      screen: const OcrScreen(),
    ),
  ];
}

class _FeatureItem {
  final String emoji;
  final String title;
  final _Category category;
  final String subtitle;
  final Color color;
  final Widget screen;

  const _FeatureItem({
    required this.emoji,
    required this.title,
    required this.category,
    required this.subtitle,
    required this.color,
    required this.screen,
  });
}

/// Shown on a tab that has no tools yet.
class _ComingSoon extends StatelessWidget {
  final _Category category;
  const _ComingSoon({required this.category});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              category.icon,
              size: 56,
              color: colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              '${category.label} tools are coming soon',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
