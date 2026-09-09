import 'package:flutter_test/flutter_test.dart';
import 'package:video_downloader/models/time_range_clip.dart';

void main() {
  group('TimeRangeClip model tests', () {
    test('default constructor initializes expected properties', () {
      const clip = TimeRangeClip();
      expect(clip.isEnabled, isFalse);
      expect(clip.start, Duration.zero);
      expect(clip.end, isNull);
    });

    test('copyWith properly overrides specified properties', () {
      const clip = TimeRangeClip();
      final updated = clip.copyWith(
        isEnabled: true,
        start: const Duration(seconds: 45),
        end: const Duration(minutes: 3),
      );

      expect(updated.isEnabled, isTrue);
      expect(updated.start, const Duration(seconds: 45));
      expect(updated.end, const Duration(minutes: 3));
    });

    test('toSectionArgument formats for yt-dlp --download-sections syntax', () {
      const clip1 = TimeRangeClip(
        start: Duration(minutes: 1, seconds: 15),
        end: Duration(minutes: 3, seconds: 45),
      );
      expect(clip1.toSectionArgument(), '*01:15-03:45');

      const clip2 = TimeRangeClip(
        start: Duration(seconds: 30),
        end: null,
      );
      expect(clip2.toSectionArgument(), '*00:30-inf');

      const clipWithHours = TimeRangeClip(
        start: Duration(hours: 1, minutes: 2, seconds: 3),
        end: Duration(hours: 2, minutes: 30, seconds: 0),
      );
      expect(clipWithHours.toSectionArgument(), '*01:02:03-02:30:00');
    });

    test('formatSummary returns human readable representation', () {
      const clip = TimeRangeClip(
        start: Duration(minutes: 1, seconds: 0),
        end: Duration(minutes: 3, seconds: 30),
      );
      expect(clip.formatSummary(), '01:00 ➔ 03:30 (02:30)');

      const openClip = TimeRangeClip(
        start: Duration(minutes: 2, seconds: 0),
        end: null,
      );
      expect(openClip.formatSummary(), '02:00 ➔ End');
    });

    test('formatTimestamp correctly formats durations with or without hours', () {
      expect(TimeRangeClip.formatTimestamp(const Duration(seconds: 5)), '00:05');
      expect(TimeRangeClip.formatTimestamp(const Duration(minutes: 12, seconds: 34)), '12:34');
      expect(TimeRangeClip.formatTimestamp(const Duration(hours: 1, minutes: 23, seconds: 45)), '01:23:45');
    });

    test('parseTimeString handles ss, mm:ss, and hh:mm:ss string formats', () {
      expect(TimeRangeClip.parseTimeString('45'), const Duration(seconds: 45));
      expect(TimeRangeClip.parseTimeString('01:30'), const Duration(minutes: 1, seconds: 30));
      expect(TimeRangeClip.parseTimeString('1:30'), const Duration(minutes: 1, seconds: 30));
      expect(TimeRangeClip.parseTimeString('02:15:30'), const Duration(hours: 2, minutes: 15, seconds: 30));
      expect(TimeRangeClip.parseTimeString(''), isNull);
      expect(TimeRangeClip.parseTimeString('invalid'), isNull);
      expect(TimeRangeClip.parseTimeString('01:invalid'), isNull);
      expect(TimeRangeClip.parseTimeString('-10'), isNull);
    });

    test('equality and hashcode match on identical values', () {
      const clip1 = TimeRangeClip(
        isEnabled: true,
        start: Duration(seconds: 10),
        end: Duration(seconds: 50),
      );
      const clip2 = TimeRangeClip(
        isEnabled: true,
        start: Duration(seconds: 10),
        end: Duration(seconds: 50),
      );
      const clip3 = TimeRangeClip(
        isEnabled: false,
        start: Duration(seconds: 10),
        end: Duration(seconds: 50),
      );

      expect(clip1, equals(clip2));
      expect(clip1.hashCode, equals(clip2.hashCode));
      expect(clip1, isNot(equals(clip3)));
    });
  });
}
