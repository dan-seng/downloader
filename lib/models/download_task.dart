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
  });

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
}
