import 'dart:io' as io;

/// Filter categories for archive items.
enum ArchiveFilter {
  all('ALL', 'All Downloads'),
  video('VIDEO', 'Video Files'),
  audio('AUDIO', 'Audio Tracks'),
  playlist('PLAYLIST', 'Playlists');

  final String id;
  final String label;

  const ArchiveFilter(this.id, this.label);
}

/// Sort criteria for the archive library deck.
enum ArchiveSort {
  newest('NEWEST', 'Date (Newest First)'),
  oldest('OLDEST', 'Date (Oldest First)'),
  largest('SIZE', 'File Size (Largest First)'),
  titleAZ('A-Z', 'Title (A-Z)');

  final String id;
  final String label;

  const ArchiveSort(this.id, this.label);
}

/// Represents an individual completed download recorded in the permanent archive library.
class DownloadArchiveItem {
  final String id;
  final String title;
  final String url;
  final String filePath;
  final String formatLabel;
  final int fileSizeBytes;
  final DateTime completedAt;
  final bool isAudioOnly;
  final String? playlistTitle;
  final String? qualityId;
  final bool fileExists;

  const DownloadArchiveItem({
    required this.id,
    required this.title,
    required this.url,
    required this.filePath,
    required this.formatLabel,
    required this.fileSizeBytes,
    required this.completedAt,
    this.isAudioOnly = false,
    this.playlistTitle,
    this.qualityId,
    this.fileExists = true,
  });

  /// Human-readable file size formatting.
  String get formattedSize {
    if (fileSizeBytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var bytes = fileSizeBytes.toDouble();
    var i = 0;
    while (bytes >= 1024 && i < suffixes.length - 1) {
      bytes /= 1024;
      i++;
    }
    return '${bytes.toStringAsFixed(i == 0 ? 0 : 1)} ${suffixes[i]}';
  }

  /// Extracts the file name from the path.
  String get fileName {
    if (filePath.isEmpty) return title;
    final separator = filePath.contains('\\') ? '\\' : '/';
    return filePath.split(separator).last;
  }

  /// Extracts the upper-cased file extension (e.g. MP4, FLAC, MP3, MKV).
  String get fileExtension {
    final name = fileName;
    final dot = name.lastIndexOf('.');
    if (dot != -1 && dot < name.length - 1) {
      return name.substring(dot + 1).toUpperCase();
    }
    return isAudioOnly ? 'AUDIO' : 'VIDEO';
  }

  /// Formatted date string for hardware telemetry display.
  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(completedAt);

    final hour = completedAt.hour.toString().padLeft(2, '0');
    final min = completedAt.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$min';

    if (diff.inDays == 0 && completedAt.day == now.day) {
      return 'Today $timeStr';
    } else if (diff.inDays <= 1 && completedAt.day == now.day - 1) {
      return 'Yesterday $timeStr';
    }

    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = monthNames[completedAt.month - 1];
    return '$month ${completedAt.day}, $timeStr';
  }

  /// Serializes the archive item to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'filePath': filePath,
      'formatLabel': formatLabel,
      'fileSizeBytes': fileSizeBytes,
      'completedAt': completedAt.toIso8601String(),
      'isAudioOnly': isAudioOnly,
      if (playlistTitle != null) 'playlistTitle': playlistTitle,
      if (qualityId != null) 'qualityId': qualityId,
    };
  }

  /// Deserializes an archive item from JSON with live disk existence check.
  factory DownloadArchiveItem.fromJson(Map<String, dynamic> json) {
    final path = json['filePath'] as String? ?? '';
    final file = io.File(path);
    final exists = path.isNotEmpty && file.existsSync();
    final size = exists ? file.lengthSync() : (json['fileSizeBytes'] as int? ?? 0);

    return DownloadArchiveItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      url: json['url'] as String? ?? '',
      filePath: path,
      formatLabel: json['formatLabel'] as String? ?? 'MP4',
      fileSizeBytes: size,
      completedAt: DateTime.tryParse(json['completedAt'] as String? ?? '') ?? DateTime.now(),
      isAudioOnly: json['isAudioOnly'] as bool? ?? false,
      playlistTitle: json['playlistTitle'] as String?,
      qualityId: json['qualityId'] as String?,
      fileExists: exists,
    );
  }

  DownloadArchiveItem copyWith({
    String? id,
    String? title,
    String? url,
    String? filePath,
    String? formatLabel,
    int? fileSizeBytes,
    DateTime? completedAt,
    bool? isAudioOnly,
    String? playlistTitle,
    String? qualityId,
    bool? fileExists,
  }) {
    return DownloadArchiveItem(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      filePath: filePath ?? this.filePath,
      formatLabel: formatLabel ?? this.formatLabel,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      completedAt: completedAt ?? this.completedAt,
      isAudioOnly: isAudioOnly ?? this.isAudioOnly,
      playlistTitle: playlistTitle ?? this.playlistTitle,
      qualityId: qualityId ?? this.qualityId,
      fileExists: fileExists ?? this.fileExists,
    );
  }
}
