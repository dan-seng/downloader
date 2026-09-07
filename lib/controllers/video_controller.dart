import 'package:flutter/foundation.dart';
import '../core/errors/app_exceptions.dart';
import '../models/video_info.dart';
import '../services/ytdlp_service.dart';

/// Controller managing the state for video analysis and metadata inspection.
class VideoController extends ChangeNotifier {
  final YtDlpService _ytDlpService;

  bool _isLoading = false;
  String? _errorMessage;
  VideoInfo? _currentVideo;
  String? _analyzedUrl;

  VideoController({YtDlpService? ytDlpService})
      : _ytDlpService = ytDlpService ?? YtDlpService();

  /// Whether metadata is currently being fetched from yt-dlp.
  bool get isLoading => _isLoading;

  /// User-facing error message, if the last operation failed.
  String? get errorMessage => _errorMessage;

  /// Parsed metadata for the analyzed video.
  VideoInfo? get currentVideo => _currentVideo;

  /// The raw URL that was last analyzed.
  String? get analyzedUrl => _analyzedUrl;

  /// Whether a valid video is loaded.
  bool get hasVideo => _currentVideo != null;

  /// Analyzes a video URL by fetching its metadata through yt-dlp.
  Future<void> analyzeUrl(String url) async {
    _isLoading = true;
    _errorMessage = null;
    _currentVideo = null;
    notifyListeners();

    try {
      final info = await _ytDlpService.fetchVideoInfo(url);
      _currentVideo = info;
      _analyzedUrl = url;
      _errorMessage = null;
    } on AppException catch (e) {
      _errorMessage = e.userMessage;
      _currentVideo = null;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
      _currentVideo = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clears the loaded video and error state.
  void clear() {
    _isLoading = false;
    _errorMessage = null;
    _currentVideo = null;
    _analyzedUrl = null;
    notifyListeners();
  }

  /// Clears the error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
