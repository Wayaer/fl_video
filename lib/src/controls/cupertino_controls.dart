import 'dart:math' as math;

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:fl_video/fl_video.dart';
import 'package:fl_video/src/controls/controls_base.dart';
import 'package:fl_video/src/extension.dart';
import 'package:material_ui/material_ui.dart';

/// Cupertino 风格的控制面板。
class FlCupertinoControls extends FlControlsWidget {
  FlCupertinoControls({
    super.key,
    this.hideDuration = const Duration(seconds: 4),
    this.backgroundColor = const Color(0x90000000),
    this.color = const Color(0xFFFFFFFF),
    this.isLive = false,
    this.subtitleON = CupertinoIcons.captions_bubble_fill,
    this.subtitleOFF = CupertinoIcons.captions_bubble,
    this.fullscreenON = CupertinoIcons.arrow_up_left_arrow_down_right,
    this.fullscreenOFF = CupertinoIcons.arrow_down_right_arrow_up_left,
    this.volumeON = CupertinoIcons.speaker_2_fill,
    this.volumeOFF = CupertinoIcons.speaker_slash_fill,
    this.error = CupertinoIcons.exclamationmark_circle,
    this.skipForward = CupertinoIcons.goforward_15,
    this.skipBack = CupertinoIcons.gobackward_15,
    this.skipDuration = const Duration(seconds: 15),
    this.enableSubtitle = true,
    this.subtitleOn,
    this.enableSpeed = true,
    this.enableSkip = true,
    this.enableFullscreen = true,
    this.enableVolume = true,
    this.enablePlay = true,
    this.enableDoubleTap = false,
    this.enablePosition = true,
    this.enableRemaining = true,
    this.positionBuilder,
    this.remainingBuilder,
    this.liveBuilder,
    this.progressColors = const FlVideoPlayerProgressColors(
      played: Color(0x78ffffff),
      handle: Color(0xffffffff),
      buffered: Color(0x3cffffff),
      background: Color(0x14ffffff),
    ),
    this.playbackSpeeds = const [0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2],
    this.speedConfig,
    this.speedLabelBuilder,
    this.speedTitle = 'Playback Speed',
    this.speedCancelLabel,
    this.loading = const CircularProgressIndicator(color: Colors.white),
    this.errorBuilder,
    this.onTap,
    this.onDragProgress,
    this.enableBottomBar = true,
  }) : assert(playbackSpeeds.every((speed) => speed > 0), 'The playbackSpeeds values must all be greater than 0'),
       assert(skipDuration > Duration.zero, 'The skipDuration must be greater than 0');

  /// 进度条配色。
  final FlVideoPlayerProgressColors progressColors;

  /// 圆形按钮与底部栏的背景色。
  final Color backgroundColor;

  @override
  final Color color;

  @override
  final bool isLive;

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

  /// 自定义倍速按钮上展示的倍数文案；为空时使用默认格式（如 `1x`、`1.5x`）。
  final FlVideoSpeedLabelBuilder? speedLabelBuilder;

  /// 是否显示快退/快进按钮。
  final bool enableSkip;

  /// 前进按钮图标。
  final IconData skipForward;

  /// 后退按钮图标。
  final IconData skipBack;

  /// 快进/快退的跳转时长，默认 15 秒；修改后请同步替换 [skipForward]/[skipBack] 图标。
  final Duration skipDuration;

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

  @override
  final Duration hideDuration;

  @override
  final Widget loading;

  /// 是否显示当前位置文本。
  final bool enablePosition;

  /// 自定义当前位置文本。
  final FlVideoPositionBuilder? positionBuilder;

  /// 是否显示剩余时间文本。
  final bool enableRemaining;

  /// 自定义剩余时间文本。
  final FlVideoRemainingBuilder? remainingBuilder;

  /// 自定义直播标识；为空时显示默认的 LIVE 文本。
  final WidgetBuilder? liveBuilder;

  @override
  final List<double> playbackSpeeds;

  @override
  final FlVideoSpeedConfig? speedConfig;

  /// 内置倍速弹窗的标题；自定义弹窗内容时无效。
  final String speedTitle;

  /// 内置 iOS 倍速操作表的取消按钮文案；为空时使用系统本地化文案（如 `Cancel`、`取消`）。
  final String? speedCancelLabel;

  @override
  final FlVideoControlsErrorBuilder? errorBuilder;

  @override
  final FlVideoControlsTap? onTap;

  /// 拖动进度条开始/结束时回调。
  final FlVideoControlsProgressDrag? onDragProgress;

  @override
  State<FlCupertinoControls> createState() => _CupertinoControlsState();
}

class _CupertinoControlsState extends FlControlsState<FlCupertinoControls> {
  /// 控制栏里除时间文本外的最小占位（跳转、播放、字幕、倍速按钮与进度条内边距）。
  static const double _controlRowReservedWidth = 240;

