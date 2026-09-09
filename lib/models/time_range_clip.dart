/// Model representing a time-trimmed clip selection for yt-dlp `--download-sections`.
class TimeRangeClip {
  final bool isEnabled;
  final Duration start;
  final Duration? end;

  const TimeRangeClip({
    this.isEnabled = false,
    this.start = Duration.zero,
    this.end,
  });

  TimeRangeClip copyWith({
    bool? isEnabled,
    Duration? start,
    Duration? end,
  }) {
    return TimeRangeClip(
      isEnabled: isEnabled ?? this.isEnabled,
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }

  /// Formats section for yt-dlp `--download-sections "*START-END"`.
  /// E.g. `*00:01:30-00:03:45` or `*00:00:00-inf`.
  String toSectionArgument() {
    final startStr = formatTimestamp(start);
    final endStr = end != null ? formatTimestamp(end!) : 'inf';
    return '*$startStr-$endStr';
  }

  /// Human-readable summary, e.g. "01:15 ➔ 03:45 (02:30 clip)".
  String formatSummary() {
    final startStr = formatTimestamp(start);
    final endStr = end != null ? formatTimestamp(end!) : 'End';
    if (end != null && end! > start) {
      final clipLen = end! - start;
      return '$startStr ➔ $endStr (${formatTimestamp(clipLen)})';
    }
    return '$startStr ➔ $endStr';
  }

  /// Formats a Duration as `hh:mm:ss` (or `mm:ss` if under 1 hour).
  static String formatTimestamp(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Parses user-entered timecodes such as "01:30", "1:30", "01:15:30", or raw seconds "90".
  static Duration? parseTimeString(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    final parts = trimmed.split(':').map((p) => int.tryParse(p.trim())).toList();
    if (parts.any((p) => p == null || p < 0)) return null;

    if (parts.length == 1) {
      return Duration(seconds: parts[0]!);
    } else if (parts.length == 2) {
      return Duration(minutes: parts[0]!, seconds: parts[1]!);
    } else if (parts.length == 3) {
      return Duration(hours: parts[0]!, minutes: parts[1]!, seconds: parts[2]!);
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeRangeClip &&
          runtimeType == other.runtimeType &&
          isEnabled == other.isEnabled &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => Object.hash(isEnabled, start, end);
}
