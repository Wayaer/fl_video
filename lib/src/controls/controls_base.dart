import 'dart:async';

import 'package:fl_video/fl_video.dart';
import 'package:material_ui/material_ui.dart';

/// 两种内置控制面板共有的参数（内部使用）：由 [FlControlsState] 读取。
abstract class FlControlsWidget extends StatefulWidget {
  const FlControlsWidget({super.key});

  /// 图标和文字颜色。
  Color get color;

  /// 无操作后自动隐藏控制面板的时长。
  Duration get hideDuration;

  /// 是否为直播。
  bool get isLive;

  /// 字幕初始开关；为空时按是否存在字幕自动决定。
  bool? get subtitleOn;

  /// 是否启用双击播放/暂停。
  bool get enableDoubleTap;

  /// 加载/缓冲时显示的组件。
  Widget get loading;

  /// 错误提示图标。
  IconData get error;

  /// 自定义错误界面。
  FlVideoControlsErrorBuilder? get errorBuilder;

  /// 点击控制面板元素时的回调。
  FlVideoControlsTap? get onTap;

  /// 可选倍速列表。
  List<double> get playbackSpeeds;

  /// 倍速弹窗自定义配置；为空时使用内置弹窗。
  FlVideoSpeedConfig? get speedConfig;
}

/// 两种内置控制面板共享的状态逻辑（内部使用）。
abstract class FlControlsState<W extends FlControlsWidget> extends State<W> {
  /// 控制面板显隐通知器。
  late FlPlayerNotifier notifier;

  /// 最近一次的播放器状态。
  VideoPlayerValue latestValue = VideoPlayerValue.uninitialized();

  /// 静音前的音量，用于取消静音时恢复。
  double? latestVolume;

  /// 自动隐藏控制面板的计时器。
  Timer? hideTimer;

  /// 是否正在拖动进度条。
  bool dragging = false;

  /// 字幕当前是否开启。
  bool subtitleOn = false;

  /// 底层视频控制器。
  late VideoPlayerController controller;

  Timer? _initTimer;
  Timer? _expandCollapseTimer;
  bool _latestFullScreen = false;
  bool _latestIsLive = false;
  FlSubtitles? _knownSubtitle;
  FlVideoPlayerController? _flVideoController;

  /// 包装层控制器，在 [didChangeDependencies] 后可用。
  FlVideoPlayerController get flVideoController => _flVideoController!;

  /// 是否按直播处理：面板参数与控制器任一为 true 即视为直播。
  bool get isLive => widget.isLive || flVideoController.isLive;

  @override
  void initState() {
    super.initState();
    notifier = FlPlayerNotifier.init;
  }

  @override
  void dispose() {
    disposeControls();
    notifier.dispose();
    super.dispose();
  }

  /// 释放监听与全部计时器。
  void disposeControls() {
    _flVideoController?.removeListener(updateState);
    hideTimer?.cancel();
    _initTimer?.cancel();
    _expandCollapseTimer?.cancel();
  }

  @override
  void didChangeDependencies() {
    final FlVideoPlayerController? oldController = _flVideoController;
    final FlVideoPlayerController flController = FlVideoPlayerController.of(context);
    if (oldController != flController) {
      if (oldController != null) disposeControls();
      _flVideoController = flController;
      controller = flController.videoPlayerController;
      initializeControls();
    }
    super.didChangeDependencies();
  }

  /// 初始化面板：同步字幕状态、监听控制器，并按需短暂显示一次。
  void initializeControls() {
    _knownSubtitle = flVideoController.subtitle;
    subtitleOn = widget.subtitleOn ?? (_knownSubtitle?.isNotEmpty ?? false);
    flVideoController.addListener(updateState);
    updateState();
    if (controller.value.isPlaying || flVideoController.autoPlay) {
      startHideTimer();
    }

    if (flVideoController.showControlsOnInitialize) {
      _initTimer = Timer(const Duration(milliseconds: 200), () {
        notifier.hideStuff = false;
        setState(() {});
      });
    }
  }

