import 'package:fl_video/fl_video.dart';
import 'package:fl_video/src/controls/controls_base.dart';
import 'package:fl_video/src/extension.dart';
import 'package:material_ui/material_ui.dart';

/// Material 风格的控制面板。
class FlMaterialControls extends FlControlsWidget {
  FlMaterialControls({
    super.key,
    this.progressColors = const FlVideoPlayerProgressColors(
      played: Color(0x80FFFFFF),
      handle: Color(0xFFFFFFFF),
      buffered: Color(0x55FFFFFF),
      background: Color(0x35FFFFFF),
    ),
    this.subtitleON = Icons.closed_caption,
    this.subtitleOFF = Icons.closed_caption_off_outlined,
    this.fullscreenON = Icons.fullscreen,
    this.fullscreenOFF = Icons.fullscreen_exit,
    this.volumeON = Icons.volume_up,
    this.volumeOFF = Icons.volume_off,
    this.error = Icons.error,
    this.backgroundColor = const Color(0x90000000),
    this.color = const Color(0xFFFFFFFF),
    this.hideDuration = const Duration(seconds: 4),
    this.enableSubtitle = true,
    this.subtitleOn,
    this.enableSpeed = true,
    this.enableFullscreen = true,
    this.enableVolume = true,
    this.enablePlay = true,
    this.enableDoubleTap = false,
    this.enablePosition = true,
    this.enableBottomBar = true,
    this.isLive = false,
    this.liveBuilder,
    this.playbackSpeeds = const [0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2],
    this.speedConfig,
    this.speedLabelBuilder,
    this.speedTitle = 'Playback Speed',
    this.loading = const CircularProgressIndicator(color: Colors.white),
    this.positionBuilder,
    this.errorBuilder,
    this.onTap,
    this.onDragProgress,
  }) : assert(playbackSpeeds.every((speed) => speed > 0), 'The playbackSpeeds values must all be greater than 0');

  /// 是否显示底部控制栏。
  final bool enableBottomBar;

  /// 是否显示字幕按钮。
  final bool enableSubtitle;

  @override
  final bool? subtitleOn;

  /// 字幕开启时的图标。
  final IconData subtitleON;

  /// 字幕关闭时的图标。
  final IconData subtitleOFF;

  /// 是否显示倍速按钮。
  final bool enableSpeed;

  /// 自定义倍速按钮上展示的倍数文案；为空时使用默认格式（如 `1X`、`1.5X`）。
  final FlVideoSpeedLabelBuilder? speedLabelBuilder;

  /// 是否显示全屏按钮。
  final bool enableFullscreen;

  /// 进入全屏的图标。
  final IconData fullscreenON;

  /// 退出全屏的图标。
  final IconData fullscreenOFF;

  /// 是否显示音量按钮。
  final bool enableVolume;

  /// 有声图标。
  final IconData volumeON;

  /// 静音图标。
  final IconData volumeOFF;

  @override
  final IconData error;

  /// 是否显示播放/暂停按钮。
  final bool enablePlay;

  @override
  final bool enableDoubleTap;

  /// 是否显示播放位置文本。
  final bool enablePosition;

  /// 自定义播放位置文本。
  final FlVideoPositionAndAllBuilder? positionBuilder;

  @override
  final bool isLive;

  /// 自定义直播标识；为空时显示默认的 LIVE 文本。
  final WidgetBuilder? liveBuilder;

  /// 进度条配色。
  final FlVideoPlayerProgressColors progressColors;

  @override
  final Color color;

  /// 圆形按钮与底部栏的背景色。
  final Color backgroundColor;

  @override
  final Duration hideDuration;

  @override
  final Widget loading;

  @override
  final List<double> playbackSpeeds;

  @override
  final FlVideoSpeedConfig? speedConfig;

  /// 内置倍速弹窗的标题；自定义弹窗内容时无效。
  final String speedTitle;

  @override
  final FlVideoControlsErrorBuilder? errorBuilder;

  @override
  final FlVideoControlsTap? onTap;

  /// 拖动进度条开始/结束时回调。
  final FlVideoControlsProgressDrag? onDragProgress;

