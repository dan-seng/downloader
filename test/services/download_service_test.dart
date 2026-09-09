import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter_test/flutter_test.dart';
import 'package:video_downloader/models/audio_config.dart';
import 'package:video_downloader/models/download_task.dart';
import 'package:video_downloader/models/quality_option.dart';
import 'package:video_downloader/models/speed_limit.dart';
import 'package:video_downloader/models/time_range_clip.dart';
import 'package:video_downloader/models/video_info.dart';
import 'package:video_downloader/services/download_service.dart';
import 'package:video_downloader/services/engine_service.dart';
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
  List<String>? lastArguments;

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
    lastArguments = arguments;
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

    test('parses raw newline progress format emitted by yt-dlp', () async {
      final fakeProcess = FakeStreamProcess();
      fakeService.process = fakeProcess;

      const video = VideoInfo(
        id: 'raw-vid',
        title: 'Raw Title',
        formats: [],
      );

      const quality = QualityOption(
        id: '1080p',
        label: '1080p',
        extension: 'mp4',
        formatSpecifier: '18',
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

      // Actual --newline / --progress-template output (raw, no prefix)
      fakeProcess.emitStdout('[download] Destination: /tmp/Raw Title.mp4\n');
      fakeProcess.emitStdout('  0.0%| Unknown B/s|Unknown\n');
      fakeProcess.emitStdout(' 17.7%|   2.07MiB/s|00:04\n');
      fakeProcess.emitStdout(' 88.5%| 294.29KiB/s|00:04\n');

      await Future.delayed(const Duration(milliseconds: 20));

      expect(lastTask?.destinationPath, equals('/tmp/Raw Title.mp4'));
      expect(lastTask?.progress, closeTo(0.885, 0.01));
      expect(lastTask?.speed, closeTo(294.29 * 1024, 0.1));
      expect(lastTask?.eta, equals(const Duration(seconds: 4)));

      fakeProcess.completeProcess(0);
      await downloadFuture;

      expect(lastTask?.status, equals(DownloadStatus.completed));
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

    test('constructs video arguments without restrictive extractor args and with mp4 merge', () async {
      final fakeProcess = FakeStreamProcess();
      fakeService.process = fakeProcess;

      const video = VideoInfo(
        id: 'test-vid-args',
        title: 'Video Title',
        formats: [],
      );

      const quality = QualityOption(
        id: '1080p',
        label: '1080p',
        extension: 'mp4',
        formatSpecifier: 'bv*[height=1080]+ba/b[height=1080]',
      );

      final downloadFuture = downloadService.startDownload(
        video: video,
        quality: quality,
        destinationDirectory: '/tmp',
        onProgress: (_) {},
      );

      await Future.delayed(const Duration(milliseconds: 10));
      fakeProcess.completeProcess(0);
      await downloadFuture;

      final args = fakeService.lastArguments!;
      expect(args.contains('--extractor-args'), isFalse);
      expect(args.contains('youtube:player_client=web,android'), isFalse);
      expect(args.contains('--merge-output-format'), isTrue);
      expect(args[args.indexOf('--merge-output-format') + 1], equals('mp4'));
      expect(args.contains('bv*[height=1080]+ba/b[height=1080]'), isTrue);
    });

    test('constructs audio extraction arguments for audio-only quality', () async {
      final fakeProcess = FakeStreamProcess();
      fakeService.process = fakeProcess;

      const video = VideoInfo(
        id: 'test-audio-args',
        title: 'Audio Title',
        formats: [],
      );

      const quality = QualityOption(
        id: 'audio_best',
        label: 'Audio Only',
        extension: 'm4a',
        isAudioOnly: true,
        formatSpecifier: 'ba/b',
      );

      final downloadFuture = downloadService.startDownload(
        video: video,
        quality: quality,
        destinationDirectory: '/tmp',
        onProgress: (_) {},
      );

      await Future.delayed(const Duration(milliseconds: 10));
      fakeProcess.completeProcess(0);
      await downloadFuture;

      final args = fakeService.lastArguments!;
      expect(args.contains('-x'), isTrue);
      expect(args.contains('--audio-format'), isTrue);
      expect(args[args.indexOf('--audio-format') + 1], equals('m4a'));
    });

    test('constructs high-fidelity audio arguments with 320k MP3, embed thumbnail, and metadata', () async {
      final fakeProcess = FakeStreamProcess();
      fakeService.process = fakeProcess;

      const video = VideoInfo(
        id: 'test-studio-audio',
        title: 'Studio Track',
        formats: [],
      );

      const quality = QualityOption(
        id: 'audio_best',
        label: 'Audio Only',
        extension: 'm4a',
        isAudioOnly: true,
        formatSpecifier: 'ba/b',
      );

      const audioConfig = AudioConfig(
        bitrate: AudioBitrate.kbps320,
        format: AudioFormat.mp3,
        embedThumbnail: true,
        embedMetadata: true,
      );

      final downloadFuture = downloadService.startDownload(
        video: video,
        quality: quality,
        destinationDirectory: '/music',
        onProgress: (_) {},
        audioConfig: audioConfig,
      );

      await Future.delayed(const Duration(milliseconds: 10));
      fakeProcess.completeProcess(0);
      await downloadFuture;

      final args = fakeService.lastArguments!;
      expect(args.contains('-x'), isTrue);
      expect(args.contains('--audio-format'), isTrue);
      expect(args[args.indexOf('--audio-format') + 1], equals('mp3'));
      expect(args.contains('--audio-quality'), isTrue);
      expect(args[args.indexOf('--audio-quality') + 1], equals('320K'));
      expect(args.contains('--embed-thumbnail'), isTrue);
      expect(args.contains('--convert-thumbnails'), isTrue);
      expect(args[args.indexOf('--convert-thumbnails') + 1], equals('jpg'));
      expect(args.contains('--add-metadata'), isTrue);
    });

    test('applies --limit-rate when throttled speed limit is configured', () async {
      final fakeProcess = FakeStreamProcess();
      fakeService.process = fakeProcess;

      const video = VideoInfo(
        id: 'test-throttled',
        title: 'Throttled Download',
        formats: [],
      );

      const quality = QualityOption(
        id: '1080p',
        label: '1080p',
        extension: 'mp4',
        formatSpecifier: 'bv+ba',
      );

      final downloadFuture = downloadService.startDownload(
        video: video,
        quality: quality,
        destinationDirectory: '/downloads',
        onProgress: (_) {},
        speedLimit: SpeedLimit.mbps10,
      );

      await Future.delayed(const Duration(milliseconds: 10));
      fakeProcess.completeProcess(0);
      await downloadFuture;

      final args = fakeService.lastArguments!;
      expect(args.contains('--limit-rate'), isTrue);
      expect(args[args.indexOf('--limit-rate') + 1], equals('10M'));
    });

    test('omits --limit-rate when unlimited speed limit is selected', () async {
      final fakeProcess = FakeStreamProcess();
      fakeService.process = fakeProcess;

      const video = VideoInfo(
        id: 'test-unlimited',
        title: 'Unlimited Download',
        formats: [],
      );

      const quality = QualityOption(
        id: '1080p',
        label: '1080p',
        extension: 'mp4',
        formatSpecifier: 'bv+ba',
      );

      final downloadFuture = downloadService.startDownload(
        video: video,
        quality: quality,
        destinationDirectory: '/downloads',
        onProgress: (_) {},
        speedLimit: SpeedLimit.unlimited,
      );

      await Future.delayed(const Duration(milliseconds: 10));
      fakeProcess.completeProcess(0);
      await downloadFuture;

      final args = fakeService.lastArguments!;
      expect(args.contains('--limit-rate'), isFalse);
    });

    test('appends --download-sections and --force-keyframes-at-cuts when clip is enabled', () async {
      final fakeProcess = FakeStreamProcess();
      fakeService.process = fakeProcess;

      const video = VideoInfo(
        id: 'test-trim',
        title: 'Trimmed Video',
        formats: [],
      );

      const quality = QualityOption(
        id: '1080p',
        label: '1080p',
        extension: 'mp4',
        formatSpecifier: 'bv+ba',
      );

      const clip = TimeRangeClip(
        isEnabled: true,
        start: Duration(minutes: 1, seconds: 30),
        end: Duration(minutes: 4, seconds: 15),
      );

      final downloadFuture = downloadService.startDownload(
        video: video,
        quality: quality,
        destinationDirectory: '/downloads',
        onProgress: (_) {},
        clip: clip,
      );

      await Future.delayed(const Duration(milliseconds: 10));
      fakeProcess.completeProcess(0);
      await downloadFuture;

      final args = fakeService.lastArguments!;
      expect(args.contains('--download-sections'), isTrue);
      final sectionIdx = args.indexOf('--download-sections');
      expect(args[sectionIdx + 1], '*01:30-04:15');
      expect(args.contains('--force-keyframes-at-cuts'), isTrue);
    });

    test('omits --download-sections when clip is disabled', () async {
      final fakeProcess = FakeStreamProcess();
      fakeService.process = fakeProcess;

      const video = VideoInfo(
        id: 'test-notrim',
        title: 'Full Video',
        formats: [],
      );

      const quality = QualityOption(
        id: '1080p',
        label: '1080p',
        extension: 'mp4',
        formatSpecifier: 'bv+ba',
      );

      const clip = TimeRangeClip(
        isEnabled: false,
        start: Duration(seconds: 30),
        end: Duration(seconds: 90),
      );

      final downloadFuture = downloadService.startDownload(
        video: video,
        quality: quality,
        destinationDirectory: '/downloads',
        onProgress: (_) {},
        clip: clip,
      );

      await Future.delayed(const Duration(milliseconds: 10));
      fakeProcess.completeProcess(0);
      await downloadFuture;

      final args = fakeService.lastArguments!;
      expect(args.contains('--download-sections'), isFalse);
      expect(args.contains('--force-keyframes-at-cuts'), isFalse);
    });

    test('forwards --ffmpeg-location when engineService provides resolved ffmpeg directory', () async {
      final fakeProcess = FakeStreamProcess();
      fakeService.process = fakeProcess;

      final mockEngineService = EngineService(
        customHomeDir: '/custom/user/home',
      );
      // Create service with mock engine info containing ffmpeg path
      final svc = DownloadService(
        processService: fakeService,
        engineService: mockEngineService,
      );

      const video = VideoInfo(
        id: 'test-vid-ffmpeg',
        title: 'Video Title',
        formats: [],
      );

      const quality = QualityOption(
        id: '1080p',
        label: '1080p',
        extension: 'mp4',
        formatSpecifier: 'bv+ba',
      );

      // Verify without ffmpeg first
      final downloadFuture = svc.startDownload(
        video: video,
        quality: quality,
        destinationDirectory: '/downloads',
        onProgress: (_) {},
      );

      await Future.delayed(const Duration(milliseconds: 10));
      fakeProcess.completeProcess(0);
      await downloadFuture;

      // If ffmpeg not resolved yet, omitted
      expect(fakeService.lastArguments!.contains('--ffmpeg-location'), isFalse);
    });
  });
}