  /// 构建播放错误界面。
  Widget buildError() {
    final String? errorDescription = flVideoController.videoPlayerController.value.errorDescription;
    return widget.errorBuilder?.call(context, errorDescription!) ??
        FlDefaultError(
          color: widget.color,
          error: widget.error,
          semanticLabel: errorDescription,
          onTap: widget.onTap == null
              ? null
              : () {
                  widget.onTap!(FlVideoTapEvent.error, flVideoController);
                },
        );
  }

  /// 包一层鼠标悬停 / 点击 / 双击的公共手势外壳。
  Widget buildTapShell(Widget child) => MouseRegion(
    onHover: (_) => cancelAndRestartHideTimer(),
    child: GestureDetector(
      onTap: cancelAndRestartHideTimer,
      onDoubleTap: widget.enableDoubleTap ? handleDoubleTap : null,
      child: child,
    ),
  );

  /// 构建当前显示的字幕；没有字幕时返回占位组件。
  Widget buildSubtitles() {
    final currentSubtitle = flVideoController.subtitle!.getByPosition(controller.value.position);
    if (currentSubtitle.isEmpty) {
      return const SizedBox();
    }
    if (flVideoController.subtitleBuilder != null) {
      return flVideoController.subtitleBuilder!(context, currentSubtitle.first!.text);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        currentSubtitle.first!.text,
        style: TextStyle(fontSize: 18, color: widget.color),
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// 播放 / 暂停切换。
  void playPause() {
    if (controller.value.isPlaying) {
      notifier.hideStuff = false;
      hideTimer?.cancel();
      // 走控制器包装层，便于识别“用户主动暂停”。
      flVideoController.pause();
    } else {
      cancelAndRestartHideTimer();
      if (!controller.value.isInitialized) {
        flVideoController.initialize().then((_) {
          if (mounted && controller.value.isInitialized) flVideoController.play();
        });
      } else {
        if (latestValue.isCompleted) controller.seekTo(const Duration());
        flVideoController.play();
      }
    }
    setState(() {});
  }

  /// 双击画面切换播放 / 暂停。
  void handleDoubleTap() {
    widget.onTap?.call(FlVideoTapEvent.largePlayPause, flVideoController);
    playPause();
  }

  /// 切换全屏：先隐藏控制面板，切换完成后重新显示。
  void handleFullscreen() {
    widget.onTap?.call(FlVideoTapEvent.fullscreen, flVideoController);
    notifier.hideStuff = true;
    flVideoController.toggleFullScreen();
    _expandCollapseTimer?.cancel();
    _expandCollapseTimer = Timer(const Duration(milliseconds: 300), () {
      cancelAndRestartHideTimer();
      setState(() {});
    });
    setState(() {});
  }

  /// 切换字幕开关。
  void toggleSubtitle() {
    widget.onTap?.call(FlVideoTapEvent.subtitle, flVideoController);
    subtitleOn = !subtitleOn;
    setState(() {});
  }

  /// 静音 / 取消静音（恢复到静音前的音量）。
  void toggleMute() {
    widget.onTap?.call(FlVideoTapEvent.volume, flVideoController);
    cancelAndRestartHideTimer();
    if (latestValue.volume == 0) {
      controller.setVolume(latestVolume ?? 1.0);
    } else {
      latestVolume = controller.value.volume;
      controller.setVolume(0.0);
    }
  }

  /// 点击倍速按钮：上报事件、暂停自动隐藏，展示弹窗后按需恢复计时。
  Future<void> onSpeedPressed() async {
    widget.onTap?.call(FlVideoTapEvent.speed, flVideoController);
    hideTimer?.cancel();
    await showSpeedDialog();
    if (!mounted) return;
    if (latestValue.isPlaying) startHideTimer();
  }

  /// 展示倍速弹窗，具体样式由各面板实现。
  Future<void> showSpeedDialog();

  /// 优先使用完全自定义的 `onSelect` 选择倍速；返回 true 表示已处理（含取消）。
  Future<bool> applyCustomSpeedSelect() async {
    final FlVideoSpeedConfig? config = widget.speedConfig;
    if (config?.onSelect == null) return false;
    final double? speed = await config!.onSelect!(context, widget.playbackSpeeds, latestValue.playbackSpeed);
    applySelectedSpeed(speed);
    return true;
  }

  /// 应用弹窗返回的倍速；为空表示取消。
  void applySelectedSpeed(double? speed) {
    if (speed != null && mounted) controller.setPlaybackSpeed(speed);
  }

  /// 取消并重新开始自动隐藏计时，同时显示控制面板。
  void cancelAndRestartHideTimer() {
    hideTimer?.cancel();
    notifier.hideStuff = false;
    startHideTimer();
    setState(() {});
  }

  /// 按 [FlControlsWidget.hideDuration] 启动自动隐藏计时。
  void startHideTimer() {
    hideTimer = Timer(widget.hideDuration, () {
      notifier.hideStuff = true;
      setState(() {});
    });
  }

  /// 播放器状态变化：仅在影响可见状态时重建。
  void updateState() {
    if (!mounted) return;
    // 字幕列表被整体替换时，按新列表是否有内容自动开关字幕。
    final FlSubtitles? subtitle = flVideoController.subtitle;
    final bool subtitleChanged = !identical(subtitle, _knownSubtitle);
    if (subtitleChanged) {
      _knownSubtitle = subtitle;
      subtitleOn = widget.subtitleOn ?? (subtitle?.isNotEmpty ?? false);
    }
    final VideoPlayerValue next = controller.value;
    final bool fullScreen = flVideoController.isFullScreen;
    final bool live = isLive;
    // 进度与字幕由各自的动画组件刷新，这里只在其余可见状态变化时重建。
    final bool needsRebuild =
        subtitleChanged ||
        fullScreen != _latestFullScreen ||
        live != _latestIsLive ||
        next.isPlaying != latestValue.isPlaying ||
        next.isBuffering != latestValue.isBuffering ||
        next.isInitialized != latestValue.isInitialized ||
        next.hasError != latestValue.hasError ||
        next.isCompleted != latestValue.isCompleted ||
        next.volume != latestValue.volume ||
        next.duration != latestValue.duration ||
        next.playbackSpeed != latestValue.playbackSpeed;
    latestValue = next;
    _latestFullScreen = fullScreen;
    _latestIsLive = live;
    if (needsRebuild) setState(() {});
  }
}

/// 带内边距的可点击图标 / 组件（内部使用）。
class FlGestureDetectorIcon extends StatelessWidget {
  const FlGestureDetectorIcon({
    super.key,
    this.icon,
    this.onTap,
    this.child,
    this.color,
    this.iconSize,
    this.isStartLeft = true,
    this.isFirst = false,
    this.addBackdropFilter = false,
    this.backgroundColor,
    this.semanticsLabel,
  }) : assert(child != null || icon != null, '至少需要提供 icon 或 child 之一');

  /// 图标；[child] 为空时显示。
  final IconData? icon;

  /// 图标尺寸；为空时使用主题尺寸。
  final double? iconSize;

  /// 点击回调。
  final GestureTapCallback? onTap;

  /// 自定义内容；为空时显示 [icon]。
  final Widget? child;

  /// 图标颜色。
  final Color? color;

  /// 是否位于左侧（决定内边距方向）。
  final bool isStartLeft;

  /// 是否为第一个元素（贴边时不加内边距）。
  final bool isFirst;

  /// 是否给内容加半透明背景。
  final bool addBackdropFilter;

  /// 背景色，仅 [addBackdropFilter] 为 true 时生效。
  final Color? backgroundColor;

  /// 供读屏使用的按钮说明。
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    double left = 6;
    double right = 6;
    if (isStartLeft) {
      if (isFirst) left = 0;
    } else {
      if (isFirst) right = 0;
    }
    Widget content =
        child ??
        Padding(
          padding: EdgeInsets.only(left: left, right: right, bottom: 4, top: 4),
          child: Icon(icon!, size: iconSize, color: color),
        );
    if (addBackdropFilter) {
      content = DecoratedBox(
        decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(6)),
        child: content,
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: semanticsLabel == null ? content : Semantics(button: true, label: semanticsLabel, child: content),
    );
  }
}
