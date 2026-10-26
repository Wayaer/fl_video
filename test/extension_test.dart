import 'package:fl_video/fl_video.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatDuration', () {
    test('小于 1 小时显示 mm:ss', () {
      expect(Duration.zero.formatDuration(), '00:00');
      expect(const Duration(seconds: 5).formatDuration(), '00:05');
      expect(const Duration(minutes: 9, seconds: 59).formatDuration(), '09:59');
      expect(const Duration(minutes: 12, seconds: 34).formatDuration(), '12:34');
      expect(const Duration(minutes: 59, seconds: 59).formatDuration(), '59:59');
    });

    test('达到 1 小时显示 hh:mm:ss', () {
      expect(const Duration(hours: 1).formatDuration(), '01:00:00');
      expect(const Duration(hours: 1, minutes: 5, seconds: 3).formatDuration(), '01:05:03');
      expect(const Duration(hours: 10, minutes: 2).formatDuration(), '10:02:00');
      expect(const Duration(hours: 100).formatDuration(), '100:00:00');
    });

    test('不足 1 秒与负数都按 0 处理', () {
      expect(const Duration(milliseconds: 999).formatDuration(), '00:00');
      expect(const Duration(seconds: -5).formatDuration(), '00:00');
    });
  });
}
