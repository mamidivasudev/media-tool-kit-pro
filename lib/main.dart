import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/services/ffmpeg_service.dart';
import 'core/services/file_service.dart';
import 'providers/theme_provider.dart';
import 'providers/merger_provider.dart';
import 'providers/remove_audio_provider.dart';
import 'providers/extract_mp3_provider.dart';
import 'providers/splitter_provider.dart';
import 'providers/compressor_provider.dart';
import 'providers/trimmer_provider.dart';
import 'providers/converter_provider.dart';
import 'providers/speed_provider.dart';
import 'providers/rotate_provider.dart';
import 'providers/gif_provider.dart';
import 'providers/frame_provider.dart';
import 'providers/replace_audio_provider.dart';
import 'providers/image/image_compress_provider.dart';
import 'providers/image/image_resize_provider.dart';
import 'providers/image/image_convert_provider.dart';
import 'providers/image/images_to_pdf_provider.dart';
import 'providers/image/image_crop_provider.dart';
import 'providers/image/image_rotate_provider.dart';
import 'providers/image/strip_metadata_provider.dart';
import 'providers/image/image_adjust_provider.dart';
import 'providers/image/watermark_provider.dart';
import 'providers/image/collage_provider.dart';
import 'providers/image/image_frame_provider.dart';
import 'providers/image/slideshow_provider.dart';
import 'providers/image/passport_provider.dart';
import 'providers/image/ocr_provider.dart';
import 'features/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Remove leftovers from earlier sessions. Not awaited, so start-up is fast.
  FFmpegService.instance.clearCache();
  FileService.instance.clearPickedFiles();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => MergerProvider()),
        ChangeNotifierProvider(create: (_) => RemoveAudioProvider()),
        ChangeNotifierProvider(create: (_) => ExtractMp3Provider()),
        ChangeNotifierProvider(create: (_) => SplitterProvider()),
        ChangeNotifierProvider(create: (_) => CompressorProvider()),
        ChangeNotifierProvider(create: (_) => TrimmerProvider()),
        ChangeNotifierProvider(create: (_) => ConverterProvider()),
        ChangeNotifierProvider(create: (_) => SpeedProvider()),
        ChangeNotifierProvider(create: (_) => RotateProvider()),
        ChangeNotifierProvider(create: (_) => GifProvider()),
        ChangeNotifierProvider(create: (_) => FrameProvider()),
        ChangeNotifierProvider(create: (_) => ReplaceAudioProvider()),
        ChangeNotifierProvider(create: (_) => ImageCompressProvider()),
        ChangeNotifierProvider(create: (_) => ImageResizeProvider()),
        ChangeNotifierProvider(create: (_) => ImageConvertProvider()),
        ChangeNotifierProvider(create: (_) => ImagesToPdfProvider()),
        ChangeNotifierProvider(create: (_) => ImageCropProvider()),
        ChangeNotifierProvider(create: (_) => ImageRotateProvider()),
        ChangeNotifierProvider(create: (_) => StripMetadataProvider()),
        ChangeNotifierProvider(create: (_) => ImageAdjustProvider()),
        ChangeNotifierProvider(create: (_) => WatermarkProvider()),
        ChangeNotifierProvider(create: (_) => CollageProvider()),
        ChangeNotifierProvider(create: (_) => ImageFrameProvider()),
        ChangeNotifierProvider(create: (_) => SlideshowProvider()),
        ChangeNotifierProvider(create: (_) => PassportProvider()),
        ChangeNotifierProvider(create: (_) => OcrProvider()),
      ],
      child: const VideoToolkitApp(),
    ),
  );
}

class VideoToolkitApp extends StatelessWidget {
  const VideoToolkitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'Media Toolkit Pro',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          builder: (context, child) {
            // Status bar icons must contrast with the current theme.
            final dark = Theme.of(context).brightness == Brightness.dark;
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness:
                    dark ? Brightness.light : Brightness.dark,
                statusBarBrightness: dark ? Brightness.dark : Brightness.light,
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const HomeScreen(),
        );
      },
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6750A4),
        brightness: brightness,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
