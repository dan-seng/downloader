import '../core/utils/formatters.dart';

/// Represents an individual media item within a playlist or batch queue.
class PlaylistItem {
  final String id;
  final String url;
  final String title;
  final Duration? duration;
  final String? uploader;
  final String? thumbnail;
  bool isSelected;

  PlaylistItem({
    required this.id,
    required this.url,
    required this.title,
    this.duration,
    this.uploader,
    this.thumbnail,
    this.isSelected = true,
  });

  /// Factory constructor to parse a single entry from yt-dlp's `--flat-playlist` JSON.
  factory PlaylistItem.fromJson(Map<String, dynamic> json, {int index = 0}) {
    final id = json['id']?.toString() ?? 'item_$index';
    final rawUrl = json['url']?.toString() ?? json['webpage_url']?.toString();
    final url = (rawUrl != null && rawUrl.isNotEmpty) ? rawUrl : id;

    Duration? duration;
    final rawDuration = json['duration'];
    if (rawDuration is num && rawDuration > 0) {
      duration = Duration(seconds: rawDuration.toInt());
    }

    String? thumbnail = json['thumbnail'] as String?;
    if (thumbnail == null || thumbnail.isEmpty) {
      final thumbnailsList = json['thumbnails'];
      if (thumbnailsList is List && thumbnailsList.isNotEmpty) {
        final last = thumbnailsList.last;
        if (last is Map && last['url'] is String) {
          thumbnail = last['url'] as String;
        }
      }
    }

    return PlaylistItem(
      id: id,
      url: url,
      title: json['title']?.toString() ?? 'Track ${index + 1}',
      duration: duration,
      uploader: json['uploader'] as String? ?? json['channel'] as String?,
      thumbnail: thumbnail,
      isSelected: true,
    );
  }

  /// Formatted duration (e.g. "03:45").
  String get formattedDuration => Formatters.formatDuration(duration);
}

/// Strongly typed model representing parsed playlist metadata and track items.
class PlaylistInfo {
  final String id;
  final String title;
  final String? uploader;
  final String? webpageUrl;
  final List<PlaylistItem> items;

  const PlaylistInfo({
    required this.id,
    required this.title,
    this.uploader,
    this.webpageUrl,
    required this.items,
  });

  /// Factory constructor to parse yt-dlp `--flat-playlist` output JSON.
  factory PlaylistInfo.fromJson(Map<String, dynamic> json) {
    final rawEntries = json['entries'];
    final items = <PlaylistItem>[];

    if (rawEntries is List) {
      for (var i = 0; i < rawEntries.length; i++) {
        final entry = rawEntries[i];
        if (entry is Map<String, dynamic>) {
          items.add(PlaylistItem.fromJson(entry, index: i));
        } else if (entry is Map) {
          items.add(PlaylistItem.fromJson(Map<String, dynamic>.from(entry), index: i));
        }
      }
    }

    return PlaylistInfo(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Playlist',
      uploader: json['uploader'] as String? ?? json['channel'] as String?,
      webpageUrl: json['webpage_url'] as String? ?? json['original_url'] as String?,
      items: items,
    );
  }

  /// Total count of items in the playlist.
  int get totalCount => items.length;

  /// Count of currently selected items for download.
  int get selectedCount => items.where((item) => item.isSelected).length;

  /// Whether at least one item is selected.
  bool get hasSelection => selectedCount > 0;

  /// Whether all items are currently selected.
  bool get isAllSelected => totalCount > 0 && selectedCount == totalCount;
}
