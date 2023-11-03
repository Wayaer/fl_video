import 'package:fl_video/fl_video.dart';
import 'package:fl_video/src/extension.dart';
import 'package:flutter/material.dart';

class PlayerNotifier extends ChangeNotifier {
  PlayerNotifier._(bool hideStuff) : _hideStuff = hideStuff;

  bool _hideStuff;

  bool get hideStuff => _hideStuff;

  set hideStuff(bool value) {
    if (_hideStuff != value) {
      _hideStuff = value;
    }
    notifyListeners();
  }

  static PlayerNotifier get init => PlayerNotifier._(true);
}

class VideoProgressBar extends StatefulWidget {
  const VideoProgressBar(
    this.controller, {
    this.colors = const FlVideoPlayerProgressColors(),
    this.onDragEnd,
    this.onDragStart,
    this.onDragUpdate,
    super.key,
    required this.barHeight,
    required this.handleHeight,
    required this.drawShadow,
  });

  final VideoPlayerController controller;
  final FlVideoPlayerProgressColors colors;
  final Function()? onDragStart;
  final Function()? onDragEnd;
  final Function()? onDragUpdate;

  final double barHeight;
  final double handleHeight;
  final bool drawShadow;

  @override
  State<VideoProgressBar> createState() => _VideoProgressBarState();
}

class _VideoProgressBarState extends State<VideoProgressBar> {
  bool _controllerWasPlaying = false;

  VideoPlayerController get controller => widget.controller;

  void _seekToRelativePosition(Offset globalPosition) {
    final box = context.findRenderObject()! as RenderBox;
    final Offset tapPos = box.globalToLocal(globalPosition);
    final double relative = tapPos.dx / box.size.width;
    final Duration position = controller.value.duration * relative;
    controller.seekTo(position);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (DragStartDetails details) {
          if (!controller.value.isInitialized) {
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
          _seekToRelativePosition(details.globalPosition);
          widget.onDragUpdate?.call();
        },
        onHorizontalDragEnd: (DragEndDetails details) {
          if (_controllerWasPlaying) {
            controller.play();
          }
          widget.onDragEnd?.call();
        },
        onTapDown: (TapDownDetails details) {
          if (!controller.value.isInitialized) {
            return;
          }
          _seekToRelativePosition(details.globalPosition);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: CustomPaint(
              painter: _ProgressBarPainter(
                  value: controller.value,
                  colors: widget.colors,
                  barHeight: widget.barHeight,
                  handleHeight: widget.handleHeight,
                  drawShadow: widget.drawShadow)),
        ));
  }
}

class _ProgressBarPainter extends CustomPainter {
  _ProgressBarPainter(
      {required this.value,
      required this.colors,
      required this.barHeight,
      required this.handleHeight,
      required this.drawShadow});

  VideoPlayerValue value;
  FlVideoPlayerProgressColors colors;

  final double barHeight;
  final double handleHeight;
  final bool drawShadow;

  @override
  bool shouldRepaint(CustomPainter painter) => true;

  @override
  void paint(Canvas canvas, Size size) {
    final baseOffset = size.height / 2 - barHeight / 2;
    Paint point = Paint();
    point.color = colors.background;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromPoints(Offset(0.0, baseOffset),
                Offset(size.width, baseOffset + barHeight)),
            const Radius.circular(4.0)),
        point);
    if (!value.isInitialized) return;
    final double playedPartPercent =
        value.position.inMilliseconds / value.duration.inMilliseconds;
    final double playedPart =
        playedPartPercent > 1 ? size.width : playedPartPercent * size.width;
    for (final DurationRange range in value.buffered) {
      final double start = range.startFraction(value.duration) * size.width;
      final double end = range.endFraction(value.duration) * size.width;
      point.color = colors.buffered;
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromPoints(Offset(start, baseOffset),
                  Offset(end, baseOffset + barHeight)),
              const Radius.circular(4.0)),
          point);
    }
    point.color = colors.played;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromPoints(Offset(0.0, baseOffset),
                Offset(playedPart, baseOffset + barHeight)),
            const Radius.circular(4.0)),
        point);

    if (drawShadow) {
      final shadowPath = Path()
        ..addOval(Rect.fromCircle(
            center: Offset(playedPart, baseOffset + barHeight / 2),
            radius: handleHeight));
      canvas.drawShadow(shadowPath, Colors.black, 0.2, false);
    }
    point.color = colors.handle;
    canvas.drawCircle(
        Offset(playedPart, baseOffset + barHeight / 2), handleHeight, point);
  }
}

class CenterPlayButton extends StatelessWidget {
  const CenterPlayButton({
    super.key,
    required this.backgroundColor,
    this.iconColor,
    required this.show,
    required this.isPlaying,
    required this.isFinished,
    this.onPressed,
  });

  final Color backgroundColor;
  final Color? iconColor;
  final bool show;
  final bool isPlaying, isFinished;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
        alignment: Alignment.center,
        child: AnimatedOpacity(
            opacity: show ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                    color: backgroundColor, shape: BoxShape.circle),
                child: IconButton(
                  iconSize: 40,
                  icon: isFinished
                      ? Icon(Icons.replay, color: iconColor)
                      : AnimatedPlayPause(color: iconColor, playing: isPlaying),
                  onPressed: onPressed,
                ))));
  }
}

/// A widget that animates implicitly between a play and a pause icon.
class AnimatedPlayPause extends StatefulWidget {
  const AnimatedPlayPause({
    super.key,
    required this.playing,
    this.size,
    this.color,
  });

  final double? size;
  final bool playing;
  final Color? color;

  @override
  State<AnimatedPlayPause> createState() => _AnimatedPlayPauseState();
}

class _AnimatedPlayPauseState extends State<AnimatedPlayPause>
    with SingleTickerProviderStateMixin {
  late final animationController = AnimationController(
      vsync: this,
      value: widget.playing ? 1 : 0,
      duration: const Duration(milliseconds: 400));

  @override
  void didUpdateWidget(AnimatedPlayPause oldWidget) {
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
      progress: animationController);
}

class DefaultIcon extends Icon {
  const DefaultIcon(IconData super.icon,
      {double super.size = 22, super.color, super.key});
}

class DefaultError extends StatelessWidget {
  const DefaultError(
      {super.key, required this.color, required this.error, this.onTap});

  final Color color;
  final IconData error;
  final GestureTapCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget icon = DefaultIcon(error, size: 42, color: color);
    if (onTap != null) {
      icon = icon.onTap(onTap);
    }
    return Center(child: icon);
  }
}
