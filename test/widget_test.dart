import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_downloader/controllers/video_controller.dart';
import 'package:video_downloader/main.dart';
import 'package:video_downloader/models/video_format.dart';
import 'package:video_downloader/models/video_info.dart';
import 'package:video_downloader/services/process_service.dart';
import 'package:video_downloader/services/ytdlp_service.dart';

class MockYtDlpService extends YtDlpService {
  VideoInfo? mockResult;

  MockYtDlpService() : super(processService: _DummyProcessService());

  @override
  Future<VideoInfo> fetchVideoInfo(String rawUrl) async {
    return mockResult ??
        const VideoInfo(
          id: 'test-123',
          title: 'Sample Video Title',
          uploader: 'Sample Creator',
          duration: Duration(minutes: 5, seconds: 30),
          formats: [
            VideoFormat(
              formatId: '1',
              extension: 'mp4',
              height: 1080,
              videoCodec: 'h264',
              audioCodec: 'aac',
            ),
          ],
        );
  }
}

class _DummyProcessService implements ProcessService {
  @override
  Future<io.ProcessResult> run(String executable, List<String> arguments,
      {String? workingDirectory, Map<String, String>? environment}) async {
    return io.ProcessResult(1, 0, '', '');
  }

  @override
  Future<io.Process> start(String executable, List<String> arguments,
      {String? workingDirectory,
      Map<String, String>? environment,
      io.ProcessStartMode mode = io.ProcessStartMode.normal}) {
    throw UnimplementedError();
  }
}

void main() {
  testWidgets('Renders HomeScreen with input bar and empty state',
      (WidgetTester tester) async {
    final mockService = MockYtDlpService();
    final controller = VideoController(ytDlpService: mockService);

    await tester.pumpWidget(VideoDownloaderApp(videoController: controller));

    // Verify title and headers
    expect(find.text('Video Downloader'), findsOneWidget);
    expect(find.text('Analyze Media'), findsOneWidget);
    expect(find.text('No video analyzed yet'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Analyze'), findsOneWidget);

    // Enter a URL
    await tester.enterText(
        find.byType(TextField), 'https://www.youtube.com/watch?v=123');
    await tester.pump();

    // Tap the analyze button
    await tester.tap(find.text('Analyze'));
    await tester.pump(); // Start async action

    // Wait for the mock fetch to settle
    await tester.pumpAndSettle();

    // Verify the preview card is rendered with metadata
    expect(find.text('Sample Video Title'), findsOneWidget);
    expect(find.text('Sample Creator'), findsOneWidget);
    expect(find.text('05:30'), findsNWidgets(2));
    expect(find.text('1 formats available'), findsOneWidget);
  });
}
