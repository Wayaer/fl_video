// 可变配置使用私有字段 + 公开 getter（写入统一走 updateConfig），这些字段由构造函数初始化
// 列表赋值；命名参数不能以下划线开头，无法使用 Initializing formal，因此关闭该 lint。
// ignore_for_file: prefer_initializing_formals

import 'package:fl_video/fl_video.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// 视频播放器控制器。
///
/// 包装底层 [VideoPlayerController]，统一管理播放状态、字幕、全屏切换和自定义控件。
class FlVideoPlayerController extends ChangeNotifier {
  FlVideoPlayerController({
    required this.videoPlayerController,
    this.autoInitialize = false,
    this.autoPlay = false,
    this.startAt,
    this.looping = false,
    this.fullScreenByDefault = false,
    Widget? placeholder,
    Widget? overlay,
    bool showControlsOnInitialize = true,
    FlSubtitles? subtitle,
    FlSubtitlesBuilder? subtitleBuilder,
    Widget? controls,
    bool allowedScreenSleep = true,
    bool isLive = false,
    this.systemOverlaysOnEnterFullScreen,
    this.deviceOrientationsOnEnterFullScreen,
    this.systemOverlaysAfterFullScreen = SystemUiOverlay.values,
    this.deviceOrientationsAfterFullScreen = const [DeviceOrientation.portraitUp],
    this.routePageBuilder,
  }) : _subtitle = subtitle,
       _placeholder = placeholder,
       _overlay = overlay,
       _showControlsOnInitialize = showControlsOnInitialize,
       _subtitleBuilder = subtitleBuilder,
       _controls = controls,
       _allowedScreenSleep = allowedScreenSleep,
       _isLive = isLive {
    videoPlayerController.addListener(_onVideoControllerUpdate);
    // 只有显式开启自动初始化/自动播放时才在构造阶段初始化，
    // 否则由使用方（或控制面板的播放按钮）在需要时调用 [initialize]。
    if (autoInitialize || autoPlay) initialize();
  }

  Widget? _controls;
  Widget? _placeholder;
  Widget? _overlay;
  FlSubtitlesBuilder? _subtitleBuilder;
  FlSubtitles? _subtitle;
  bool _showControlsOnInitialize;
  bool _allowedScreenSleep;
  bool _isLive;

  /// 字幕列表，请通过 [setSubtitle] 更新以触发控制面板刷新。
  FlSubtitles? get subtitle => _subtitle;

  /// 自定义字幕组件的构建器。
  FlSubtitlesBuilder? get subtitleBuilder => _subtitleBuilder;

  /// 底层视频播放器控制器。
  final VideoPlayerController videoPlayerController;

  /// 是否在创建后自动初始化视频（[autoPlay] 为 true 时同样会初始化）。
  final bool autoInitialize;

  /// 是否在初始化完成后自动播放。
  final bool autoPlay;

  /// 初始播放位置；在初始化（自动或手动）时生效。
  final Duration? startAt;

  /// 是否循环播放。
  final bool looping;

  /// 控制面板初始化时是否短暂显示一次。
  bool get showControlsOnInitialize => _showControlsOnInitialize;

  /// 自定义控制面板，可参考 [FlMaterialControls] 或 [FlCupertinoControls]。
  Widget? get controls => _controls;

  /// 视频未初始化时显示的占位组件。
  Widget? get placeholder => _placeholder;

  /// 位于视频之上、控制面板之下的叠加组件。
  Widget? get overlay => _overlay;

  /// 是否在首次播放时自动进入全屏。
  final bool fullScreenByDefault;

  /// 全屏时是否允许系统息屏；为 false 时保持屏幕常亮。
  bool get allowedScreenSleep => _allowedScreenSleep;

  /// 是否为直播流。
  bool get isLive => _isLive;

  /// 进入全屏时保留的系统 UI；为空则隐藏全部系统 UI。
  final List<SystemUiOverlay>? systemOverlaysOnEnterFullScreen;

  /// 进入全屏时使用的屏幕方向；为空则按视频宽高比自动选择。
  final List<DeviceOrientation>? deviceOrientationsOnEnterFullScreen;

  /// 退出全屏后恢复的系统 UI。
  final List<SystemUiOverlay> systemOverlaysAfterFullScreen;

  /// 退出全屏后恢复的屏幕方向，默认仅竖屏；横屏优先的应用需显式传入所需方向。
  final List<DeviceOrientation> deviceOrientationsAfterFullScreen;