  @override
  Widget build(BuildContext context) {
    if (latestValue.hasError) {
      return buildError();
    }

    return buildTapShell(
      Universal(
        isStack: true,
        absorbing: notifier.hideStuff,
        children: [
          _buildHitArea(),
          Universal(
            padding: const EdgeInsets.all(12.0),
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnimatedOpacity(
                opacity: notifier.hideStuff ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [_buildFullscreen(), if (widget.enableVolume) _buildVolume()],
                ),
              ),
              const Spacer(),
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
    bottom: flVideoController.isFullScreen,
    decoration: BoxDecoration(color: widget.backgroundColor, borderRadius: BorderRadius.circular(10)),
    child: isLive
        ? Universal(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            direction: Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [_buildPlayPause(), _buildLive()],
          )
        : _buildControlRow(),
  );

  /// 普通播放的控制栏。
  ///
  /// 两侧时间文本最多各占「整行宽度减去按钮与进度条占位」后的一半，超长时由文本自己省略，
  /// 这样窄屏、大字体或自定义了较宽的时间组件时都不会把整行撑破。
  Widget _buildControlRow() => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      final double maxTimeTextWidth = math.max(32, (constraints.maxWidth - _controlRowReservedWidth) / 2);
      final Widget position = AnimatedBuilder(
        animation: controller,
        builder: (BuildContext context, Widget? child) => _buildPosition(),
      );
      final Widget remaining = AnimatedBuilder(
        animation: controller,
        builder: (BuildContext context, Widget? child) => _buildRemaining(),
      );
      return Row(
        children: <Widget>[
          if (widget.enableSkip) _buildSkipBack(),
          if (widget.enablePlay) _buildPlayPause(),
          if (widget.enableSkip) _buildSkipForward(),
          if (widget.enablePosition)
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxTimeTextWidth),
              child: position,
            ),
          Expanded(child: _buildProgressBar()),
          if (widget.enableRemaining)
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxTimeTextWidth),
              child: remaining,
            ),
          if (widget.enableSubtitle) _buildSubtitleToggle(),
          if (widget.enableSpeed) _buildSpeed(),
        ],
      );
    },
  );

  Widget _buildLive() =>
      widget.liveBuilder?.call(context) ?? Text('LIVE', style: TextStyle(color: widget.color, fontSize: 12.0));

  Widget _buildFullscreen() => widget.enableFullscreen
      ? FlGestureDetectorIcon(
          onTap: handleFullscreen,
          addBackdropFilter: true,
          backgroundColor: widget.backgroundColor,
          icon: flVideoController.isFullScreen ? widget.fullscreenOFF : widget.fullscreenON,
          color: widget.color,
          semanticsLabel: flVideoController.isFullScreen ? 'Exit fullscreen' : 'Enter fullscreen',
        )
      : const SizedBox();

  FlGestureDetectorIcon _buildVolume() => FlGestureDetectorIcon(
    addBackdropFilter: true,
    backgroundColor: widget.backgroundColor,
    onTap: toggleMute,
    icon: latestValue.volume > 0 ? widget.volumeON : widget.volumeOFF,
    color: widget.color,
    semanticsLabel: latestValue.volume > 0 ? 'Mute' : 'Unmute',
  );

  /// 中间暂停播放
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
      onTap: latestValue.isPlaying
          ? cancelAndRestartHideTimer
          : () {
              hideTimer?.cancel();
              notifier.hideStuff = false;
              setState(() {});
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

  FlGestureDetectorIcon _buildPlayPause() => FlGestureDetectorIcon(
    onTap: () {
      widget.onTap?.call(FlVideoTapEvent.playPause, flVideoController);
      playPause();
    },
    semanticsLabel: controller.value.isPlaying ? 'Pause' : 'Play',
    child: Padding(
      padding: const EdgeInsets.all(4),
      child: FlAnimatedPlayPause(color: widget.color, playing: controller.value.isPlaying),
    ),
  );

  Widget _buildPosition() {
    final position = controller.value.position;
    if (widget.positionBuilder != null) {
      return widget.positionBuilder!(position.formatDuration());
    }
    Widget text = Padding(
      padding: const EdgeInsets.only(left: 6, top: 8, bottom: 8),
      child: Text(
        position.formatDuration(),
        style: TextStyle(color: widget.color, fontSize: 12.0),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
    if (widget.onTap != null) {
      return text.onTap(() {
        widget.onTap!(FlVideoTapEvent.position, flVideoController);
      });
    }
    return text;
  }

  Widget _buildRemaining() {
    final remaining = controller.value.duration - controller.value.position;
    if (widget.remainingBuilder != null) {
      return widget.remainingBuilder!(remaining.formatDuration());
    }
    Widget text = Padding(
      padding: const EdgeInsets.only(right: 6, top: 8, bottom: 8),
      child: Text(
        '-${remaining.formatDuration()}',
        style: TextStyle(color: widget.color, fontSize: 12.0),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
    if (widget.onTap != null) {
      return text.onTap(() {
        widget.onTap!(FlVideoTapEvent.remaining, flVideoController);
      });
    }
    return text;
  }

  FlGestureDetectorIcon _buildSkipBack() => FlGestureDetectorIcon(
    onTap: () {
      widget.onTap?.call(FlVideoTapEvent.skipBack, flVideoController);
      cancelAndRestartHideTimer();
      final beginning = const Duration().inMilliseconds;
      final skip = (latestValue.position - widget.skipDuration).inMilliseconds;
      controller.seekTo(Duration(milliseconds: math.max(skip, beginning)));
    },
    icon: widget.skipBack,
    color: widget.color,
    semanticsLabel: 'Rewind',
  );

  FlGestureDetectorIcon _buildSkipForward() => FlGestureDetectorIcon(
    onTap: () {
      widget.onTap?.call(FlVideoTapEvent.skipForward, flVideoController);
      cancelAndRestartHideTimer();
      final end = latestValue.duration.inMilliseconds;
      final skip = (latestValue.position + widget.skipDuration).inMilliseconds;
      controller.seekTo(Duration(milliseconds: math.min(skip, end)));
    },
    icon: widget.skipForward,
    color: widget.color,
    semanticsLabel: 'Fast forward',
  );

  FlGestureDetectorIcon _buildSubtitleToggle() => FlGestureDetectorIcon(
    onTap: toggleSubtitle,
    icon: subtitleOn ? widget.subtitleON : widget.subtitleOFF,
    color: widget.color,
    semanticsLabel: subtitleOn ? 'Hide subtitles' : 'Show subtitles',
  );

  FlGestureDetectorIcon _buildSpeed() => FlGestureDetectorIcon(
    onTap: onSpeedPressed,
    color: widget.color,
    semanticsLabel: 'Playback speed',
    // 直接展示当前倍数，iOS 风格用小写 x（如 1x），选择后自动回显。
    child: _buildSpeedLabel(),
  );

  /// 倍速按钮文案；iOS 风格使用小写 x，例如 `1x`、`1.5x`。
  Widget _buildSpeedLabel() {
    final double speed = latestValue.playbackSpeed;
    final String label = widget.speedLabelBuilder?.call(speed) ?? speed.formatPlaybackSpeed(suffix: 'x');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Text(
        label,
        style: TextStyle(color: widget.color, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  @override
  Future<void> showSpeedDialog() async {
    if (await applyCustomSpeedSelect() || !mounted) return;
    final FlVideoSpeedConfig? config = widget.speedConfig;
    final double selected = latestValue.playbackSpeed;
    final double? speed = await showCupertinoModalPopup<double>(
      context: context,
      semanticsDismissible: true,
      useRootNavigator: true,
      builder: (BuildContext sheetContext) {
        return config?.contentBuilder?.call(
              sheetContext,
              widget.playbackSpeeds,
              selected,
              (double value) => Navigator.of(sheetContext).pop(value),
            ) ??
            // iOS 风格：底部操作表列出所有倍数，当前倍数带勾选。
            _CupertinoPlaybackSpeedSheet(
              title: widget.speedTitle,
              cancelLabel: widget.speedCancelLabel,
              speeds: widget.playbackSpeeds,
              selected: selected,
              onSelected: (double value) => Navigator.of(sheetContext).pop(value),
            );
      },
    );
    applySelectedSpeed(speed);
  }

  Widget _buildProgressBar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12.0),
    child: _CupertinoVideoProgressBar(
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
  );
}

/// Cupertino 风格的倍速选择操作表（内部使用）：列出所有倍数，当前倍数带勾选。
class _CupertinoPlaybackSpeedSheet extends StatelessWidget {
  const _CupertinoPlaybackSpeedSheet({
    required this.title,
    required this.speeds,
    required this.selected,
    required this.onSelected,
    this.cancelLabel,
  });

  /// 操作表标题。
  final String title;

  /// 取消按钮文案；为空时使用系统本地化文案。
  final String? cancelLabel;

  /// 可选倍数。
  final List<double> speeds;

  /// 当前选中的倍数。
  final double selected;

  /// 选择倍数回调。
  final ValueChanged<double> onSelected;

  @override
  Widget build(BuildContext context) {
    final Color selectedColor = CupertinoTheme.of(context).primaryColor;
    return CupertinoActionSheet(
      title: Text(title),
      actions: [
        for (final double speed in speeds)
          CupertinoActionSheetAction(
            onPressed: () => onSelected(speed),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (speed == selected) Icon(CupertinoIcons.check_mark, size: 20, color: selectedColor),
                Text(speed.formatPlaybackSpeed(suffix: 'x')),
              ],
            ),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(
        isDefaultAction: true,
        onPressed: () => Navigator.of(context).pop(),
        child: Text(cancelLabel ?? CupertinoLocalizations.of(context).cancelButtonLabel),
      ),
    );
  }
}

/// Cupertino 风格的粗进度条（内部使用）。
class _CupertinoVideoProgressBar extends FlVideoProgressBar {
  const _CupertinoVideoProgressBar(super.controller, {super.colors, super.onDragStart, super.onDragEnd, super.onTap})
    : super(barHeight: 5, handleHeight: 6, drawShadow: true);
}
