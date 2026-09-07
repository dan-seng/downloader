import 'package:flutter_test/flutter_test.dart';
import 'package:video_downloader/core/utils/formatters.dart';

void main() {
  group('Formatters', () {
    test('formats duration correctly', () {
      expect(Formatters.formatDuration(null), equals('Unknown'));
      expect(Formatters.formatDuration(const Duration(seconds: 0)), equals('00:00'));
      expect(Formatters.formatDuration(const Duration(seconds: 45)), equals('00:45'));
      expect(Formatters.formatDuration(const Duration(minutes: 3, seconds: 15)), equals('03:15'));
      expect(Formatters.formatDuration(const Duration(hours: 1, minutes: 2, seconds: 3)), equals('01:02:03'));
      expect(Formatters.formatDuration(const Duration(hours: 10, minutes: 0, seconds: 0)), equals('10:00:00'));
    });

    test('formats byte sizes correctly', () {
      expect(Formatters.formatBytes(null), equals('Unknown size'));
      expect(Formatters.formatBytes(-5), equals('Unknown size'));
      expect(Formatters.formatBytes(500), equals('500 B'));
      expect(Formatters.formatBytes(1024), equals('1.0 KB'));
      expect(Formatters.formatBytes(1536), equals('1.5 KB'));
      expect(Formatters.formatBytes(1048576), equals('1.0 MB'));
      expect(Formatters.formatBytes(15728640), equals('15.0 MB'));
      expect(Formatters.formatBytes(1073741824), equals('1.0 GB'));
    });

    test('formats fps correctly', () {
      expect(Formatters.formatFps(null), isNull);
      expect(Formatters.formatFps(0), isNull);
      expect(Formatters.formatFps(29.97), equals('30 fps'));
      expect(Formatters.formatFps(24.5), equals('24.5 fps'));
      expect(Formatters.formatFps(30), equals('30 fps'));
      expect(Formatters.formatFps(60), equals('60 fps'));
    });
  });
}
