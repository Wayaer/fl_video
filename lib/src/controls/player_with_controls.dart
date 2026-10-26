import 'dart:async';

import 'package:fl_video/fl_video.dart';
import 'package:fl_video/src/extension.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

/// 控制面板显隐状态；仅供内置控制面板使用。
class FlPlayerNotifier extends ChangeNotifier {
  FlPlayerNotifier._(bool hideStuff) : _hideStuff = hideStuff;

  bool _hideStuff;

  /// 是否隐藏控制面板。
  bool get hideStuff => _hideStuff;

  set hideStuff(bool value) {
    if (_hideStuff == value) return;
    _hideStuff = value;
    notifyListeners();
  }

  /// 创建初始为隐藏状态的通知器。
  static FlPlayerNotifier get init => FlPlayerNotifier._(true);
}

/// 可点击、可拖动的视频进度条。
class FlVideoProgressBar extends StatefulWidget {
  const FlVideoProgressBar(
    this.controller, {
    this.colors = const FlVideoPlayerProgressColors(),
    this.onDragEnd,
    this.onDragStart,
    this.onTap,
    super.key,
    required this.barHeight,
    required this.handleHeight,
    required this.drawShadow,
  });

  /// 底层视频控制器。
  final VideoPlayerController controller;

  /// 进度条配色。
  final FlVideoPlayerProgressColors colors;

  /// 拖动开始回调。
  final Function()? onDragStart;

  /// 拖动结束或取消时的回调。
  final Function()? onDragEnd;

  /// 点击进度条并完成跳转后的回调。
  final Function()? onTap;

  /// 进度条高度。
  final double barHeight;

  /// 拖动手柄半径。
  final double handleHeight;

  /// 是否给拖动手柄绘制阴影。
  final bool drawShadow;

  @override
  State<FlVideoProgressBar> createState() => _VideoProgressBarState();
}

class _VideoProgressBarState extends State<FlVideoProgressBar> {
  /// 拖动过程中应用 seek 的最小间隔，避免高频拖动时疯狂调用平台 seek。
  static const Duration _seekInterval = Duration(milliseconds: 60);

  bool _controllerWasPlaying = false;

  /// 待应用的拖动位置，配合 [_seekTimer] 做节流。
  Offset? _pendingPosition;
  Timer? _seekTimer;

  VideoPlayerController get controller => widget.controller;

  /// 根据点击/拖动位置计算进度并跳转。
  void _seekToRelativePosition(Offset globalPosition) {
    final box = context.findRenderObject()! as RenderBox;
    final double width = box.size.width;
    // 宽度为 0 时无法换算比例，直接忽略，避免 NaN 进入 Duration 计算。
    if (width <= 0) return;
    final Offset tapPos = box.globalToLocal(globalPosition);
    final double relative = tapPos.dx / width;
    final Duration position = controller.value.duration * relative;
    controller.seekTo(position);
  }

  /// 节流后的拖动跳转：拖得再快也只按 [_seekInterval] 的频率 seek。
  void _scheduleSeek(Offset globalPosition) {
    _pendingPosition = globalPosition;
    _seekTimer ??= Timer(_seekInterval, () {
      _seekTimer = null;
      final Offset? position = _pendingPosition;
      _pendingPosition = null;
      if (position != null && mounted) _seekToRelativePosition(position);
    });
  }

  /// 立即应用尚未执行的拖动跳转。
  void _flushPendingSeek() {
    _seekTimer?.cancel();
    _seekTimer = null;
    final Offset? position = _pendingPosition;
    _pendingPosition = null;
    if (position != null && mounted) _seekToRelativePosition(position);
  }

  /// 拖动结束或被取消后，恢复拖动前的播放状态。
  void _finishDrag() {
    _flushPendingSeek();
    if (!_controllerWasPlaying) return;
    _controllerWasPlaying = false;
    controller.play();
  }

