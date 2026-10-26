import 'package:fl_video/fl_video.dart';
import 'package:flutter_test/flutter_test.dart';

/// 探针控制器：记录底层调用次数，不依赖真实平台。
class SpyVideoPlayerController extends VideoPlayerController {
  SpyVideoPlayerController({this.initializeThrows = false}) : super.asset('assets/v.mp4');

  /// 为 true 时模拟初始化失败。
  final bool initializeThrows;

  int initializeCalls = 0;
  int disposeCalls = 0;
  bool initialized = false;
  Duration? seekedTo;

  @override
  Future<void> initialize() async {
    initializeCalls++;
    if (initializeThrows) throw Exception('initialize failed');
    initialized = true;
    value = value.copyWith(isInitialized: true);
  }

  @override
  Future<void> dispose() async {
    disposeCalls++;
    super.dispose();
  }

  @override
  Future<void> seekTo(Duration position) async {
    seekedTo = position;
    value = value.copyWith(position: position);
  }

  // 播放控制只改内存状态，避免测试环境缺少平台实现而抛错。
  @override
  Future<void> setLooping(bool looping) async {
    value = value.copyWith(isLooping: looping);
  }

  @override
  Future<void> play() async {
    value = value.copyWith(isPlaying: true);
  }

  @override
  Future<void> pause() async {
    value = value.copyWith(isPlaying: false);
  }
}

void main() {
  group('initialize', () {
    test('默认配置下手动 initialize() 会真正初始化底层播放器', () async {
      final spy = SpyVideoPlayerController();
      final controller = FlVideoPlayerController(videoPlayerController: spy);

      await controller.initialize();
      expect(spy.initializeCalls, 1);
      expect(controller.isInitialized, isTrue);

      // 重复调用复用同一次初始化
      await controller.initialize();
      expect(spy.initializeCalls, 1);
      await controller.dispose();
    });

    test('默认配置下构造时不初始化', () async {
      final spy = SpyVideoPlayerController();
      final controller = FlVideoPlayerController(videoPlayerController: spy);
      await Future<void>.delayed(Duration.zero);
      expect(spy.initializeCalls, 0);
      await controller.dispose();
    });

    test('autoPlay 时构造后自动初始化并播放', () async {
      final spy = SpyVideoPlayerController();
      final controller = FlVideoPlayerController(videoPlayerController: spy, autoPlay: true);
      await Future<void>.delayed(Duration.zero);
      expect(spy.initializeCalls, 1);
      expect(controller.isPlaying, isTrue);
      await controller.dispose();
    });

    test('startAt 在手动初始化时生效', () async {
      final spy = SpyVideoPlayerController();
      final controller = FlVideoPlayerController(videoPlayerController: spy, startAt: const Duration(seconds: 5));
      await controller.initialize();
      expect(spy.seekedTo, const Duration(seconds: 5));
      await controller.dispose();
    });

    test('初始化失败后可以重试', () async {
      final spy = SpyVideoPlayerController(initializeThrows: true);
      final controller = FlVideoPlayerController(videoPlayerController: spy);

      await controller.initialize();
      expect(spy.initializeCalls, 1);
      await controller.initialize();
      expect(spy.initializeCalls, 2, reason: '失败后应允许重新初始化');
      await controller.dispose();
    });
  });

  group('dispose', () {
    test('默认释放底层播放器', () async {
      final spy = SpyVideoPlayerController();
      final controller = FlVideoPlayerController(videoPlayerController: spy);
      await controller.dispose();
      expect(spy.disposeCalls, 1);
    });

    test('传 false 时保留底层播放器', () async {
      final spy = SpyVideoPlayerController();
      final controller = FlVideoPlayerController(videoPlayerController: spy);
      await controller.dispose(false);
      expect(spy.disposeCalls, 0);
      await spy.dispose();
    });
  });

  group('全屏', () {
    test('自动全屏只触发一次，退出后不会被再次拉回', () async {
      final spy = SpyVideoPlayerController();
      final controller = FlVideoPlayerController(videoPlayerController: spy, fullScreenByDefault: true);
      controller.enterFullScreen();
      await Future<void>.delayed(Duration.zero);
      expect(controller.isFullScreen, isTrue);

      await controller.play();
      controller.exitFullScreen();
      expect(controller.isFullScreen, isFalse);

      spy.value = spy.value.copyWith(position: const Duration(seconds: 1));
      expect(controller.isFullScreen, isFalse, reason: '退出后不应被重新拉回全屏');
      await controller.dispose();
    });

    test('用户主动暂停会被记录', () async {
      final spy = SpyVideoPlayerController();
      final controller = FlVideoPlayerController(videoPlayerController: spy);
      expect(controller.lastUserPauseAt, isNull);

      await controller.pause();
      expect(controller.lastUserPauseAt, isNotNull);

      await controller.play();
      expect(controller.lastUserPauseAt, isNull, reason: '恢复播放后应清空暂停时间');
      await controller.dispose();
    });
  });

  group('配置与字幕', () {
    test('updateConfig 会更新配置并通知', () async {
      final spy = SpyVideoPlayerController();
      final controller = FlVideoPlayerController(videoPlayerController: spy);
      int notified = 0;
      controller.addListener(() => notified++);

      controller.updateConfig(isLive: true, allowedScreenSleep: false);
      expect(controller.isLive, isTrue);
      expect(controller.allowedScreenSleep, isFalse);
      expect(notified, 1);

      // 未传的字段保持原值
      controller.updateConfig();
      expect(controller.isLive, isTrue);
      await controller.dispose();
    });

    test('setSubtitle 会替换字幕并通知', () async {
      final spy = SpyVideoPlayerController();
      final controller = FlVideoPlayerController(videoPlayerController: spy);
      int notified = 0;
      controller.addListener(() => notified++);

      controller.setSubtitle([FlSubtitle(index: 0, start: Duration.zero, end: const Duration(seconds: 1), text: 'a')]);
      expect(controller.subtitle?.isNotEmpty, isTrue);
      expect(notified, 1);
      await controller.dispose();
    });

    test('字幕区间为左闭右开', () {
      final subtitles = FlSubtitles([
        FlSubtitle(index: 0, start: Duration.zero, end: const Duration(seconds: 10), text: 'a'),
        FlSubtitle(index: 1, start: const Duration(seconds: 10), end: const Duration(seconds: 20), text: 'b'),
      ]);
      expect(subtitles.getByPosition(Duration.zero).first!.text, 'a');
      expect(subtitles.getByPosition(const Duration(seconds: 10)).first!.text, 'b');
      expect(subtitles.getByPosition(const Duration(seconds: 20)), isEmpty);
    });
  });
}
