import 'package:flutter/foundation.dart';
import '../core/errors/app_exceptions.dart';
import '../models/playlist_info.dart';
import '../models/video_info.dart';
import '../services/ytdlp_service.dart';

/// Controller managing the state for video and playlist analysis and metadata inspection.
class VideoController extends ChangeNotifier {
  final YtDlpService _ytDlpService;

  bool _isLoading = false;
  String? _errorMessage;
  VideoInfo? _currentVideo;
  PlaylistInfo? _currentPlaylist;
  String? _analyzedUrl;

  VideoController({YtDlpService? ytDlpService})
      : _ytDlpService = ytDlpService ?? YtDlpService();

  /// Whether metadata is currently being fetched from the engine.
  bool get isLoading => _isLoading;

  /// User-facing error message, if the last operation failed.
  String? get errorMessage => _errorMessage;

  /// Parsed metadata for the analyzed video.
  VideoInfo? get currentVideo => _currentVideo;

  /// Parsed playlist metadata, if a playlist was analyzed.
  PlaylistInfo? get currentPlaylist => _currentPlaylist;

  /// Whether the analyzed target is a playlist.
  bool get isPlaylist => _currentPlaylist != null;

  /// The raw URL that was last analyzed.
  String? get analyzedUrl => _analyzedUrl;

  /// Whether a valid video or playlist is loaded.
  bool get hasTarget => _currentVideo != null || _currentPlaylist != null;
  bool get hasVideo => _currentVideo != null;

  /// Analyzes a URL by detecting playlists or videos and fetching metadata.
  Future<void> analyzeUrl(String url) async {
    _isLoading = true;
    _errorMessage = null;
    _currentVideo = null;
    _currentPlaylist = null;
    notifyListeners();

    try {
      if (_ytDlpService.isPlaylistUrl(url)) {
        try {
          final playlist = await _ytDlpService.fetchPlaylistInfo(url);
          if (playlist.totalCount > 0) {
            _currentPlaylist = playlist;
            _currentVideo = null;
            _analyzedUrl = url;
            _errorMessage = null;
            return;
          }
        } catch (_) {
          // If playlist extraction fails (e.g. video URL with invalid list param),
          // fall back seamlessly to single video extraction.
        }
      }

      final info = await _ytDlpService.fetchVideoInfo(url);
      _currentVideo = info;
      _currentPlaylist = null;
      _analyzedUrl = url;
      _errorMessage = null;
    } on AppException catch (e) {
      _errorMessage = e.userMessage;
      _currentVideo = null;
      _currentPlaylist = null;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
      _currentVideo = null;
      _currentPlaylist = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggles selection state of a playlist item by index.
  void togglePlaylistItem(int index, {bool? selected}) {
    final playlist = _currentPlaylist;
    if (playlist != null && index >= 0 && index < playlist.items.length) {
      final item = playlist.items[index];
      item.isSelected = selected ?? !item.isSelected;
      notifyListeners();
    }
  }

  /// Selects or deselects all playlist items.
  void selectAllPlaylistItems(bool selectAll) {
    final playlist = _currentPlaylist;
    if (playlist != null) {
      for (final item in playlist.items) {
        item.isSelected = selectAll;
      }
      notifyListeners();
    }
  }

  /// Clears the loaded video, playlist, and error state.
  void clear() {
    _isLoading = false;
    _errorMessage = null;
    _currentVideo = null;
    _currentPlaylist = null;
    _analyzedUrl = null;
    notifyListeners();
  }

  /// Clears the error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
