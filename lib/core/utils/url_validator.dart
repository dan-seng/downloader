import '../errors/app_exceptions.dart';

/// Utilities for validating and sanitizing video URLs before process execution.
class UrlValidator {
  const UrlValidator._();

  /// Validates a URL input string.
  ///
  /// Throws [InvalidUrlException] if the URL is empty, contains flags,
  /// or lacks a valid http/https scheme and host.
  /// Returns the trimmed, normalized URL string on success.
  static String validate(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) {
      throw const InvalidUrlException(
        'Please enter a video URL.',
        technicalDetails: 'URL string is null or empty',
      );
    }

    final trimmed = rawUrl.trim();

    // Prevent passing command options or flags disguised as URLs
    if (trimmed.startsWith('-')) {
      throw const InvalidUrlException(
        'Invalid URL format.',
        technicalDetails: 'URL cannot start with a dash or flag',
      );
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      throw const InvalidUrlException(
        'Invalid URL. Please enter a complete web address (e.g., https://...).',
        technicalDetails: 'Failed to parse scheme or authority from input',
      );
    }

    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') {
      throw InvalidUrlException(
        'Unsupported URL scheme. Please use http:// or https://.',
        technicalDetails: 'Scheme "$scheme" is not supported',
      );
    }

    if (uri.host.isEmpty || !uri.host.contains('.')) {
      throw const InvalidUrlException(
        'Invalid URL. Please enter a valid website address.',
        technicalDetails: 'Host is missing or does not contain a domain',
      );
    }

    return trimmed;
  }

  /// Non-throwing check to test if a URL looks valid.
  static bool isValid(String? rawUrl) {
    try {
      validate(rawUrl);
      return true;
    } on InvalidUrlException {
      return false;
    }
  }
}
