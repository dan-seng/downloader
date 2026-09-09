import 'dart:io' as io;
import 'package:flutter_test/flutter_test.dart';
import 'package:video_downloader/services/engine_service.dart';
import 'package:video_downloader/services/process_service.dart';

class _MockProcessService implements ProcessService {
  final Map<String, io.ProcessResult> responses;
  final List<List<String>> executedCommands = [];

  _MockProcessService(this.responses);

  @override
  Future<io.ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    final key = '$executable ${arguments.join(' ')}';
    executedCommands.add([executable, ...arguments]);

    if (responses.containsKey(key)) {
      return responses[key]!;
    }
    // Also check just executable
    if (responses.containsKey(executable)) {
      return responses[executable]!;
    }

    return io.ProcessResult(0, 1, '', 'Command not found in mock');
  }

  @override
  Future<io.Process> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    io.ProcessStartMode mode = io.ProcessStartMode.normal,
  }) {
    throw UnimplementedError();
  }
}

void main() {
  group('EngineService Tests', () {
    late io.Directory tempDir;

    setUp(() {
      tempDir = io.Directory.systemTemp.createTempSync('spidey_engine_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('detects yt-dlp in User Vault (~/.spidey_dlx/bin/yt-dlp) with highest priority', () async {
      final userBinDir = io.Directory('${tempDir.path}/.spidey_dlx/bin');
      userBinDir.createSync(recursive: true);

      final userExe = io.File('${userBinDir.path}/yt-dlp');
      userExe.writeAsStringSync('binary content');

      final mockProcess = _MockProcessService({
        '${userExe.path} --version': io.ProcessResult(1, 0, '2025.01.15\n', ''),
        'ffmpeg -version': io.ProcessResult(2, 0, 'ffmpeg version 6.1.1-3ubuntu2\n', ''),
      });

      final service = EngineService(
        processService: mockProcess,
        customHomeDir: tempDir.path,
        customBundleDir: '${tempDir.path}/bundle',
      );

      final info = await service.checkEngine();

      expect(info.isYtdlpReady, isTrue);
      expect(info.ytdlpSource, EngineBinarySource.userBin);
      expect(info.ytdlpVersion, '2025.01.15');
      expect(info.ytdlpPath, userExe.path);
      expect(info.ffmpegAvailable, isTrue);
      expect(info.ffmpegVersion, contains('ffmpeg version 6.1.1'));
    });

    test('falls back to App Bundle if user vault does not have binary', () async {
      final bundleDir = io.Directory('${tempDir.path}/bundle/data/bin');
      bundleDir.createSync(recursive: true);

      final bundleExe = io.File('${bundleDir.path}/yt-dlp');
      bundleExe.writeAsStringSync('bundled binary');

      final mockProcess = _MockProcessService({
        '${bundleExe.path} --version': io.ProcessResult(1, 0, '2024.12.01\n', ''),
        'ffmpeg -version': io.ProcessResult(2, 0, 'ffmpeg version 6.0\n', ''),
      });

      final service = EngineService(
        processService: mockProcess,
        customHomeDir: tempDir.path,
        customBundleDir: '${tempDir.path}/bundle',
      );

      final info = await service.checkEngine();

      expect(info.isYtdlpReady, isTrue);
      expect(info.ytdlpSource, EngineBinarySource.bundled);
      expect(info.ytdlpVersion, '2024.12.01');
      expect(info.ytdlpPath, bundleExe.path);
    });

    test('falls back to System PATH when user vault and bundle are missing', () async {
      final mockProcess = _MockProcessService({
        'yt-dlp --version': io.ProcessResult(1, 0, '2024.08.06\n', ''),
        'ffmpeg -version': io.ProcessResult(2, 0, 'ffmpeg version 5.1\n', ''),
      });

      final service = EngineService(
        processService: mockProcess,
        customHomeDir: tempDir.path,
        customBundleDir: '${tempDir.path}/empty_bundle',
      );

      final info = await service.checkEngine();

      expect(info.isYtdlpReady, isTrue);
      expect(info.ytdlpSource, EngineBinarySource.systemPath);
      expect(info.ytdlpVersion, '2024.08.06');
    });

    test('reports missing when neither user bin, bundle, nor PATH can run', () async {
      final mockProcess = _MockProcessService({});

      final service = EngineService(
        processService: mockProcess,
        customHomeDir: tempDir.path,
        customBundleDir: '${tempDir.path}/empty_bundle',
      );

      final info = await service.checkEngine();

      expect(info.isYtdlpReady, isFalse);
      expect(info.ytdlpSource, EngineBinarySource.missing);
      expect(info.ytdlpVersion, isNull);
      expect(info.ytdlpPath, isNull);
      expect(info.ffmpegAvailable, isFalse);
    });

    test('downloads and verifies yt-dlp into user bin with mock downloader', () async {
      final userBinDir = '${tempDir.path}/.spidey_dlx/bin';
      final targetPath = '$userBinDir/yt-dlp';

      final mockProcess = _MockProcessService({
        'chmod +x $targetPath': io.ProcessResult(1, 0, '', ''),
        '$targetPath --version': io.ProcessResult(2, 0, '2025.02.01\n', ''),
        'ffmpeg -version': io.ProcessResult(3, 0, 'ffmpeg version 6.1\n', ''),
      });

      final progressEvents = <double>[];

      final service = EngineService(
        processService: mockProcess,
        customHomeDir: tempDir.path,
        binaryDownloader: (uri, dest, {onProgress}) async {
          dest.parent.createSync(recursive: true);
          onProgress?.call(0.5, 'Downloading 50%...');
          dest.writeAsStringSync('#!/bin/sh\necho "yt-dlp"');
          onProgress?.call(1.0, 'Done');
        },
      );

      final info = await service.downloadOrUpdateYtDlp(
        onProgress: (p, _) => progressEvents.add(p),
      );

      expect(io.File(targetPath).existsSync(), isTrue);
      expect(info.isYtdlpReady, isTrue);
      expect(info.ytdlpSource, EngineBinarySource.userBin);
      expect(info.ytdlpVersion, '2025.02.01');
      expect(progressEvents, isNotEmpty);
    });

    test('detects FFmpeg in user vault and resolves getFfmpegDirectory()', () async {
      final userBinDir = io.Directory('${tempDir.path}/.spidey_dlx/bin');
      userBinDir.createSync(recursive: true);

      final userFfmpeg = io.File('${userBinDir.path}/ffmpeg');
      userFfmpeg.writeAsStringSync('binary content');

      final mockProcess = _MockProcessService({
        'yt-dlp --version': io.ProcessResult(1, 0, '2025.01.15\n', ''),
        '${userFfmpeg.path} -version': io.ProcessResult(2, 0, 'ffmpeg version 7.0-static\n', ''),
      });

      final service = EngineService(
        processService: mockProcess,
        customHomeDir: tempDir.path,
      );

      final info = await service.checkEngine();

      expect(info.ffmpegAvailable, isTrue);
      expect(info.ffmpegSource, EngineBinarySource.userBin);
      expect(info.ffmpegPath, userFfmpeg.path);
      expect(info.ffmpegVersion, contains('ffmpeg version 7.0'));
      expect(service.getFfmpegDirectory(), userBinDir.path);
    });

    test('detects FFmpeg in app bundle and resolves directory', () async {
      final bundleDir = io.Directory('${tempDir.path}/bundle/data/bin');
      bundleDir.createSync(recursive: true);

      final bundleFfmpeg = io.File('${bundleDir.path}/ffmpeg');
      bundleFfmpeg.writeAsStringSync('bundled ffmpeg');

      final mockProcess = _MockProcessService({
        'yt-dlp --version': io.ProcessResult(1, 0, '2025.01.15\n', ''),
        '${bundleFfmpeg.path} -version': io.ProcessResult(2, 0, 'ffmpeg version 6.1\n', ''),
      });

      final service = EngineService(
        processService: mockProcess,
        customHomeDir: tempDir.path,
        customBundleDir: '${tempDir.path}/bundle',
      );

      final info = await service.checkEngine();

      expect(info.ffmpegAvailable, isTrue);
      expect(info.ffmpegSource, EngineBinarySource.bundled);
      expect(service.getFfmpegDirectory(), bundleDir.path);
    });

    test('downloads and installs all packages sequentially', () async {
      final userBinDir = '${tempDir.path}/.spidey_dlx/bin';
      final ytdlpPath = '$userBinDir/yt-dlp';
      final ffmpegPath = '$userBinDir/ffmpeg';

      final mockProcess = _MockProcessService({
        'chmod +x $ytdlpPath': io.ProcessResult(1, 0, '', ''),
        'chmod +x $ffmpegPath': io.ProcessResult(2, 0, '', ''),
        'chmod +x $userBinDir/ffprobe': io.ProcessResult(3, 0, '', ''),
        '$ytdlpPath --version': io.ProcessResult(4, 0, '2025.03.01\n', ''),
        '$ffmpegPath -version': io.ProcessResult(5, 0, 'ffmpeg version 7.1\n', ''),
      });

      final service = EngineService(
        processService: mockProcess,
        customHomeDir: tempDir.path,
        binaryDownloader: (uri, dest, {onProgress}) async {
          dest.parent.createSync(recursive: true);
          onProgress?.call(0.5, 'Downloading...');
          // If it's the ffmpeg archive, write the ffmpeg executable to userBinDir
          if (uri.path.contains('ffmpeg')) {
            final f = io.File(ffmpegPath);
            f.writeAsStringSync('mock ffmpeg');
          } else {
            dest.writeAsStringSync('mock yt-dlp');
          }
          onProgress?.call(1.0, 'Done');
        },
      );

      final info = await service.downloadOrUpdateAllPackages();

      expect(info.isReady, isTrue);
      expect(info.isYtdlpReady, isTrue);
      expect(info.ffmpegAvailable, isTrue);
    });

    group('Version Comparison & Update Detection', () {
      test('isVersionNewer correctly compares date-based versions', () {
        expect(EngineService.isVersionNewer('2025.03.01', '2025.02.19'), isTrue);
        expect(EngineService.isVersionNewer('2025.02.19', '2025.02.19'), isFalse);
        expect(EngineService.isVersionNewer('2024.12.31', '2025.01.01'), isFalse);
        expect(EngineService.isVersionNewer('v2025.05.01', '2025.04.10'), isTrue);
        expect(EngineService.isVersionNewer('2025.02.19.1', '2025.02.19'), isTrue);
        expect(EngineService.isVersionNewer('2025.02.19', '2025.02.19.1'), isFalse);
        expect(EngineService.isVersionNewer('2025.02.19', ''), isTrue);
        expect(EngineService.isVersionNewer('', '2025.02.19'), isFalse);
      });

      test('fetchLatestYtDlpReleaseTag uses injected releaseFetcher', () async {
        final service = EngineService(
          customHomeDir: tempDir.path,
          releaseFetcher: () async => '2025.04.15',
        );

        final tag = await service.fetchLatestYtDlpReleaseTag();
        expect(tag, '2025.04.15');
      });

      test('checkForYtDlpUpdate returns newer tag when available', () async {
        final service = EngineService(
          customHomeDir: tempDir.path,
          releaseFetcher: () async => '2025.04.15',
        );

        final update = await service.checkForYtDlpUpdate(currentVersion: '2025.02.01');
        expect(update, '2025.04.15');

        final upToDate = await service.checkForYtDlpUpdate(currentVersion: '2025.04.15');
        expect(upToDate, isNull);

        final newerCurrent = await service.checkForYtDlpUpdate(currentVersion: '2025.05.01');
        expect(newerCurrent, isNull);
      });
    });
  });
}
