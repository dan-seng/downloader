import 'package:flutter/foundation.dart';
import '../models/download_task.dart';
import '../models/quality_option.dart';
import '../models/video_info.dart';
import '../services/download_service.dart';
import '../services/storage_service.dart';

/// Controller managing quality selection, destination directories,
/// and live download tasks.
class DownloadController extends ChangeNotifier {
  final DownloadService _downloadService;
  final StorageService _storageService;

  String _downloadDirectory = '';
  QualityOption? _selectedQuality;
  List<QualityOption> _availableQualities = [];
  DownloadTask? _currentTask;
  String? _errorMessage;

  DownloadController({
    DownloadService? downloadService,
    StorageService? storageService,
  })  : _downloadService = downloadService ?? DownloadService(),
        _storageService = storageService ?? const StorageService();

  String get downloadDirectory => _downloadDirectory;
  QualityOption? get selectedQuality => _selectedQuality;
  List<QualityOption> get availableQualities => _availableQualities;
  DownloadTask? get currentTask => _currentTask;
  String? get errorMessage => _errorMessage;
  bool get isDownloading => _downloadService.isDownloading;

  /// Initializes the default download directory from system paths.
  Future<void> initialize() async {
    if (_downloadDirectory.isEmpty) {
      _downloadDirectory = await _storageService.getDefaultDownloadsDirectory();
      notifyListeners();
    }
  }

  /// Sets the currently analyzed video and derives available quality options.
  void setVideo(VideoInfo? video) {
    if (video == null) {
      _availableQualities = [];
      _selectedQuality = null;
    } else {
      _availableQualities = QualityOption.fromVideoInfo(video);
      // Select 1080p by default if present, else first available option
      _selectedQuality = _availableQualities.firstWhere(
        (q) => q.height == 1080,
        orElse: () => _availableQualities.first,
      );
    }
    notifyListeners();
  }

  /// Selects a download quality/format option.
  void selectQuality(QualityOption option) {
    _selectedQuality = option;
    notifyListeners();
  }

  /// Opens native folder picker dialog to select destination directory.
  Future<void> pickDirectory() async {
    final picked = await _storageService.pickDirectory(
      initialDirectory: _downloadDirectory.isNotEmpty ? _downloadDirectory : null,
    );
    if (picked != null && picked.isNotEmpty) {
      _downloadDirectory = picked;
      notifyListeners();
    }
  }

  /// Starts downloading the analyzed video.
  Future<void> startDownload(VideoInfo video) async {
    if (_selectedQuality == null) {
      _errorMessage = 'Please select a quality format before downloading.';
      notifyListeners();
      return;
    }

    if (_downloadDirectory.isEmpty) {
      await initialize();
    }

    _errorMessage = null;

    try {
      await _downloadService.startDownload(
        video: video,
        quality: _selectedQuality!,
        destinationDirectory: _downloadDirectory,
        onProgress: (task) {
          _currentTask = task;
          notifyListeners();
        },
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Cancels the ongoing download.
  Future<void> cancelDownload() async {
    await _downloadService.cancelCurrentDownload();
    notifyListeners();
  }

  /// Opens the downloaded file in the native system application.
  Future<void> openFile() async {
    final path = _currentTask?.destinationPath;
    if (path != null && path.isNotEmpty) {
      await _storageService.openFile(path);
    } else {
      await openFolder();
    }
  }

  /// Opens the destination directory in the native file manager.
  Future<void> openFolder() async {
    if (_downloadDirectory.isNotEmpty) {
      await _storageService.openDirectory(_downloadDirectory);
    }
  }

  /// Clears the completed or failed download banner.
  void dismissTask() {
    if (!isDownloading) {
      _currentTask = null;
      notifyListeners();
    }
  }
}
