import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

/// Signature for spawning a process, allowing dependency injection in unit tests.
typedef ProcessStarter = Future<io.Process> Function(
  String executable,
  List<String> arguments,
);

/// Signature for running a one-off command.
typedef ProcessRunner = Future<io.ProcessResult> Function(
  String executable,
  List<String> arguments,
);

/// Service managing OS-level desktop system notifications and sound cues.
class NotificationService {
  final ProcessStarter _processStarter;
  final ProcessRunner _processRunner;
  bool notificationsEnabled;
  bool soundEnabled;

  NotificationService({
    ProcessStarter? processStarter,
    ProcessRunner? processRunner,
    this.notificationsEnabled = true,
    this.soundEnabled = true,
  })  : _processStarter = processStarter ?? io.Process.start,
        _processRunner = processRunner ?? io.Process.run;

  /// Checks if desktop notification delivery is supported on the current platform.
  bool get isSupported => io.Platform.isLinux || io.Platform.isMacOS || io.Platform.isWindows;

  /// Plays the freedesktop completion sound cue.
  Future<void> playNotificationSound() async {
    if (!soundEnabled) return;
    try {
      if (io.Platform.isLinux) {
        await _processRunner('canberra-gtk-play', ['-i', 'complete']);
      }
    } catch (_) {
      // Sound playback failure is non-fatal
    }
  }

  /// Sends a desktop notification when an individual video or audio download finishes.
  Future<void> sendDownloadCompleteNotification({
    required String title,
    required String filePath,
    void Function()? onOpenFile,
    void Function()? onOpenFolder,
  }) async {
    if (!notificationsEnabled || !isSupported) return;

    // Fire sound effect
    unawaited(playNotificationSound());

    if (io.Platform.isLinux) {
      try {
        final args = [
          '-a',
          'VINX',
          '-i',
          'video-x-generic',
          '-u',
          'normal',
          '-h',
          'string:sound-name:complete',
          '-A',
          'open=Open File',
          '-A',
          'folder=Open Folder',
          'Download Complete',
          '"$title" is ready.',
        ];

        final process = await _processStarter('notify-send', args);
        process.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen((action) {
          final trimmed = action.trim();
          if (trimmed == 'open' || trimmed == '0') {
            onOpenFile?.call();
          } else if (trimmed == 'folder' || trimmed == '1') {
            onOpenFolder?.call();
          }
        });
      } catch (_) {
        // Fallback or ignore if notify-send is unavailable
      }
    }
  }

  /// Sends a desktop notification when a playlist batch finishes.
  Future<void> sendBatchCompleteNotification({
    required int count,
    required String destinationPath,
    void Function()? onOpenFolder,
  }) async {
    if (!notificationsEnabled || !isSupported) return;

    // Fire sound effect
    unawaited(playNotificationSound());

    if (io.Platform.isLinux) {
      try {
        final args = [
          '-a',
          'VINX',
          '-i',
          'folder-download',
          '-u',
          'normal',
          '-h',
          'string:sound-name:complete',
          '-A',
          'folder=Open Folder',
          'Batch Download Complete',
          'Finished downloading $count tracks to $destinationPath',
        ];

        final process = await _processStarter('notify-send', args);
        process.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen((action) {
          final trimmed = action.trim();
          if (trimmed == 'folder' || trimmed == '0') {
            onOpenFolder?.call();
          }
        });
      } catch (_) {
        // Fallback
      }
    }
  }
}
