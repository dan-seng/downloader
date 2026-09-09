import 'dart:async';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import '../models/audio_config.dart';
import '../models/download_archive_item.dart';
import '../models/download_task.dart';
import '../models/playlist_info.dart';
import '../models/quality_option.dart';
import '../models/speed_limit.dart';
import '../models/time_range_clip.dart';
import '../models/video_info.dart';
import '../services/archive_service.dart';
import '../services/download_service.dart';
import '../services/engine_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

/// Controller managing quality selection, destination directories,
/// live download tasks, desktop notifications, persistent library archives,
/// and hybrid yt-dlp / FFmpeg engine lifecycle.
class DownloadController extends ChangeNotifier {
  final DownloadService _downloadService;
  final StorageService _storageService;
  final NotificationService _notificationService;
  final ArchiveService _archiveService;
  final EngineService _engineService;

  String _downloadDirectory = '';
  QualityOption? _selectedQuality;
  List<QualityOption> _availableQualities = [];
  DownloadTask? _currentTask;
  String? _errorMessage;
  AudioConfig _audioConfig = const AudioConfig();
  SpeedLimit _speedLimit = SpeedLimit.unlimited;
  ScheduleDelay _scheduleDelay = ScheduleDelay.none;
  Completer<void>? _scheduleCancelCompleter;
  TimeRangeClip _clip = const TimeRangeClip();

  List<DownloadArchiveItem> _archiveItems = [];
  String _archiveSearchQuery = '';
  ArchiveFilter _archiveFilter = ArchiveFilter.all;
  ArchiveSort _archiveSort = ArchiveSort.newest;
  bool _notificationsEnabled = true;

  EngineInfo? _engineInfo;
  bool _isEngineUpdating = false;
  double _engineUpdateProgress = 0.0;
  String _engineUpdateMessage = '';

  DownloadController({
    DownloadService? downloadService,
    StorageService? storageService,
    NotificationService? notificationService,
    ArchiveService? archiveService,
    EngineService? engineService,
  })  : _engineService = engineService ?? EngineService(),
        _storageService = storageService ?? const StorageService(),
        _notificationService = notificationService ?? NotificationService(),
        _archiveService = archiveService ?? ArchiveService(),
        _downloadService = downloadService ??
            DownloadService(
              engineService: engineService ?? EngineService(),
            );

  final List<String> _consoleLogs = [];
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
  TimeRangeClip get clip => _clip;
  bool get notificationsEnabled => _notificationsEnabled;
  NotificationService get notificationService => _notificationService;
  ArchiveService get archiveService => _archiveService;
  EngineService get engineService => _engineService;
  EngineInfo? get engineInfo => _engineInfo;
  bool get isEngineUpdating => _isEngineUpdating;
  double get engineUpdateProgress => _engineUpdateProgress;
  String get engineUpdateMessage => _engineUpdateMessage;
  List<DownloadArchiveItem> get archiveItems => List.unmodifiable(_archiveItems);
  String get archiveSearchQuery => _archiveSearchQuery;
  ArchiveFilter get archiveFilter => _archiveFilter;
  ArchiveSort get archiveSort => _archiveSort;
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

  /// Sets or updates the clip trimming range configuration.
  void setClip(TimeRangeClip clip) {
    _clip = clip;
    if (clip.isEnabled) {
      addLog('clip range set: ${clip.formatSummary()}');
    } else {
      addLog('clip trimming disabled — downloading full media');
    }
    notifyListeners();
  }

  /// Toggles clip trimming mode on/off.
  void toggleClip(bool enabled) {
    _clip = _clip.copyWith(isEnabled: enabled);
    addLog(enabled ? 'clip mode enabled: ${_clip.formatSummary()}' : 'clip mode disabled');
    notifyListeners();
  }

  /// Sets the start and end range for the clip.
  void setClipRange(Duration start, Duration? end) {
    _clip = _clip.copyWith(start: start, end: end);
    notifyListeners();
  }

  /// Applies a quick preset length from start (e.g. 30s, 60s, 300s).
  void applyClipPreset(Duration duration) {
    _clip = _clip.copyWith(
      isEnabled: true,
      start: Duration.zero,
      end: duration,
    );
    addLog('applied clip preset: ${_clip.formatSummary()}');
    notifyListeners();
  }

