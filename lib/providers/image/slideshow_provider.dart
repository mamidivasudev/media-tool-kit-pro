import 'base_image_provider.dart';

enum SlideshowSize {
  landscape('Landscape 16:9', 1280, 720),
  fullHd('Full HD 1080p', 1920, 1080),
  portrait('Portrait 9:16', 720, 1280),
  square('Square 1:1', 1080, 1080);

  final String label;
  final int width;
  final int height;
  const SlideshowSize(this.label, this.width, this.height);
}

/// Provider that turns pictures into a video, with optional music.
class SlideshowProvider extends MultiImageProvider {
  static const List<double> durations = [1, 2, 3, 5, 8];

  double _secondsEach = 3;
  SlideshowSize _size = SlideshowSize.landscape;
  String? _audioPath;

  @override
  int get minImages => 2;
  @override
  int get maxImages => 30;

  double get secondsEach => _secondsEach;
  SlideshowSize get size => _size;
  String? get audioPath => _audioPath;
  double get totalSeconds => images.length * _secondsEach;

  void setSeconds(double v) {
    _secondsEach = v;
    notifyListeners();
  }

  void setSize(SlideshowSize v) {
    _size = v;
    notifyListeners();
  }

  Future<void> pickAudio() async {
    if (isBusy) return;
    final path = await fileService.pickAudio();
    if (path == null) return;
    _audioPath = path;
    notifyListeners();
  }

  void removeAudio() {
    _audioPath = null;
    notifyListeners();
  }

  Future<void> process() {
    if (!canProcess) return Future.value();
    final paths = List.of(images);
    return runJob(
      suffix: 'slideshow',
      extension: 'mp4',
      failMessage: 'Creating the slideshow failed.',
      job: (out, onProgress) => imageTools.slideshow(
        images: paths,
        output: out,
        secondsEach: _secondsEach,
        width: _size.width,
        height: _size.height,
        audioPath: _audioPath,
        onProgress: onProgress,
      ),
    );
  }

  // The result is a video, so it is saved with the video saver.
  @override
  Future<bool> saveToGallery() async {
    final path = outputPath;
    if (path == null) return false;
    return storage.saveVideoToGallery(path);
  }

  @override
  void onReset() {
    super.onReset();
    _audioPath = null;
  }
}
