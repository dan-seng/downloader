import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt_exp;

/// Custom HTTP client for mobile YouTube stream requests.
/// Injects the YouTube Android application User-Agent header for googlevideo.com
/// stream requests, ensuring CDN requests avoid HTTP 403 Forbidden and infinite retry hangs.
class MobileYoutubeHttpClient extends http.BaseClient {
  final http.Client _inner;

  MobileYoutubeHttpClient([http.Client? inner]) : _inner = inner ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (request.url.host.contains('googlevideo.com') ||
        request.url.queryParameters['c'] == 'ANDROID') {
      request.headers['User-Agent'] =
          'com.google.android.youtube/19.29.37 (Linux; U; Android 11) gzip';
    }
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}

/// Creates a [yt_exp.YoutubeExplode] instance configured with mobile stream headers.
yt_exp.YoutubeExplode createMobileYoutubeExplode([http.Client? innerClient]) {
  return yt_exp.YoutubeExplode(
    httpClient: yt_exp.YoutubeHttpClient(MobileYoutubeHttpClient(innerClient)),
  );
}
