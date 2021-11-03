import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

class VideoProgressBar extends StatefulWidget {
  const VideoProgressBar(
    this.controller, {
    this.colors = const FlVideoPlayerProgressColors(),
    this.onDragEnd,
    this.onDragStart,
    this.onDragUpdate,
    Key? key,
    required this.barHeight,
    required this.handleHeight,
    required this.drawShadow,
  }) : super(key: key);

  final VideoPlayerController controller;
  final FlVideoPlayerProgressColors colors;
  final Function()? onDragStart;
  final Function()? onDragEnd;
  final Function()? onDragUpdate;

  final double barHeight;
  final double handleHeight;
  final bool drawShadow;

  @override
  _VideoProgressBarState createState() => _VideoProgressBarState();
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

class FlVideoPlayerProgressColors {
  const FlVideoPlayerProgressColors({
    this.played = const Color(0xb2ff0000),
    this.buffered = const Color(0x331e1ec8),
    this.handle = const Color(0xffc8c8c8),
    this.background = const Color(0x7fc8c8c8),
  });

  final Color played;
  final Color buffered;
  final Color handle;
  final Color background;
}