  /// 自定义全屏页面构建器。
  final FlVideoPlayerRoutePageBuilder? routePageBuilder;

  /// 获取 [context] 所在 [FlVideoPlayer] 的控制器。
  ///
  /// 不在 [FlVideoPlayer] 子树中使用时会抛出 [FlutterError]。
  static FlVideoPlayerController of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<FlVideoPlayerControllerProvider>();
    if (provider == null) {
      throw FlutterError(
        'FlVideoPlayerController.of() was called with a context that does not contain a FlVideoPlayer.',
      );
    }
    return provider.controller;
  }

  bool _isFullScreen = false;
  bool _isDisposed = false;
  Future<void>? _initializeFuture;
  DateTime? _lastUserPauseAt;
  int _configRevision = 0;

  /// 展示配置的版本号，配置更新后自增，供 [FlVideoPlayer] 判断是否需要重建。
  int get configRevision => _configRevision;

  /// 视频是否已初始化完成。
  bool get isInitialized => videoPlayerController.value.isInitialized;

  /// 是否循环播放。
  bool get isLooping => videoPlayerController.value.isLooping;

  /// 是否正在缓冲。
  bool get isBuffering => videoPlayerController.value.isBuffering;

  /// 当前播放位置。
  Duration get position => videoPlayerController.value.position;

  /// 视频总时长。
  Duration get duration => videoPlayerController.value.duration;

  /// 是否发生播放错误。
  bool get hasError => videoPlayerController.value.hasError;

  /// 当前音量（0.0 ~ 1.0）。
  double get volume => videoPlayerController.value.volume;

  /// 已缓冲的时间区间。
  List<DurationRange> get buffered => videoPlayerController.value.buffered;

  /// 当前播放倍速。
  double get playbackSpeed => videoPlayerController.value.playbackSpeed;

  /// 底层播放器的完整状态。
  VideoPlayerValue get value => videoPlayerController.value;

  /// 错误描述，仅 [hasError] 为 true 时非空。
  String? get errorDescription => videoPlayerController.value.errorDescription;

  /// 是否处于全屏状态。
  bool get isFullScreen => _isFullScreen;

  /// 是否正在播放。
  bool get isPlaying => videoPlayerController.value.isPlaying;

  /// 转发底层播放器的所有状态变化，使其可作为统一的 Listenable 使用。
  void _onVideoControllerUpdate() {
    if (_isDisposed) return;
    notifyListeners();
  }

  /// 初始化视频。
  ///
  /// 未初始化时会真正初始化底层播放器（无论 [autoInitialize] / [autoPlay] 是否开启），
  /// 初始化完成后应用 [looping] 与 [startAt]；重复调用会复用同一次初始化，
  /// 上次初始化失败时会重新尝试。
  Future<void> initialize() {
    if (_isDisposed || videoPlayerController.value.isInitialized) return Future<void>.value();
    return _initializeFuture ??= _initialize().catchError((Object error, StackTrace stackTrace) {
      debugPrint('FlVideoPlayerController initialize error: $error\n$stackTrace');
      // 允许失败后重试：播放按钮等入口会再次调用 initialize()。
      _initializeFuture = null;
      if (!_isDisposed) notifyListeners();
    });
  }

  /// 按配置初始化视频、设置循环与初始位置，并按需自动播放。
  Future<void> _initialize() async {
    if (_isDisposed) return;
    if (!videoPlayerController.value.isInitialized) {
      await videoPlayerController.initialize();
      if (_isDisposed) return;
    }
    await videoPlayerController.setLooping(looping);
    if (_isDisposed) return;

    // 先跳转到初始位置再播放，避免自动播放时先播一小段再跳走。
    if (startAt != null) {
      await videoPlayerController.seekTo(startAt!);
      if (_isDisposed) return;
    }

    // 自动全屏只生效一次：先注册监听，保证自动播放或用户首次播放后立即注销。
    if (fullScreenByDefault) {
      videoPlayerController.removeListener(_fullScreenListener);
      videoPlayerController.addListener(_fullScreenListener);
    }

    if (autoPlay) {
      if (fullScreenByDefault) enterFullScreen();
      await videoPlayerController.play();
    }
    if (_isDisposed) return;

    notifyListeners();
  }

  /// 首次播放时自动进入全屏（仅在 [fullScreenByDefault] 为 true 时注册）。
  ///
  /// 只要视频进入过播放状态就注销自己，否则用户退出全屏后会被立刻再次拉回全屏。
  void _fullScreenListener() {
    if (_isDisposed) return;
    if (!videoPlayerController.value.isPlaying) return;
    videoPlayerController.removeListener(_fullScreenListener);
    if (!_isFullScreen) enterFullScreen();
  }

  /// 进入全屏。
  void enterFullScreen() {
    if (_isDisposed) return;
    _isFullScreen = true;
    notifyListeners();
  }

  /// 退出全屏。
  void exitFullScreen() {
    if (_isDisposed) return;
    _isFullScreen = false;
    notifyListeners();
  }

  /// 切换全屏状态。
  void toggleFullScreen() {
    if (_isDisposed) return;
    _isFullScreen = !_isFullScreen;
    notifyListeners();
  }

  /// 在播放与暂停之间切换。
  Future<void> togglePause() => isPlaying ? pause() : play();

  /// 开始播放。
  Future<void> play() {
    _lastUserPauseAt = null;
    return videoPlayerController.play();
  }

  /// 设置播放倍速。
  Future<void> setPlaybackSpeed(double speed) => videoPlayerController.setPlaybackSpeed(speed);

  /// 设置是否循环播放。
  Future<void> setLooping(bool looping) => videoPlayerController.setLooping(looping);

  /// 暂停播放。
  Future<void> pause() {
    _lastUserPauseAt = DateTime.now();
    return videoPlayerController.pause();
  }

  /// 最近一次调用 [pause] 的时间，用于区分“用户主动暂停”与平台导致的暂停。
  DateTime? get lastUserPauseAt => _lastUserPauseAt;

  /// 更新运行期可变的展示配置，完成后通知控制面板刷新。
  ///
  /// 传入 null 的参数保持原值；需要移除已有组件时可传入 [SizedBox.shrink]。
  /// [autoInitialize]、[autoPlay]、[startAt]、[fullScreenByDefault] 等初始化相关配置只
  /// 在构造时生效，不支持运行期更新。
  void updateConfig({
    Widget? controls,
    Widget? overlay,
    Widget? placeholder,
    FlSubtitlesBuilder? subtitleBuilder,
    bool? showControlsOnInitialize,
    bool? allowedScreenSleep,
    bool? isLive,
  }) {
    if (_isDisposed) return;
    if (controls != null) _controls = controls;
    if (overlay != null) _overlay = overlay;
    if (placeholder != null) _placeholder = placeholder;
    if (subtitleBuilder != null) _subtitleBuilder = subtitleBuilder;
    if (showControlsOnInitialize != null) _showControlsOnInitialize = showControlsOnInitialize;
    if (allowedScreenSleep != null) _allowedScreenSleep = allowedScreenSleep;
    if (isLive != null) _isLive = isLive;
    _configRevision++;
    notifyListeners();
  }

  /// 跳转到指定位置。
  Future<void> seekTo(Duration moment) => videoPlayerController.seekTo(moment);

  /// 设置音量（0.0 ~ 1.0）。
  Future<void> setVolume(double volume) => videoPlayerController.setVolume(volume);

  /// 替换字幕列表并通知控制面板刷新。
  void setSubtitle(List<FlSubtitle> newSubtitle) {
    if (_isDisposed) return;
    _subtitle = FlSubtitles(newSubtitle);
    notifyListeners();
  }

  /// 释放控制器。
  ///
  /// [disposeVideoPlayer] 默认同时释放底层播放器，避免音频和平台资源泄漏；
  /// 传 false 时底层播放器（及其音频、定时器）会继续运行。
  @override
  Future<void> dispose([bool disposeVideoPlayer = true]) async {
    if (_isDisposed) {
      // 控制器已释放过，仍允许补一次底层播放器释放。
      if (disposeVideoPlayer) await videoPlayerController.dispose();
      return;
    }
    _isDisposed = true;
    videoPlayerController.removeListener(_onVideoControllerUpdate);
    videoPlayerController.removeListener(_fullScreenListener);
    super.dispose();
    if (disposeVideoPlayer) await videoPlayerController.dispose();
  }
}

/// 向子树提供 [FlVideoPlayerController] 的 InheritedWidget（内部使用）。
class FlVideoPlayerControllerProvider extends InheritedWidget {
  const FlVideoPlayerControllerProvider({super.key, required this.controller, required super.child});

  /// 提供的控制器。
  final FlVideoPlayerController controller;

  @override
  bool updateShouldNotify(covariant FlVideoPlayerControllerProvider oldWidget) => controller != oldWidget.controller;
}
