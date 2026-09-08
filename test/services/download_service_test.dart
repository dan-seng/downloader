import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter_test/flutter_test.dart';
import 'package:video_downloader/models/download_task.dart';
import 'package:video_downloader/models/quality_option.dart';
import 'package:video_downloader/models/video_info.dart';
import 'package:video_downloader/services/download_service.dart';
import 'package:video_downloader/services/process_service.dart';

class FakeStreamProcess implements io.Process {
  final StreamController<List<int>> _stdoutController =
      StreamController<List<int>>.broadcast();
  final StreamController<List<int>> _stderrController =
      StreamController<List<int>>.broadcast();
  final Completer<int> _exitCodeCompleter = Completer<int>();

  void emitStdout(String text) {
    if (!_stdoutController.isClosed) {
      _stdoutController.add(utf8.encode(text));
    }
  }

  void completeProcess(int code) {
    if (!_stdoutController.isClosed) _stdoutController.close();
    if (!_stderrController.isClosed) _stderrController.close();
    if (!_exitCodeCompleter.isCompleted) {
      _exitCodeCompleter.complete(code);
    }
  }

  @override
  Stream<List<int>> get stdout => _stdoutController.stream;

  @override
  Stream<List<int>> get stderr => _stderrController.stream;

  @override
  Future<int> get exitCode => _exitCodeCompleter.future;

  @override
  bool kill([io.ProcessSignal signal = io.ProcessSignal.sigterm]) {
    completeProcess(143);
    return true;
  }

  @override
  int get pid => 12345;

  @override
  io.IOSink get stdin => throw UnimplementedError();
}

class FakeStartProcessService implements ProcessService {
  late FakeStreamProcess process;

  @override
  Future<io.ProcessResult> run(String executable, List<String> arguments,
      {String? workingDirectory, Map<String, String>? environment}) {
    throw UnimplementedError();
  }

  @override
  Future<io.Process> start(String executable, List<String> arguments,
      {String? workingDirectory,
      Map<String, String>? environment,
      io.ProcessStartMode mode = io.ProcessStartMode.normal}) async {
    return process;
  }
}

void main() {
  group('DownloadService', () {
    late FakeStartProcessService fakeService;
    late DownloadService downloadService;

    setUp(() {
      fakeService = FakeStartProcessService();
      downloadService = DownloadService(processService: fakeService);
    });

    test('parses progress updates, destination path, and completes', () async {
      final fakeProcess = FakeStreamProcess();
      fakeService.process = fakeProcess;

      const video = VideoInfo(
        id: 'test-vid',
        title: 'Video Title',
        formats: [],
      );

      const quality = QualityOption(
        id: '1080p',
        label: '1080p',
        extension: 'mp4',
        formatSpecifier: 'bv+ba',
      );

      DownloadTask? lastTask;

      final downloadFuture = downloadService.startDownload(
        video: video,
        quality: quality,
        destinationDirectory: '/tmp',
        onProgress: (task) {
          lastTask = task;
        },
      );

      // Allow startDownload to await process launch
      await Future.delayed(const Duration(milliseconds: 10));

      // Simulate output lines
      fakeProcess.emitStdout('[download] Destination: /tmp/Video Title.mp4\n');
      fakeProcess.emitStdout('download: 25.5%|  4.20MiB/s|00:30\n');
      fakeProcess.emitStdout('download: 75.0%|  5.10MiB/s|00:10\n');

      await Future.delayed(const Duration(milliseconds: 20));

      expect(lastTask?.destinationPath, equals('/tmp/Video Title.mp4'));
      expect(lastTask?.progress, closeTo(0.75, 0.01));
      expect(lastTask?.speed, isNotNull);
      expect(lastTask?.eta, equals(const Duration(seconds: 10)));

      // Complete process
      fakeProcess.completeProcess(0);
      await downloadFuture;

      expect(lastTask?.status, equals(DownloadStatus.completed));
      expect(lastTask?.progress, equals(1.0));
    });

    test('cancellation terminates process and marks task cancelled', () async {
      final fakeProcess = FakeStreamProcess();
      fakeService.process = fakeProcess;

      const video = VideoInfo(
        id: 'test-vid',
        title: 'Video Title',
        formats: [],
      );

      const quality = QualityOption(
        id: '1080p',
        label: '1080p',
        extension: 'mp4',
        formatSpecifier: 'bv+ba',
      );

      DownloadTask? lastTask;

      final downloadFuture = downloadService.startDownload(
        video: video,
        quality: quality,
        destinationDirectory: '/tmp',
        onProgress: (task) {
          lastTask = task;
        },
      );

      await Future.delayed(const Duration(milliseconds: 10));
      await downloadService.cancelCurrentDownload();
      await downloadFuture;

      expect(lastTask?.status, equals(DownloadStatus.cancelled));
    });
  });
}