  @override
  void dispose() {
    _seekTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (DragStartDetails details) {
        if (!controller.value.isInitialized) {
          _controllerWasPlaying = false;
          return;
        }
        _controllerWasPlaying = controller.value.isPlaying;
        if (_controllerWasPlaying) {
          controller.pause();
        }
        widget.onDragStart?.call();
      },
      onHorizontalDragUpdate: (DragUpdateDetails details) {
        if (!controller.value.isInitialized) {
          return;
        }
        _scheduleSeek(details.globalPosition);
      },
      onHorizontalDragEnd: (DragEndDetails details) {
        _finishDrag();
        widget.onDragEnd?.call();
      },
      // 手势被其他识别器抢走时不会触发 end，这里同样要恢复播放并通知拖拽结束。
      onHorizontalDragCancel: () {
        _finishDrag();
        widget.onDragEnd?.call();
      },
      onTapDown: (TapDownDetails details) {
        if (!controller.value.isInitialized) {
          return;
        }
        _seekToRelativePosition(details.globalPosition);
        widget.onTap?.call();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        // 自行监听播放器，避免依赖控制面板整体重建来刷新进度。
        child: AnimatedBuilder(
          animation: controller,
          builder: (BuildContext context, Widget? child) => CustomPaint(
            // 给绘制盒一个明确的条高：否则高度为 0，进度条只能靠溢出绘制，
            // 可见位置与命中区域会错位，父级一旦裁剪还会被裁掉。
            size: Size.fromHeight(widget.barHeight),
            painter: _ProgressBarPainter(
              value: controller.value,
              colors: widget.colors,
              barHeight: widget.barHeight,
              handleHeight: widget.handleHeight,
              drawShadow: widget.drawShadow,
            ),
          ),
        ),
      ),
    );
  }
}

/// 进度条绘制器（内部使用）。
class _ProgressBarPainter extends CustomPainter {
  _ProgressBarPainter({
    required this.value,
    required this.colors,
    required this.barHeight,
    required this.handleHeight,
    required this.drawShadow,
  });

  final VideoPlayerValue value;
  final FlVideoPlayerProgressColors colors;

  final double barHeight;
  final double handleHeight;
  final bool drawShadow;

  @override
  bool shouldRepaint(_ProgressBarPainter oldDelegate) {
    return value.isInitialized != oldDelegate.value.isInitialized ||
        value.position != oldDelegate.value.position ||
        value.duration != oldDelegate.value.duration ||
        !listEquals(value.buffered, oldDelegate.value.buffered) ||
        colors.played != oldDelegate.colors.played ||
        colors.handle != oldDelegate.colors.handle ||
        colors.buffered != oldDelegate.colors.buffered ||
        colors.background != oldDelegate.colors.background ||
        barHeight != oldDelegate.barHeight ||
        handleHeight != oldDelegate.handleHeight ||
        drawShadow != oldDelegate.drawShadow;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final baseOffset = size.height / 2 - barHeight / 2;
    Paint point = Paint();
    point.color = colors.background;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(Offset(0.0, baseOffset), Offset(size.width, baseOffset + barHeight)),
        const Radius.circular(4.0),
      ),
      point,
    );
    if (!value.isInitialized) return;
    final int durationMs = value.duration.inMilliseconds;
    final double playedPartPercent = durationMs <= 0 ? 0 : value.position.inMilliseconds / durationMs;
    final double playedPart = playedPartPercent > 1 ? size.width : playedPartPercent * size.width;
    // 时长未知（如直播）时无法计算缓冲区间比例，避免 NaN 进入绘制。
    if (durationMs > 0) {
      for (final DurationRange range in value.buffered) {
        final double start = range.startFraction(value.duration) * size.width;
        final double end = range.endFraction(value.duration) * size.width;
        point.color = colors.buffered;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromPoints(Offset(start, baseOffset), Offset(end, baseOffset + barHeight)),
            const Radius.circular(4.0),
          ),
          point,
        );
      }
    }
    point.color = colors.played;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(Offset(0.0, baseOffset), Offset(playedPart, baseOffset + barHeight)),
        const Radius.circular(4.0),
      ),
      point,
    );

    if (drawShadow) {
      final shadowPath = Path()
        ..addOval(Rect.fromCircle(center: Offset(playedPart, baseOffset + barHeight / 2), radius: handleHeight));
      canvas.drawShadow(shadowPath, Colors.black, 0.2, false);
    }
    point.color = colors.handle;
    canvas.drawCircle(Offset(playedPart, baseOffset + barHeight / 2), handleHeight, point);
  }
}

/// 画面中央的播放/暂停按钮。
class FlCenterPlayButton extends StatelessWidget {
  const FlCenterPlayButton({
    super.key,
    required this.backgroundColor,
    this.iconColor,
    required this.show,
    required this.isPlaying,
    required this.isFinished,
    this.onPressed,
  });

  /// 圆形按钮背景色。
  final Color backgroundColor;

  /// 图标颜色。
  final Color? iconColor;

  /// 是否显示按钮；为 false 时淡出且不响应点击。
  final bool show;

  /// 是否正在播放。
  final bool isPlaying;

