import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/audio_config.dart';
import '../models/download_task.dart';
import '../models/playlist_info.dart';
import '../models/quality_option.dart';
import '../models/speed_limit.dart';
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
  AudioConfig _audioConfig = const AudioConfig();
  SpeedLimit _speedLimit = SpeedLimit.unlimited;
  ScheduleDelay _scheduleDelay = ScheduleDelay.none;
  Completer<void>? _scheduleCancelCompleter;


  DownloadController({
    DownloadService? downloadService,
    StorageService? storageService,
  })  : _downloadService = downloadService ?? DownloadService(),
        _storageService = storageService ?? const StorageService();

  final List<String> _consoleLogs = ['deck ready — waiting for a link'];
  final List<DownloadTask> _recentQueue = [];
  final List<DownloadTask> _batchQueue = [];
  bool _isBatchRunning = false;
  int _batchCurrentIndex = 0;

  String get downloadDirectory => _downloadDirectory;
  QualityOption? get selectedQuality => _selectedQuality;
  List<QualityOption> get availableQualities => _availableQualities;
  DownloadTask? get currentTask => _currentTask;
  String? get errorMessage => _errorMessage;
  AudioConfig get audioConfig => _audioConfig;
  SpeedLimit get speedLimit => _speedLimit;
  ScheduleDelay get scheduleDelay => _scheduleDelay;
  bool get isDownloading =>
      _isBatchRunning ||
      _downloadService.isDownloading ||
      (_currentTask != null &&
          (_currentTask!.status == DownloadStatus.downloading ||
              _currentTask!.status == DownloadStatus.queued));
  bool get isBatchRunning => _isBatchRunning;
  int get batchCurrentIndex => _batchCurrentIndex;
  List<String> get consoleLogs => List.unmodifiable(_consoleLogs);
  List<DownloadTask> get recentQueue => List.unmodifiable(_recentQueue);
  List<DownloadTask> get batchQueue => List.unmodifiable(_batchQueue);
  int get batchTotalCount => _batchQueue.length;
  int get batchCompletedCount =>
      _batchQueue.where((t) => t.status == DownloadStatus.completed).length;

  /// Sets bandwidth speed throttling limit.
  void setSpeedLimit(SpeedLimit limit) {
    _speedLimit = limit;
    addLog('bandwidth throttle set: ${limit.label}');
    notifyListeners();
  }

  /// Sets off-peak delayed start schedule.
  void setScheduleDelay(ScheduleDelay delay) {
    _scheduleDelay = delay;
    addLog('off-peak schedule set: ${delay.label}');
    notifyListeners();
  }

  /// Updates audio extraction configuration.
  void updateAudioConfig(AudioConfig config) {
    _audioConfig = config;
    addLog('audio profile updated: ${_audioConfig.format.id.toUpperCase()} ${_audioConfig.bitrate.id} (art: ${_audioConfig.embedThumbnail}, tags: ${_audioConfig.embedMetadata})');
    notifyListeners();
  }

  /// Sets audio bitrate.
  void setAudioBitrate(AudioBitrate bitrate) {
    _audioConfig = _audioConfig.copyWith(bitrate: bitrate);
    addLog('audio bitrate set: ${bitrate.label}');
    notifyListeners();
  }

  /// Sets audio container format.
  void setAudioFormat(AudioFormat format) {
    _audioConfig = _audioConfig.copyWith(format: format);
    addLog('audio container set: ${format.label}');
    notifyListeners();
  }

  /// Toggles cover art embedding.
  void setEmbedThumbnail(bool embed) {
    _audioConfig = _audioConfig.copyWith(embedThumbnail: embed);
    notifyListeners();
  }

  /// Toggles ID3 / stream metadata tagging.
  void setEmbedMetadata(bool embed) {
    _audioConfig = _audioConfig.copyWith(embedMetadata: embed);
    notifyListeners();
  }

  /// Applies a pre-configured audio preset.
  void applyAudioPreset(AudioConfig preset) {
    _audioConfig = preset;
    addLog('applied audio preset: ${_audioConfig.format.id.toUpperCase()} ${_audioConfig.bitrate.label}');
    notifyListeners();
  }

  /// Overall progress across all items in the active batch queue (0.0 to 1.0).
  double get overallBatchProgress {
    if (_batchQueue.isEmpty) return 0.0;
    final total = _batchQueue.fold<double>(0.0, (sum, t) => sum + t.progress);
    return total / _batchQueue.length;
  }

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

    if (_scheduleDelay.isDelayed) {
      final queuedTask = DownloadTask(
        id: video.id,
        url: video.webpageUrl ?? 'https://www.youtube.com/watch?v=${video.id}',
        title: video.title,
        destinationPath: _downloadDirectory,
        formatId: _selectedQuality!.id,
        status: DownloadStatus.queued,
        progress: 0.0,
      );
      _currentTask = queuedTask;
      notifyListeners();
      addLog('off-peak delay armed: waiting ${_scheduleDelay.label} before initiating transfer...');

      _scheduleCancelCompleter = Completer<void>();
      final wasCancelled = await Future.any([
        Future.delayed(_scheduleDelay.duration).then((_) => false),
        _scheduleCancelCompleter!.future.then((_) => true),
      ]);
      _scheduleCancelCompleter = null;

      if (wasCancelled) {
        queuedTask.status = DownloadStatus.cancelled;
        addLog('scheduled download aborted');
        notifyListeners();
        return;
      }
    }

    try {
      await _downloadService.startDownload(
        video: video,
        quality: _selectedQuality!,
        destinationDirectory: _downloadDirectory,
        audioConfig: _audioConfig,
        speedLimit: _speedLimit,
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

  /// Sets the currently analyzed playlist and generates universal quality profiles.
  void setPlaylist(PlaylistInfo? playlist) {
    if (playlist == null) {
      _availableQualities = [];
      _selectedQuality = null;
    } else {
      _availableQualities = const [
        QualityOption(
          id: '1080p',
          label: '1080p (Full HD)',
          formatSpecifier: 'bv*[height<=1080]+ba/b[height<=1080]',
          extension: 'mp4',
          height: 1080,
        ),
        QualityOption(
          id: '720p',
          label: '720p (HD)',
          formatSpecifier: 'bv*[height<=720]+ba/b[height<=720]',
          extension: 'mp4',
          height: 720,
        ),
        QualityOption(
          id: '480p',
          label: '480p (SD)',
          formatSpecifier: 'bv*[height<=480]+ba/b[height<=480]',
          extension: 'mp4',
          height: 480,
        ),
        QualityOption(
          id: 'audio_mp3',
          label: 'MP3 (Audio Only)',
          formatSpecifier: 'ba/b',
          extension: 'mp3',
          isAudioOnly: true,
        ),
        QualityOption(
          id: 'best',
          label: 'Best Available',
          formatSpecifier: 'bv*+ba/b',
          extension: 'mp4',
        ),
      ];
      _selectedQuality = _availableQualities.first;
      addLog('loaded playlist: "${playlist.title}" (${playlist.totalCount} tracks)');
    }
    notifyListeners();
  }

  /// Starts downloading the selected tracks in a playlist batch sequentially.
  Future<void> startBatchDownload(
    PlaylistInfo playlist, {
    QualityOption? quality,
    AudioConfig? audioConfig,
  }) async {
    final qualityToUse = quality ??
        _selectedQuality ??
        (availableQualities.isNotEmpty ? availableQualities.first : null);
    if (qualityToUse == null) {
      _errorMessage = 'Please select a quality format for the batch.';
      notifyListeners();
      return;
    }

    final audioConfigToUse = audioConfig ?? _audioConfig;

    final selectedItems = playlist.items.where((item) => item.isSelected).toList();
    if (selectedItems.isEmpty) {
      _errorMessage = 'No tracks selected for download.';
      notifyListeners();
      return;
    }

    _isBatchRunning = true;
    _batchCurrentIndex = 0;

    if (_downloadDirectory.isEmpty) {
      await initialize();
    }

    if (!_isBatchRunning) {
      // Cancelled during directory initialization
      return;
    }

    _errorMessage = null;
    _batchQueue.clear();
    for (final item in selectedItems) {
      _batchQueue.add(DownloadTask(
        id: item.id,
        url: item.url,
        title: item.title,
        destinationPath: _downloadDirectory,
        formatId: qualityToUse.id,
        status: DownloadStatus.queued,
      ));
    }

    addLog('\$ spidey-batch-start: ${selectedItems.length} tracks queued with ${qualityToUse.label}');
    notifyListeners();

    if (_scheduleDelay.isDelayed) {
      addLog('off-peak delay armed: waiting ${_scheduleDelay.label} before starting batch queue...');
      _scheduleCancelCompleter = Completer<void>();
      final wasCancelled = await Future.any([
        Future.delayed(_scheduleDelay.duration).then((_) => false),
        _scheduleCancelCompleter!.future.then((_) => true),
      ]);
      _scheduleCancelCompleter = null;

      if (wasCancelled || !_isBatchRunning) {
        addLog('scheduled batch queue aborted');
        await cancelBatch();
        return;
      }
    }

    for (var i = 0; i < _batchQueue.length; i++) {
      if (!_isBatchRunning) break;
      _batchCurrentIndex = i;
      final task = _batchQueue[i];
      _currentTask = task;
      task.status = DownloadStatus.downloading;
      notifyListeners();

      addLog('batch [${i + 1}/${_batchQueue.length}] fetching: "${task.title}"');

      final videoStub = VideoInfo(
        id: task.id,
        title: task.title,
        formats: const [],
        webpageUrl: task.url,
      );

      try {
        await _downloadService.startDownload(
          video: videoStub,
          quality: qualityToUse,
          destinationDirectory: _downloadDirectory,
          audioConfig: audioConfigToUse,
          speedLimit: _speedLimit,
          onProgress: (liveTask) {
            task.progress = liveTask.progress;
            task.speed = liveTask.speed;
            task.eta = liveTask.eta;
            task.status = liveTask.status;
            task.destinationPath = liveTask.destinationPath;
            notifyListeners();
          },
          onLog: (line) => addLog(line),
        );

        if (!_recentQueue.any((t) => t.id == task.id)) {
          _recentQueue.insert(0, task);
        }
      } catch (e) {
        task.status = DownloadStatus.failed;
        task.errorMessage = e.toString();
        addLog('failed track: "${task.title}" — $e');
        notifyListeners();
      }
    }

    _isBatchRunning = false;
    _currentTask = null;
    final completed =
        _batchQueue.where((t) => t.status == DownloadStatus.completed).length;
    addLog('\$ spidey-batch-complete: $completed/${_batchQueue.length} tracks finished');
    notifyListeners();
  }

  /// Cancels the entire batch download queue.
  Future<void> cancelBatch() async {
    if (_scheduleCancelCompleter != null &&
        !_scheduleCancelCompleter!.isCompleted) {
      _scheduleCancelCompleter!.complete();
    }
    addLog('batch download cancel requested');
    _isBatchRunning = false;
    await _downloadService.cancelCurrentDownload();
    for (final task in _batchQueue) {
      if (task.status == DownloadStatus.queued ||
          task.status == DownloadStatus.downloading) {
        task.status = DownloadStatus.cancelled;
      }
    }
    _currentTask = null;
    notifyListeners();
  }

  /// Cancels the ongoing download.
  Future<void> cancelDownload() async {
    if (_scheduleCancelCompleter != null &&
        !_scheduleCancelCompleter!.isCompleted) {
      _scheduleCancelCompleter!.complete();
    }
    if (_isBatchRunning) {
      await cancelBatch();
      return;
    }
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
