import 'dart:async';

import 'package:fl_video/fl_video.dart';
import 'package:fl_video/src/extension.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// 自定义全屏页面的构建器。
///
/// [controllerProvider] 是包含播放器画面的组件，可直接作为页面内容使用。
typedef FlVideoPlayerRoutePageBuilder = Widget Function(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  FlVideoPlayerControllerProvider controllerProvider,
);

/// 自定义字幕组件的构建器。
typedef FlSubtitlesBuilder = Widget Function(BuildContext context, String subtitle);

/// 视频播放组件，内置 Material 与 Cupertino 两种控制面板样式。
class FlVideoPlayer extends StatefulWidget {
  const FlVideoPlayer({super.key, required this.controller});

  /// 播放器控制器。
  final FlVideoPlayerController controller;

  @override
  State<FlVideoPlayer> createState() => _FlVideoPlayerState();
}

class _FlVideoPlayerState extends State<FlVideoPlayer> {
  /// 是否已打开全屏路由。
  bool _isFullScreen = false;

  /// 是否由本组件开启了屏幕常亮。
  bool _wakelockEnabled = false;

  /// 视频宽高比，用于决定画面尺寸。
  final ValueNotifier<double> _aspectRatio = ValueNotifier<double>(0);

  /// 打开全屏路由所用的 Navigator，便于销毁时精确关闭。
  NavigatorState? _fullScreenNavigator;

  /// 当前全屏路由，销毁时用它精确移除，避免误关其上的弹窗。
  Route<void>? _fullScreenRoute;

  /// 退出全屏时视频是否处于播放状态，用于视图重新挂载后恢复播放。
  bool _resumeAfterExit = false;

  /// 视图重建后的播放状态校验计时器。
  Timer? _resumeTimer;

  /// 已执行的播放状态校验次数。
  int _resumeAttempts = 0;

  /// 校验过程中是否已重新发起播放。
  bool _resumeIssued = false;

  /// 最近一次用户点击播放器的时间，用于避免自动恢复播放覆盖用户的暂停操作。
  DateTime? _lastUserTouch;

  /// 上次构建时的配置版本号，配置更新后触发重建。
  int _configRevision = 0;

