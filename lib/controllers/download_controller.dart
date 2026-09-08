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

  final List<String> _consoleLogs = ['deck ready — waiting for a link'];
  final List<DownloadTask> _recentQueue = [];

  String get downloadDirectory => _downloadDirectory;
  QualityOption? get selectedQuality => _selectedQuality;
  List<QualityOption> get availableQualities => _availableQualities;
  DownloadTask? get currentTask => _currentTask;
  String? get errorMessage => _errorMessage;
  bool get isDownloading =>
      _downloadService.isDownloading ||
      (_currentTask != null &&
          _currentTask!.status == DownloadStatus.downloading);
  List<String> get consoleLogs => List.unmodifiable(_consoleLogs);
  List<DownloadTask> get recentQueue => List.unmodifiable(_recentQueue);

  /// Appends a timestamped log to the terminal output console.
  void addLog(String message) {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    _consoleLogs.add('$timeStr  $message');
    if (_consoleLogs.length > 200) {
      _consoleLogs.removeAt(0);
    }
    notifyListeners();
  }

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

      // Find the highest resolution specific video option
      QualityOption? bestOption;
      for (final option in _availableQualities) {
        if (!option.isAudioOnly && option.height != null && option.id != 'best') {
          if (bestOption == null ||
              (bestOption.height != null &&
                  option.height! > bestOption.height!)) {
            bestOption = option;
          }
        }
      }

      // Default to highest resolution specific option, or first available option
      _selectedQuality = bestOption ??
          (_availableQualities.isNotEmpty ? _availableQualities.first : null);

      addLog('resolved title: "${video.title}"');
      addLog('${video.formats.length} streams available, default: ${_selectedQuality?.label ?? "unknown"}');
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
    addLog('\$ spidey-get -f ${_selectedQuality!.id} "${video.title}"');

    try {
      await _downloadService.startDownload(
        video: video,
        quality: _selectedQuality!,
        destinationDirectory: _downloadDirectory,
        onProgress: (task) {
          _currentTask = task;
          if (task.status == DownloadStatus.completed) {
            if (!_recentQueue.any((t) => t.id == task.id)) {
              _recentQueue.insert(0, task);
            }
            addLog('download complete — saved to ${task.destinationPath}');
          } else if (task.status == DownloadStatus.failed) {
            addLog('download failed: ${task.errorMessage ?? "unknown error"}');
          }
          notifyListeners();
        },
        onLog: (line) {
          addLog(line);
        },
      );
    } catch (e) {
      _errorMessage = e.toString();
      addLog('error: $_errorMessage');
      notifyListeners();
    }
  }

  /// Cancels the ongoing download.
  Future<void> cancelDownload() async {
    addLog('download cancel requested');
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
