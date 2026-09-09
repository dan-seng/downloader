import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter_test/flutter_test.dart';
import 'package:video_downloader/services/notification_service.dart';

class MockProcess implements io.Process {
  final StreamController<List<int>> _stdoutController = StreamController<List<int>>();
  final Completer<int> _exitCodeCompleter = Completer<int>();

  void emitStdout(String text) {
    _stdoutController.add(utf8.encode('$text\n'));
  }

  void closeStdout() {
    _stdoutController.close();
  }

  @override
  Stream<List<int>> get stdout => _stdoutController.stream;

  @override
  Stream<List<int>> get stderr => const Stream.empty();

  @override
  Future<int> get exitCode => _exitCodeCompleter.future;

  @override
  int get pid => 12345;

  @override
  io.IOSink get stdin => throw UnimplementedError();

  @override
  bool kill([io.ProcessSignal signal = io.ProcessSignal.sigterm]) => true;
}

void main() {
  group('NotificationService', () {
    test('sendDownloadCompleteNotification spawns notify-send with action flags', () async {
      String? capturedExecutable;
      List<String>? capturedArgs;
      final mockProcess = MockProcess();

      final service = NotificationService(
        processStarter: (executable, args) async {
          capturedExecutable = executable;
          capturedArgs = args;
          return mockProcess;
        },
        processRunner: (executable, args) async {
          return io.ProcessResult(0, 0, '', '');
        },
      );

      bool fileOpened = false;
      bool folderOpened = false;

      final future = service.sendDownloadCompleteNotification(
        title: 'Cyberpunk 2077 OST',
        filePath: '/home/user/Downloads/cyberpunk.mp4',
        onOpenFile: () => fileOpened = true,
        onOpenFolder: () => folderOpened = true,
      );

      await future;

      expect(capturedExecutable, 'notify-send');
      expect(capturedArgs, contains('-a'));
      expect(capturedArgs, contains('VINX'));
      expect(capturedArgs, contains('-A'));
      expect(capturedArgs, contains('open=Open File'));
      expect(capturedArgs, contains('folder=Open Folder'));
      expect(capturedArgs, contains('"Cyberpunk 2077 OST" is ready.'));

      // Simulate clicking "Open File"
      mockProcess.emitStdout('open');
      await Future.delayed(const Duration(milliseconds: 10));
      expect(fileOpened, isTrue);
      expect(folderOpened, isFalse);

      mockProcess.closeStdout();
    });

    test('sendBatchCompleteNotification spawns notify-send with folder action', () async {
      String? capturedExecutable;
      List<String>? capturedArgs;
      final mockProcess = MockProcess();

      final service = NotificationService(
        processStarter: (executable, args) async {
          capturedExecutable = executable;
          capturedArgs = args;
          return mockProcess;
        },
        processRunner: (executable, args) async {
          return io.ProcessResult(0, 0, '', '');
        },
      );

      bool folderOpened = false;

      await service.sendBatchCompleteNotification(
        count: 14,
        destinationPath: '/home/user/Downloads/Album',
        onOpenFolder: () => folderOpened = true,
      );

      expect(capturedExecutable, 'notify-send');
      expect(capturedArgs, contains('folder=Open Folder'));
      expect(capturedArgs, contains('Finished downloading 14 tracks to /home/user/Downloads/Album'));

      mockProcess.emitStdout('folder');
      await Future.delayed(const Duration(milliseconds: 10));
      expect(folderOpened, isTrue);

      mockProcess.closeStdout();
    });

    test('does not send notification when notificationsEnabled is false', () async {
      bool spawned = false;
      final service = NotificationService(
        notificationsEnabled: false,
        processStarter: (executable, args) async {
          spawned = true;
          return MockProcess();
        },
        processRunner: (executable, args) async {
          return io.ProcessResult(0, 0, '', '');
        },
      );

      await service.sendDownloadCompleteNotification(
        title: 'Ignored',
        filePath: '/path/to/file.mp4',
      );

      expect(spawned, isFalse);
    });

    test('plays complete sound via canberra-gtk-play', () async {
      String? playedCmd;
      List<String>? playedArgs;

      final service = NotificationService(
        processStarter: (executable, args) async => MockProcess(),
        processRunner: (executable, args) async {
          playedCmd = executable;
          playedArgs = args;
          return io.ProcessResult(0, 0, '', '');
        },
      );

      await service.playNotificationSound();

      expect(playedCmd, 'canberra-gtk-play');
      expect(playedArgs, ['-i', 'complete']);
    });
  });
}
