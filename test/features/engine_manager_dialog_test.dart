import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_downloader/controllers/download_controller.dart';
import 'package:video_downloader/features/home/widgets/engine_manager_dialog.dart';
import 'package:video_downloader/models/download_archive_item.dart';
import 'package:video_downloader/services/archive_service.dart';
import 'package:video_downloader/services/engine_service.dart';
import 'package:video_downloader/services/process_service.dart';

class _MockArchiveService extends ArchiveService {
  @override
  Future<List<DownloadArchiveItem>> loadArchive() async => [];
  @override
  Future<void> saveItem(DownloadArchiveItem item) async {}
  @override
  Future<bool> deleteItem(String id, {bool deleteFileFromDisk = false}) async => true;
}

class _MockEngineProcessService implements ProcessService {
  final Map<String, io.ProcessResult> responses;

  _MockEngineProcessService(this.responses);

  @override
  Future<io.ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    final key = '$executable ${arguments.join(' ')}';
    if (responses.containsKey(key)) {
      return responses[key]!;
    }
    return io.ProcessResult(0, 1, '', 'not found');
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
  group('EngineManagerDialog Widget Tests', () {
    testWidgets('renders detected engine info and version correctly', (tester) async {
      final mockProcess = _MockEngineProcessService({
        'yt-dlp --version': io.ProcessResult(1, 0, '2025.01.20\n', ''),
        'ffmpeg -version': io.ProcessResult(2, 0, 'ffmpeg version 6.1.1\n', ''),
      });

      final engineService = EngineService(
        processService: mockProcess,
        customHomeDir: '/tmp/nonexistent_home',
      );

      final controller = DownloadController(
        archiveService: _MockArchiveService(),
        engineService: engineService,
      );

      await controller.checkEngine();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EngineManagerDialog(
              downloadController: controller,
              isDark: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('VINX ENGINE SUBSYSTEM'), findsOneWidget);
      expect(find.text('2025.01.20'), findsOneWidget);
      expect(find.text('UPDATE TO LATEST RELEASE'), findsOneWidget);
      expect(find.text('DETECTED'), findsOneWidget);
    });

    testWidgets('renders missing state when no engine is installed', (tester) async {
      final mockProcess = _MockEngineProcessService({});

      final engineService = EngineService(
        processService: mockProcess,
        customHomeDir: '/tmp/nonexistent_home',
      );

      final controller = DownloadController(
        archiveService: _MockArchiveService(),
        engineService: engineService,
      );

      await controller.checkEngine();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EngineManagerDialog(
              downloadController: controller,
              isDark: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('MISSING'), findsOneWidget);
      expect(find.text('DOWNLOAD & INSTALL yt-dlp'), findsOneWidget);
      expect(find.text('NOT FOUND'), findsOneWidget);
    });

    testWidgets('tapping download triggers engine update and displays progress', (tester) async {
      final mockProcess = _MockEngineProcessService({
        'chmod +x /tmp/test_home/.spidey_dlx/bin/yt-dlp': io.ProcessResult(1, 0, '', ''),
        '/tmp/test_home/.spidey_dlx/bin/yt-dlp --version': io.ProcessResult(2, 0, '2025.02.10\n', ''),
      });

      final engineService = EngineService(
        processService: mockProcess,
        customHomeDir: '/tmp/test_home',
        binaryDownloader: (uri, dest, {onProgress}) async {
          dest.parent.createSync(recursive: true);
          onProgress?.call(0.65, 'Downloading engine (65%)...');
          dest.writeAsStringSync('mock binary');
        },
      );

      final controller = DownloadController(
        archiveService: _MockArchiveService(),
        engineService: engineService,
      );

      await controller.checkEngine();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EngineManagerDialog(
              downloadController: controller,
              isDark: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final actionBtn = find.byKey(const ValueKey('engine_dialog_action_button'));
      expect(actionBtn, findsOneWidget);

      // Trigger update
      await tester.tap(actionBtn);
      await tester.pump();

      // Controller should update engine info after completion
      await tester.pumpAndSettle();

      expect(controller.engineInfo?.isYtdlpReady, isTrue);
      expect(controller.engineInfo?.ytdlpVersion, '2025.02.10');
    });
  });
}
