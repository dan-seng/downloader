import '../core/utils/formatters.dart';

/// Status of a download task.
enum DownloadStatus {
  queued,
  downloading,
  completed,
  failed,
  cancelled,
}

/// Represents an individual video download job.
class DownloadTask {
  final String id;
  final String url;
  final String title;
  final String? formatId;

  String? destinationPath;
  DownloadStatus status;
  double progress; // 0.0 to 1.0
  double? speed; // bytes per second
  Duration? eta;
  String? errorMessage;
  int? transferredBytes;
  int? totalBytes;

  DownloadTask({
    required this.id,
    required this.url,
    required this.title,
    this.destinationPath,
    this.formatId,
    this.status = DownloadStatus.queued,
    this.progress = 0.0,
    this.speed,
    this.eta,
    this.errorMessage,
    this.transferredBytes,
    this.totalBytes,
  });

  bool get isCompleted => status == DownloadStatus.completed;
  bool get isFailed => status == DownloadStatus.failed;
  bool get isCancelled => status == DownloadStatus.cancelled;
  bool get isDownloading => status == DownloadStatus.downloading;

  String get formattedSpeed {
    if (speed == null || speed! <= 0) return '0.0 MB/s';
    if (speed! < 1024 * 1024) {
      return '${(speed! / 1024).toStringAsFixed(1)} KB/s';
    }
    return '${(speed! / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }

  String get formattedEta {
    if (eta == null) return '—:—';
    final totalSeconds = eta!.inSeconds;
    if (totalSeconds < 0) return '—:—';
    final minutes = eta!.inMinutes;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedSizeProgress {
    if (transferredBytes == null || transferredBytes! <= 0) {
      if (totalBytes != null && totalBytes! > 0) {
        return '0 B / ${Formatters.formatBytes(totalBytes)}';
      }
      return '';
    }
    final transferred = Formatters.formatBytes(transferredBytes);
    if (totalBytes != null && totalBytes! > 0) {
      final total = Formatters.formatBytes(totalBytes);
      return '$transferred / $total';
    }
    return '$transferred downloaded';
  }
}
