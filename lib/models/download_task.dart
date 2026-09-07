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
  final String? destinationPath;
  final String? formatId;

  DownloadStatus status;
  double progress; // 0.0 to 1.0 (or percentage)
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
}
