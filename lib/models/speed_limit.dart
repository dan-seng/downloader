/// Bandwidth transfer rate limits for subprocess speed throttling.
enum SpeedLimit {
  unlimited('Unlimited (Max Speed)', null, 'MAX'),
  mbps15('15 MB/s (High Speed)', '15M', '15 MB/s'),
  mbps10('10 MB/s (Standard)', '10M', '10 MB/s'),
  mbps5('5 MB/s (Balanced)', '5M', '5 MB/s'),
  mbps2('2 MB/s (Low Impact)', '2M', '2 MB/s'),
  mbps1('1 MB/s (Background)', '1M', '1 MB/s');

  final String label;
  final String? rateFlag;
  final String shortLabel;

  const SpeedLimit(this.label, this.rateFlag, this.shortLabel);

  bool get isThrottled => rateFlag != null;
}

/// Delayed download scheduling presets.
enum ScheduleDelay {
  none('Start Immediately', Duration.zero, 'NOW'),
  min15('In 15 minutes', Duration(minutes: 15), '15m'),
  min30('In 30 minutes', Duration(minutes: 30), '30m'),
  hour1('In 1 hour', Duration(hours: 1), '1h'),
  hour2('In 2 hours', Duration(hours: 2), '2h');

  final String label;
  final Duration duration;
  final String shortLabel;

  const ScheduleDelay(this.label, this.duration, this.shortLabel);

  bool get isDelayed => duration > Duration.zero;
}
