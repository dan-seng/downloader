import 'package:flutter_test/flutter_test.dart';
import 'package:video_downloader/models/speed_limit.dart';

void main() {
  group('SpeedLimit Model', () {
    test('unlimited has null rateFlag and isThrottled false', () {
      expect(SpeedLimit.unlimited.rateFlag, isNull);
      expect(SpeedLimit.unlimited.isThrottled, isFalse);
      expect(SpeedLimit.unlimited.shortLabel, equals('MAX'));
    });

    test('speed limit options have correct rate flags', () {
      expect(SpeedLimit.mbps15.rateFlag, equals('15M'));
      expect(SpeedLimit.mbps15.isThrottled, isTrue);

      expect(SpeedLimit.mbps10.rateFlag, equals('10M'));
      expect(SpeedLimit.mbps10.isThrottled, isTrue);

      expect(SpeedLimit.mbps5.rateFlag, equals('5M'));
      expect(SpeedLimit.mbps5.isThrottled, isTrue);

      expect(SpeedLimit.mbps2.rateFlag, equals('2M'));
      expect(SpeedLimit.mbps2.isThrottled, isTrue);

      expect(SpeedLimit.mbps1.rateFlag, equals('1M'));
      expect(SpeedLimit.mbps1.isThrottled, isTrue);
    });
  });

  group('ScheduleDelay Model', () {
    test('none has zero duration and isDelayed false', () {
      expect(ScheduleDelay.none.duration, Duration.zero);
      expect(ScheduleDelay.none.isDelayed, isFalse);
    });

    test('presets have correct durations', () {
      expect(ScheduleDelay.min15.duration, const Duration(minutes: 15));
      expect(ScheduleDelay.min15.isDelayed, isTrue);

      expect(ScheduleDelay.min30.duration, const Duration(minutes: 30));
      expect(ScheduleDelay.hour1.duration, const Duration(hours: 1));
      expect(ScheduleDelay.hour2.duration, const Duration(hours: 2));
    });
  });
}