  FlVideoPlayerController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller.addListener(listener);
  }

  @override
  void dispose() {
    _aspectRatio.dispose();
    _resumeTimer?.cancel();
    controller.removeListener(listener);
    // 销毁时若仍处于全屏，关闭路由并恢复系统 UI。
    if (_isFullScreen) {
      _isFullScreen = false;
      controller.exitFullScreen();
      _removeFullScreenRoute();
      _fullScreenNavigator = null;
      _restoreAfterFullScreen();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(FlVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 切换控制器时迁移监听，并关闭残留的全屏页。
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(listener);
      widget.controller.addListener(listener);
      if (oldWidget.controller.isFullScreen) {
        WidgetsBinding.instance.addPostFrameCallback((_) => oldWidget.controller.exitFullScreen());
      }
      if (_isFullScreen) {
        _isFullScreen = false;
        _fullScreenNavigator = null;
        // didUpdateWidget 处于构建阶段，路由移除延迟到当前帧结束后执行。
        final Route<void>? route = _fullScreenRoute;
        _fullScreenRoute = null;
        _restoreAfterFullScreen();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (route != null && route.isActive) route.navigator?.removeRoute(route);
        });
      }
    }
  }

  /// 精确移除当前全屏路由，避免 `maybePop` 误关其上方的弹窗。
  void _removeFullScreenRoute() {
    final Route<void>? route = _fullScreenRoute;
    _fullScreenRoute = null;
    if (route != null && route.isActive) route.navigator?.removeRoute(route);
  }

  /// 控制器通知：同步宽高比，并处理全屏的进入与退出。
  Future<void> listener() async {
    try {
      final double aspectRatio = controller.value.aspectRatio;
      if (aspectRatio != _aspectRatio.value) _aspectRatio.value = aspectRatio;
      // 运行期更新了 controls / overlay / placeholder 等配置时重建。
      if (controller.configRevision != _configRevision) {
        _configRevision = controller.configRevision;
        if (mounted) setState(() {});
      }
      if (controller.isFullScreen && !_isFullScreen) {
        if (_fullScreenNavigator != null) return;
        _isFullScreen = true;
        if (mounted) setState(() {});
        await _pushFullScreenWidget(wasPlaying: controller.isPlaying);
      } else if (!controller.isFullScreen && _isFullScreen) {
        // 记录退出前的播放状态，等视频视图重新挂载后再恢复。
        _resumeAfterExit = controller.isPlaying;
        _isFullScreen = false;
        // 路由退场结束后再恢复内联控制面板，避免与全屏页同时存在两份控件。
        final NavigatorState? navigator = _fullScreenNavigator;
        if (navigator == null) {
          if (mounted) setState(() {});
        } else {
          navigator.maybePop();
        }
      }
    } catch (error, stackTrace) {
      debugPrint('FlVideoPlayer fullscreen error: $error\n$stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) => FlVideoPlayerControllerProvider(
    controller: controller,
    child: _buildPlayer(attached: !_isFullScreen),
  );

  /// 构建播放器主体。
  ///
  /// [attached] 为 false 时不挂载视频画面、叠加层和控制面板（全屏时由全屏路由单独挂载）。
  /// 同一时刻只保留一份视频视图：Web 上重复挂载会把同一个 video 元素在两个平台视图间搬动，导致播放中断。
  Widget _buildPlayer({required bool attached}) {
    if (!attached) return const SizedBox.expand();
    return Universal(
      expand: true,
      color: Colors.black,
      isStack: true,
      children: [
        ValueListenableBuilder(
          valueListenable: _aspectRatio,
          builder: (_, double aspectRatio, _) =>
              aspectRatio != 0 && controller.videoPlayerController.value.isInitialized
              ? Universal(
                  alignment: Alignment.center,
                  aspectRatio: controller.videoPlayerController.value.aspectRatio,
                  child: VideoPlayer(controller.videoPlayerController),
                )
              : controller.placeholder ?? const SizedBox(),
        ),
        if (controller.overlay != null) controller.overlay!,
        if (controller.controls != null) _buildControls(),
      ],
    );
  }

  /// 构建控制面板层，并记录用户触摸时间。
  Widget _buildControls() {
    final Widget controls = controller.controls!;
    return Listener(
      onPointerDown: (_) => _lastUserTouch = DateTime.now(),
      child: controller.isFullScreen ? SafeArea(bottom: false, child: controls) : controls,
    );
  }

  /// 打开全屏路由，并处理进入时的常亮、系统 UI 与屏幕方向。
  ///
  /// [wasPlaying] 记录进入全屏前的播放状态，视图重新挂载被平台打断后用于恢复播放。
  Future<void> _pushFullScreenWidget({required bool wasPlaying}) async {
    final NavigatorState navigator = Navigator.of(context, rootNavigator: true);
    _fullScreenNavigator = navigator;
    final TransitionRoute<void> route = PageRouteBuilder<void>(
      pageBuilder: (BuildContext routeContext, Animation<double> animation, Animation<double> secondaryAnimation) {
        final FlVideoPlayerControllerProvider provider = FlVideoPlayerControllerProvider(
          controller: controller,
          child: _buildPlayer(attached: true),
        );
        if (controller.routePageBuilder != null) {
          return controller.routePageBuilder!(routeContext, animation, secondaryAnimation, provider);
        }
        return AnimatedBuilder(
          animation: animation,
          builder: (_, _) => Scaffold(backgroundColor: Colors.black, resizeToAvoidBottomInset: false, body: provider),
        );
      },
    );
    onEnterFullScreen();
    _fullScreenRoute = route;
    if (!controller.allowedScreenSleep) {
      _wakelockEnabled = true;
      _setWakelock(enable: true);
    }
    // 全屏页的视频视图在下一帧建立，这里按进入前的状态恢复播放。
    final Future<void> pushed = navigator.push(route);
    _resumeAfterViewRebuild(wasPlaying);
    await pushed;

    _fullScreenNavigator = null;
    _fullScreenRoute = null;
    _isFullScreen = false;
    // 组件已销毁时 dispose 已经恢复过系统状态，这里不再重复处理。
    if (!mounted) return;
    if (controller.isFullScreen) {
      // 退场动画期间用户又点了进入全屏：按最后一次操作重新打开全屏页。
      _resumeAfterExit = false;
      unawaited(listener());
      return;
    }
    controller.exitFullScreen();
    setState(() {});
    // 内联视频视图重新挂载，同样按退出前的状态恢复播放。
    _resumeAfterViewRebuild(_resumeAfterExit);
    _resumeAfterExit = false;
    _restoreAfterFullScreen();
  }

  /// 切换屏幕常亮，忽略平台不支持或权限不足导致的失败。
  void _setWakelock({required bool enable}) {
    final Future<void> task = enable ? WakelockPlus.enable() : WakelockPlus.disable();
    unawaited(
      task.catchError((Object error) {
        debugPrint('FlVideoPlayer wakelock error: $error');
      }),
    );
  }

  /// [since] 之后用户是否操作过播放器：触摸过控制面板，或主动暂停过。
  bool _userInterruptedSince(DateTime since) {
    final DateTime? touchedAt = _lastUserTouch;
    final DateTime? pausedAt = controller.lastUserPauseAt;
    return (touchedAt != null && touchedAt.isAfter(since)) || (pausedAt != null && pausedAt.isAfter(since));
  }

  /// 视频视图重新挂载后恢复播放状态。
  ///
  /// Web 等平台在平台视图被搬动时会暂停底层播放，且暂停事件可能晚于视图重建到达，
  /// 所以在一小段时间内做几次校验：一旦发现被平台暂停就按切换前的意图恢复播放，
  /// 恢复成功后立即停止校验；若用户在切换后已经操作过播放器（触摸控制面板或主动暂停），
  /// 则不再恢复，避免覆盖用户自己的暂停操作。
  void _resumeAfterViewRebuild(bool wasPlaying) {
    if (!wasPlaying) return;
    final DateTime startedAt = DateTime.now();
    _resumeAttempts = 0;
    _resumeIssued = false;
    _resumeTimer?.cancel();
    _resumeTimer = Timer.periodic(const Duration(milliseconds: 250), (Timer timer) {
      _resumeAttempts++;
      if (!mounted || _resumeAttempts > 4 || _userInterruptedSince(startedAt)) {
        timer.cancel();
        _resumeTimer = null;
        return;
      }
      if (controller.isPlaying) {
        // 已经恢复播放（或从未被平台暂停），结束校验。
        if (_resumeIssued) {
          timer.cancel();
          _resumeTimer = null;
        }
        return;
      }
      _resumeIssued = true;
      controller.play().onError((Object error, StackTrace stackTrace) {
        debugPrint('FlVideoPlayer resume playback error: $error');
      });
    });
  }

  /// 退出全屏后恢复常亮、系统 UI 和屏幕方向。
  void _restoreAfterFullScreen() {
    if (_wakelockEnabled) {
      _wakelockEnabled = false;
      _setWakelock(enable: false);
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: controller.systemOverlaysAfterFullScreen);
    SystemChrome.setPreferredOrientations(controller.deviceOrientationsAfterFullScreen);
  }

  /// 进入全屏时隐藏系统 UI，并按视频宽高比设置屏幕方向。
  void onEnterFullScreen() {
    final videoWidth = controller.videoPlayerController.value.size.width;
    final videoHeight = controller.videoPlayerController.value.size.height;

    if (controller.systemOverlaysOnEnterFullScreen != null) {
      // 使用自定义配置
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: controller.systemOverlaysOnEnterFullScreen!);
    } else {
      // 默认隐藏全部系统 UI
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    }

    if (controller.deviceOrientationsOnEnterFullScreen != null) {
      // 使用自定义配置
      SystemChrome.setPreferredOrientations(controller.deviceOrientationsOnEnterFullScreen!);
    } else {
      final isLandscapeVideo = videoWidth > videoHeight;
      final isPortraitVideo = videoWidth < videoHeight;

      // 默认：横屏视频强制横屏
      if (isLandscapeVideo) {
        SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
      }
      // 默认：竖屏视频强制竖屏
      else if (isPortraitVideo) {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
      }
      // 方形视频允许所有方向
      else {
        SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      }
    }
  }
}
