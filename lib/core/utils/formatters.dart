/// Helper methods for formatting durations, byte sizes, and media properties.
class Formatters {
  const Formatters._();

  /// Formats a [Duration] into `HH:mm:ss` or `mm:ss`.
  ///
  /// Examples:
  /// - 65 seconds -> `01:05`
  /// - 3665 seconds -> `01:01:05`
  static String formatDuration(Duration? duration) {
    if (duration == null) return 'Unknown';

    final totalSeconds = duration.inSeconds;
    if (totalSeconds < 0) return '00:00';

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    final minStr = minutes.toString().padLeft(2, '0');
    final secStr = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      final hrStr = hours.toString().padLeft(2, '0');
      return '$hrStr:$minStr:$secStr';
    }
    return '$minStr:$secStr';
  }

  /// Formats byte count into a readable string (e.g., `12.5 MB`, `1.2 GB`).
  static String formatBytes(int? bytes) {
    if (bytes == null || bytes < 0) return 'Unknown size';
    if (bytes < 1024) return '$bytes B';

    const units = ['KB', 'MB', 'GB', 'TB'];
    double size = bytes.toDouble();
    int unitIndex = -1;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    if (unitIndex == -1) return '$bytes B';
    return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
  }

  /// Formats frames per second into a clean label (e.g. `60 fps`).
  static String? formatFps(double? fps) {
    if (fps == null || fps <= 0) return null;
    final rounded = fps.roundToDouble();
    if ((fps - rounded).abs() < 0.1) {
      return '${rounded.toInt()} fps';
    }
    return '${fps.toStringAsFixed(1)} fps';
  }
}