  /// Resets clip trimming back to the beginning.
  void resetClip([Duration? maxDuration]) {
    _clip = TimeRangeClip(
      isEnabled: false,
      start: Duration.zero,
      end: maxDuration,
    );
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

  /// Sets whether OS-level desktop notifications and sound effects are enabled.
  void setNotificationsEnabled(bool enabled) {
    _notificationsEnabled = enabled;
    _notificationService.notificationsEnabled = enabled;
    addLog('desktop notifications ${enabled ? "enabled" : "muted"}');
    notifyListeners();
  }

  /// Loads persistent download archive from disk.
  Future<void> loadArchive() async {
    _archiveItems = await _archiveService.loadArchive();
    notifyListeners();
  }

  /// Sets real-time query string to search archive items by title, filename, or URL.
  void setArchiveSearchQuery(String query) {
    _archiveSearchQuery = query;
    notifyListeners();
  }

  /// Sets category filter for the archive library.
  void setArchiveFilter(ArchiveFilter filter) {
    _archiveFilter = filter;
    notifyListeners();
  }

  /// Sets sorting order for the archive library.
  void setArchiveSort(ArchiveSort sort) {
    _archiveSort = sort;
    notifyListeners();
  }

  /// Returns sorted and filtered archive items matching current query and filter tab.
  List<DownloadArchiveItem> get filteredArchiveItems {
    var items = List<DownloadArchiveItem>.from(_archiveItems);

    switch (_archiveFilter) {
      case ArchiveFilter.all:
        break;
      case ArchiveFilter.video:
        items = items.where((it) => !it.isAudioOnly).toList();
        break;
      case ArchiveFilter.audio:
        items = items.where((it) => it.isAudioOnly).toList();
        break;
      case ArchiveFilter.playlist:
        items = items.where((it) => it.playlistTitle != null && it.playlistTitle!.isNotEmpty).toList();
        break;
    }

    if (_archiveSearchQuery.trim().isNotEmpty) {
      final q = _archiveSearchQuery.trim().toLowerCase();
      items = items.where((it) {
        return it.title.toLowerCase().contains(q) ||
            it.url.toLowerCase().contains(q) ||
            it.fileName.toLowerCase().contains(q);
      }).toList();
    }

    switch (_archiveSort) {
      case ArchiveSort.newest:
        items.sort((a, b) => b.completedAt.compareTo(a.completedAt));
        break;
      case ArchiveSort.oldest:
        items.sort((a, b) => a.completedAt.compareTo(b.completedAt));
        break;
      case ArchiveSort.largest:
        items.sort((a, b) => b.fileSizeBytes.compareTo(a.fileSizeBytes));
        break;
      case ArchiveSort.titleAZ:
        items.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
    }

    return items;
  }

  /// Deletes an archive record and optionally purges the physical file from disk.
  Future<bool> deleteArchiveItem(String id, {bool deleteFileFromDisk = false}) async {
    final success = await _archiveService.deleteItem(id, deleteFileFromDisk: deleteFileFromDisk);
    if (success) {
      addLog(deleteFileFromDisk
          ? 'deleted archive record and purged file from disk'
          : 'removed item from archive library');
      await loadArchive();
    }
    return success;
  }

  /// Prunes archive entries whose files no longer exist on disk.
  Future<int> clearMissingArchive() async {
    final count = await _archiveService.clearMissing();
    if (count > 0) {
      addLog('cleared $count missing items from archive');
      await loadArchive();
    }
    return count;
  }

  /// Opens an archived file in the default system viewer.
  Future<void> openArchiveFile(String filePath) async {
    await _storageService.openFile(filePath);
  }

  /// Opens the directory containing an archived file in the system file manager.
  Future<void> openArchiveFolder(String filePath) async {
    if (filePath.isEmpty) {
      await _storageService.openDirectory(_downloadDirectory);
      return;
    }
    final parent = io.File(filePath).parent.path;
    await _storageService.openDirectory(parent);
  }

  /// Records completed download into persistent archive and triggers OS notification.
  Future<void> _recordArchiveAndNotify({
    required DownloadTask task,
    required String url,
    required String qualityLabel,
    required bool isAudioOnly,
    String? qualityId,
    String? playlistTitle,
    bool notify = true,
  }) async {
    final path = task.destinationPath ?? '';
    var size = 0;
    if (path.isNotEmpty) {
      try {
        final file = io.File(path);
        if (file.existsSync()) {
          size = file.lengthSync();
        }
      } catch (_) {}
    }

    final archiveItem = DownloadArchiveItem(
      id: '${task.id}_${DateTime.now().millisecondsSinceEpoch}',
      title: task.title,
      url: url,
      filePath: path,
      formatLabel: qualityLabel,
      fileSizeBytes: size,
      completedAt: DateTime.now(),
      isAudioOnly: isAudioOnly,
      playlistTitle: playlistTitle,
      qualityId: qualityId,
      fileExists: path.isNotEmpty && io.File(path).existsSync(),
    );

    await _archiveService.saveItem(archiveItem);
    await loadArchive();

    if (notify) {
      unawaited(_notificationService.sendDownloadCompleteNotification(
        title: task.title,
        filePath: path,
        onOpenFile: () => _storageService.openFile(path),
        onOpenFolder: () => _storageService.openDirectory(_downloadDirectory),
      ));
    }
  }

  /// Initializes the default download directory from system paths, loads archive, and verifies engine packages.
  Future<void> initialize({bool autoInstallMissing = true}) async {
    if (_downloadDirectory.isEmpty) {
      _downloadDirectory = await _storageService.getDefaultDownloadsDirectory();
    }
    await loadArchive();
    await checkEngine();
    if (autoInstallMissing && _engineInfo != null && !_engineInfo!.isReady) {
      await installRequiredPackages();
    }
    notifyListeners();
  }

  /// Runs a discovery scan to check for yt-dlp and FFmpeg binaries across the hybrid hierarchy.
  Future<void> checkEngine() async {
    try {
      _engineInfo = await _engineService.checkEngine();
      if (_engineInfo != null) {
        if (_engineInfo!.isYtdlpReady) {
          addLog('engine verified: yt-dlp ${_engineInfo!.ytdlpVersion ?? ""} (${_engineInfo!.sourceLabel})');
        } else {
          addLog('engine warning: yt-dlp not detected in user bin, bundle, or system PATH');
        }
        if (_engineInfo!.ffmpegAvailable) {
          addLog('engine verified: FFmpeg ${_engineInfo!.ffmpegVersion ?? ""} (${_engineInfo!.ffmpegSourceLabel})');
        } else {
          addLog('engine notice: FFmpeg not detected in user bin, bundle, or system PATH');
        }
      }
    } catch (e) {
      addLog('engine check error: $e');
    }
    notifyListeners();
  }

  /// Downloads and installs all missing engine packages (yt-dlp and FFmpeg) into the user vault.
  Future<bool> installRequiredPackages() async {
    if (_isEngineUpdating) return false;
    _isEngineUpdating = true;
    _engineUpdateProgress = 0.05;
    _engineUpdateMessage = 'Installing packages...';
    notifyListeners();

    try {
      addLog('initiating automatic package installation (yt-dlp & FFmpeg)...');
      final needsYtdlp = _engineInfo == null || !_engineInfo!.isYtdlpReady;
      final needsFfmpeg = _engineInfo == null || !_engineInfo!.ffmpegAvailable;

      if (needsYtdlp && needsFfmpeg) {
        final info = await _engineService.downloadOrUpdateAllPackages(
          onProgress: (progress, status) {
            _engineUpdateProgress = progress;
            _engineUpdateMessage = status;
            notifyListeners();
          },
        );
        _engineInfo = info;
      } else if (needsYtdlp) {
        final info = await _engineService.downloadOrUpdateYtDlp(
          onProgress: (progress, status) {
            _engineUpdateProgress = progress;
            _engineUpdateMessage = 'Installing packages: $status';
            notifyListeners();
          },
        );
        _engineInfo = info;
      } else if (needsFfmpeg) {
        final info = await _engineService.downloadOrUpdateFfmpeg(
          onProgress: (progress, status) {
            _engineUpdateProgress = progress;
            _engineUpdateMessage = 'Installing packages: $status';
            notifyListeners();
          },
        );
        _engineInfo = info;
      }

      _engineUpdateMessage = 'Packages installed successfully';
      addLog('packages installed successfully: yt-dlp ${_engineInfo?.ytdlpVersion ?? ""} & FFmpeg ${_engineInfo?.ffmpegVersion ?? ""}');
      return true;
    } catch (e) {
      _engineUpdateMessage = 'Failed to install packages: $e';
      addLog('package installation error: $e');
      return false;
    } finally {
      _isEngineUpdating = false;
      notifyListeners();
    }
  }

  /// Downloads or updates yt-dlp into the user bin vault (~/.spidey_dlx/bin/yt-dlp).
  Future<bool> updateEngine() async {
    if (_isEngineUpdating) return false;
    _isEngineUpdating = true;
    _engineUpdateProgress = 0.05;
    _engineUpdateMessage = 'Connecting to GitHub releases...';
    notifyListeners();

    try {
      addLog('initiating engine download from official release channel...');
      final info = await _engineService.downloadOrUpdateYtDlp(
        onProgress: (progress, status) {
          _engineUpdateProgress = progress;
          _engineUpdateMessage = status;
          notifyListeners();
        },
      );
      _engineInfo = info;
      _engineUpdateMessage = 'Engine ready: yt-dlp ${info.ytdlpVersion ?? "installed"}';
      addLog('engine updated successfully: yt-dlp ${info.ytdlpVersion ?? ""} (${info.sourceLabel})');
      return true;
    } catch (e) {
      _engineUpdateMessage = 'Failed to update engine: $e';
      addLog('engine update error: $e');
      return false;
    } finally {
      _isEngineUpdating = false;
      notifyListeners();
    }
  }

  /// Downloads or updates FFmpeg into the user bin vault (~/.spidey_dlx/bin/ffmpeg).
  Future<bool> updateFfmpeg() async {
    if (_isEngineUpdating) return false;
    _isEngineUpdating = true;
    _engineUpdateProgress = 0.05;
    _engineUpdateMessage = 'Connecting to FFmpeg release server...';
    notifyListeners();

    try {
      addLog('initiating FFmpeg download...');
      final info = await _engineService.downloadOrUpdateFfmpeg(
        onProgress: (progress, status) {
          _engineUpdateProgress = progress;
          _engineUpdateMessage = status;
          notifyListeners();
        },
      );
      _engineInfo = info;
      _engineUpdateMessage = 'FFmpeg ready: ${info.ffmpegVersion ?? "installed"}';
      addLog('FFmpeg updated successfully: ${info.ffmpegVersion ?? ""} (${info.ffmpegSourceLabel})');
      return true;
    } catch (e) {
      _engineUpdateMessage = 'Failed to update FFmpeg: $e';
      addLog('FFmpeg update error: $e');
      return false;
    } finally {
      _isEngineUpdating = false;
      notifyListeners();
    }
  }

  /// Sets the currently analyzed video and derives available quality options.
  void setVideo(VideoInfo? video) {
    if (video == null) {
      _availableQualities = [];
      _selectedQuality = null;
      _clip = const TimeRangeClip();
    } else {
      _availableQualities = QualityOption.fromVideoInfo(video);
      _clip = TimeRangeClip(
        isEnabled: false,
        start: Duration.zero,
        end: video.duration,
      );

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
      addLog('destination folder set: $picked');
      notifyListeners();
    }
  }

  /// Sets the download destination directory directly.
  void setDownloadDirectory(String path) {
    final trimmed = path.trim();
    if (trimmed.isNotEmpty) {
      _downloadDirectory = trimmed;
      addLog('destination folder set: $trimmed');
      notifyListeners();
    }
  }

  /// Opens the current destination directory in the native file manager.
  Future<void> openDownloadDirectory() async => openFolder();

  /// Returns common system directory presets (Downloads, Videos, Desktop, Home).
  Future<Map<String, String>> getQuickDirectories() async {
    return _storageService.getQuickDirectories();
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
        url: (video.webpageUrl != null && video.webpageUrl!.isNotEmpty)
            ? video.webpageUrl!
            : video.id,
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
        clip: _clip.isEnabled ? _clip : null,
        onProgress: (task) {
          _currentTask = task;
          if (task.status == DownloadStatus.completed) {
            if (!_recentQueue.any((t) => t.id == task.id)) {
              _recentQueue.insert(0, task);
            }
            addLog('download complete — saved to ${task.destinationPath}');
            _recordArchiveAndNotify(
              task: task,
              url: video.webpageUrl ?? '',
              qualityLabel: _selectedQuality?.label ?? 'Universal',
              isAudioOnly: _selectedQuality?.isAudioOnly == true,
              qualityId: _selectedQuality?.id,
            );
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

        if (task.status == DownloadStatus.completed) {
          _recordArchiveAndNotify(
            task: task,
            url: task.url,
            qualityLabel: qualityToUse.label,
            isAudioOnly: qualityToUse.isAudioOnly,
            qualityId: qualityToUse.id,
            playlistTitle: playlist.title,
            notify: false,
          );
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
    if (completed > 0) {
      unawaited(_notificationService.sendBatchCompleteNotification(
        count: completed,
        destinationPath: _downloadDirectory,
        onOpenFolder: () => _storageService.openDirectory(_downloadDirectory),
      ));
    }
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