  @override
  State<FlMaterialControls> createState() => _MaterialControlsState();
}

class _MaterialControlsState extends FlControlsState<FlMaterialControls> {
  /// 是否已通过点击画面切换过控制面板显隐，决定下一次点击是显示还是隐藏。
  bool _displayTapped = false;

  /// 点击控制面板时同时复位「点击切换显隐」的状态。
  @override
  void cancelAndRestartHideTimer() {
    _displayTapped = true;
    super.cancelAndRestartHideTimer();
  }

  @override
  Widget build(BuildContext context) {
    if (latestValue.hasError) {
      return buildError();
    }

    return buildTapShell(
      Universal(
        absorbing: notifier.hideStuff,
        isStack: true,
        children: [
          _buildHitArea(),
          Universal(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (subtitleOn && widget.enableSubtitle && flVideoController.subtitle != null)
                AnimatedBuilder(
                  animation: controller,
                  builder: (BuildContext context, Widget? child) => buildSubtitles(),
                ),
              if (widget.enableBottomBar)
                AnimatedOpacity(
                  opacity: notifier.hideStuff ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: _buildBottomBar(),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() => Universal(
    mainAxisSize: MainAxisSize.min,
    bottom: flVideoController.isFullScreen,
    children: [
      if (!isLive)
        SizedBox(
          width: double.infinity,
          child: _MaterialVideoProgressBar(
            controller,
            onDragStart: () {
              widget.onDragProgress?.call(FlVideoDragProgressEvent.start, latestValue.position);
              dragging = true;
              setState(() {});
              hideTimer?.cancel();
            },
            onDragEnd: () {
              widget.onDragProgress?.call(FlVideoDragProgressEvent.end, latestValue.position);
              dragging = false;
              setState(() {});
              startHideTimer();
            },
            onTap: () {
              widget.onTap?.call(FlVideoTapEvent.progress, flVideoController);
            },
            colors: widget.progressColors,
          ),
        ),
      Row(
        children: [
          if (widget.enablePlay) _buildPlayPause(),
          if (widget.enableVolume) _buildVolume(),
          if (widget.enablePosition)
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: isLive
                    ? widget.liveBuilder?.call(context) ?? Text('LIVE', style: TextStyle(color: widget.color))
                    : AnimatedBuilder(
                        animation: controller,
                        builder: (BuildContext context, Widget? child) => _buildPosition(),
                      ),
              ),
            )
          else
            const Spacer(),
          if (widget.enableSpeed) _buildPlaybackSpeed(),
          if (widget.enableSubtitle) _buildSubtitle(),
          if (widget.enableFullscreen) _buildFullscreenButton(),
        ],
      ),
    ],
  );

  FlGestureDetectorIcon _buildSubtitle() => FlGestureDetectorIcon(
    onTap: toggleSubtitle,
    isStartLeft: false,
    isFirst: !widget.enableFullscreen,
    iconSize: 22,
    color: widget.color,
    icon: subtitleOn ? widget.subtitleON : widget.subtitleOFF,
    semanticsLabel: subtitleOn ? 'Hide subtitles' : 'Show subtitles',
  );

  FlGestureDetectorIcon _buildPlaybackSpeed() => FlGestureDetectorIcon(
    isStartLeft: false,
    color: widget.color,
    isFirst: !widget.enableFullscreen && !widget.enableSubtitle,
    semanticsLabel: 'Playback speed',
    onTap: onSpeedPressed,
    // 直接展示当前倍数，例如 1X、1.5X，选择后自动回显。
    child: _buildSpeedLabel(),
  );

  /// 倍速按钮文案。
  Widget _buildSpeedLabel() {
    final double speed = latestValue.playbackSpeed;
    final String label = widget.speedLabelBuilder?.call(speed) ?? speed.formatPlaybackSpeed();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        label,
        style: TextStyle(color: widget.color, fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  @override
  Future<void> showSpeedDialog() async {
    if (await applyCustomSpeedSelect() || !mounted) return;
    final FlVideoSpeedConfig? config = widget.speedConfig;
    final double selected = latestValue.playbackSpeed;
    final double? speed = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      // 弹窗自带圆角与背景，外层保持透明避免出现双层底色。
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (BuildContext sheetContext) {
        return config?.contentBuilder?.call(
              sheetContext,
              widget.playbackSpeeds,
              selected,
              (double value) => Navigator.of(sheetContext).pop(value),
            ) ??
            FlPlaybackSpeedDialog(
              title: widget.speedTitle,
              speeds: widget.playbackSpeeds,
              selected: selected,
              onSelected: (double value) => Navigator.of(sheetContext).pop(value),
            );
      },
    );
    applySelectedSpeed(speed);
  }

  FlGestureDetectorIcon _buildFullscreenButton() => FlGestureDetectorIcon(
    onTap: handleFullscreen,
    isStartLeft: false,
    isFirst: true,
    iconSize: 22,
    color: widget.color,
    icon: flVideoController.isFullScreen ? widget.fullscreenOFF : widget.fullscreenON,
    semanticsLabel: flVideoController.isFullScreen ? 'Exit fullscreen' : 'Enter fullscreen',
  );

  Widget _buildHitArea() {
    if (latestValue.isBuffering && !latestValue.isPlaying) {
      Widget loading = widget.loading;
      if (widget.onTap != null) {
        loading = loading.onTap(() {
          widget.onTap!(FlVideoTapEvent.loading, flVideoController);
        });
      }
      return Center(
        child: Semantics(label: 'Loading', child: loading),
      );
    }
    return FlGestureDetectorIcon(
      onTap: () {
        if (latestValue.isPlaying) {
          if (_displayTapped) {
            notifier.hideStuff = true;
            // 复位后，下一次点击会重新显示控制面板。
            _displayTapped = false;
            setState(() {});
          } else {
            cancelAndRestartHideTimer();
          }
        } else {
          playPause();
          notifier.hideStuff = true;
          _displayTapped = false;
          setState(() {});
        }
      },
      child: FlCenterPlayButton(
        backgroundColor: widget.backgroundColor,
        iconColor: widget.color,
        isFinished: latestValue.isCompleted,
        isPlaying: controller.value.isPlaying,
        show: !latestValue.isPlaying && !dragging,
        onPressed: () {
          widget.onTap?.call(FlVideoTapEvent.largePlayPause, flVideoController);
          playPause();
        },
      ),
    );
  }

  FlGestureDetectorIcon _buildVolume() => FlGestureDetectorIcon(
    onTap: toggleMute,
    isFirst: !widget.enablePlay,
    iconSize: 22,
    color: widget.color,
    icon: latestValue.volume > 0 ? widget.volumeON : widget.volumeOFF,
    semanticsLabel: latestValue.volume > 0 ? 'Mute' : 'Unmute',
  );

  FlGestureDetectorIcon _buildPlayPause() => FlGestureDetectorIcon(
    onTap: () {
      widget.onTap?.call(FlVideoTapEvent.playPause, flVideoController);
      playPause();
    },
    semanticsLabel: controller.value.isPlaying ? 'Pause' : 'Play',
    child: FlAnimatedPlayPause(playing: controller.value.isPlaying, color: widget.color),
  );

  Widget _buildPosition() {
    final VideoPlayerValue value = controller.value;
    final duration = value.duration;
    final position = value.position;
    if (widget.positionBuilder != null) {
      return widget.positionBuilder!(position.formatDuration(), duration.formatDuration());
    }
    Widget text = Text(
      '${position.formatDuration()} / ${duration.formatDuration()}',
      style: TextStyle(fontSize: 14.0, color: widget.color),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    if (!widget.enableVolume) {
      text = Padding(
        padding: EdgeInsets.only(left: widget.enablePlay ? 6 : 0),
        child: text,
      );
    }
    if (widget.onTap != null) {
      return text.onTap(() {
        widget.onTap!(FlVideoTapEvent.position, flVideoController);
      });
    }
    return text;
  }
}

/// Material 风格的细进度条（内部使用）。
class _MaterialVideoProgressBar extends FlVideoProgressBar {
  const _MaterialVideoProgressBar(super.controller, {super.colors, super.onDragStart, super.onDragEnd, super.onTap})
    : super(barHeight: 3, handleHeight: 6, drawShadow: false);
}