  /// 是否已播放完毕（显示重播图标）。
  final bool isFinished;

  /// 点击回调。
  final VoidCallback? onPressed;

  /// 供读屏使用的按钮说明。
  String get semanticLabel {
    if (isFinished) return 'Replay';
    return isPlaying ? 'Pause' : 'Play';
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: AnimatedOpacity(
        opacity: show ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: IgnorePointer(
          ignoring: !show,
          child: Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
            // 用 tooltip 提供无障碍标签，避免和 IconButton 自身的 button 语义重复。
            child: IconButton(
              iconSize: 40,
              tooltip: semanticLabel,
              icon: isFinished
                  ? Icon(Icons.replay, color: iconColor)
                  : FlAnimatedPlayPause(color: iconColor, playing: isPlaying),
              onPressed: onPressed,
            ),
          ),
        ),
      ),
    );
  }
}

/// 在播放与暂停图标之间做隐式动画的组件。
class FlAnimatedPlayPause extends StatefulWidget {
  const FlAnimatedPlayPause({super.key, required this.playing, this.size, this.color});

  /// 图标尺寸。
  final double? size;

  /// 是否处于播放状态。
  final bool playing;

  /// 图标颜色。
  final Color? color;

  @override
  State<FlAnimatedPlayPause> createState() => _AnimatedPlayPauseState();
}

class _AnimatedPlayPauseState extends State<FlAnimatedPlayPause> with SingleTickerProviderStateMixin {
  late final animationController = AnimationController(
    vsync: this,
    value: widget.playing ? 1 : 0,
    duration: const Duration(milliseconds: 400),
  );

  @override
  void didUpdateWidget(FlAnimatedPlayPause oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playing != oldWidget.playing) {
      if (widget.playing) {
        animationController.forward();
      } else {
        animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedIcon(
    color: widget.color,
    size: widget.size,
    icon: AnimatedIcons.play_pause,
    progress: animationController,
  );
}

/// 控制面板默认使用的 22 号图标。
class FlDefaultIcon extends Icon {
  const FlDefaultIcon(IconData super.icon, {double super.size = 22, super.color, super.key});
}

/// 控制面板默认的播放错误提示。
class FlDefaultError extends StatelessWidget {
  const FlDefaultError({super.key, required this.color, required this.error, this.onTap, this.semanticLabel});

  /// 图标颜色。
  final Color color;

  /// 错误图标。
  final IconData error;

  /// 点击回调。
  final GestureTapCallback? onTap;

  /// 供读屏使用的错误说明。
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    Widget icon = FlDefaultIcon(error, size: 42, color: color);
    if (onTap != null) {
      icon = icon.onTap(onTap);
    }
    return Center(
      child: Semantics(label: semanticLabel ?? 'Playback failed', child: icon),
    );
  }
}

/// 默认倍速选择弹窗内容（内部使用）：标题 + 可换行的倍速选项。
class FlPlaybackSpeedDialog extends StatelessWidget {
  const FlPlaybackSpeedDialog({
    super.key,
    required this.title,
    required this.speeds,
    required this.selected,
    required this.onSelected,
  });

  /// 弹窗标题。
  final String title;

  /// 可选倍速。
  final List<double> speeds;

  /// 当前选中的倍速。
  final double selected;

  /// 选择倍速回调。
  final ValueChanged<double> onSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 10,
                children: [
                  for (final double speed in speeds)
                    _SpeedOption(speed: speed, selected: speed == selected, onTap: () => onSelected(speed)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 单个倍速选项（内部使用）：选中时填充底色并显示对勾。
class _SpeedOption extends StatelessWidget {
  const _SpeedOption({required this.speed, required this.selected, required this.onTap});

  /// 倍速值。
  final double speed;

  /// 是否为当前倍速。
  final bool selected;

  /// 点击回调。
  final VoidCallback onTap;

  /// 整数值显示为 1.0，其余保持原样。
  String get text {
    final String value = speed == speed.truncateToDouble() ? speed.toStringAsFixed(1) : speed.toString();
    return '${value}x';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextStyle? style = theme.textTheme.labelLarge?.copyWith(
      color: selected ? scheme.onSecondaryContainer : scheme.onSurface,
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(minWidth: 58),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? scheme.secondaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? Colors.transparent : scheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (selected) ...[
              Icon(Icons.check, size: 16, color: scheme.onSecondaryContainer),
              const SizedBox(width: 4),
            ],
            Text(text, style: style),
          ],
        ),
      ),
    );
  }
}
