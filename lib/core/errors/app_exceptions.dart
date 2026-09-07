/// Base class for all application exceptions with user-facing messages
/// and optional technical diagnostic details.
abstract class AppException implements Exception {
  final String userMessage;
  final String? technicalDetails;

  const AppException(this.userMessage, {this.technicalDetails});

  @override
  String toString() {
    if (technicalDetails != null && technicalDetails!.isNotEmpty) {
      return '$userMessage ($technicalDetails)';
    }
    return userMessage;
  }
}

/// Thrown when the provided URL fails validation.
class InvalidUrlException extends AppException {
  const InvalidUrlException(
    super.userMessage, {
    super.technicalDetails,
  });
}

/// Thrown when yt-dlp encounters an error processing a URL or downloading.
class YtDlpException extends AppException {
  final int? exitCode;

  const YtDlpException(
    super.userMessage, {
    this.exitCode,
    super.technicalDetails,
  });
}

/// Thrown when launching an OS process fails (e.g. binary not found or permission denied).
class ProcessExecutionException extends AppException {
  const ProcessExecutionException(
    super.userMessage, {
    super.technicalDetails,
  });
}
