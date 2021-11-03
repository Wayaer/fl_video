import 'package:fl_video/fl_video.dart';
import 'package:fl_video/src/fl_video_player.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class PlayerWithControls extends StatelessWidget {
  const PlayerWithControls(this.controller, {Key? key}) : super(key: key);
  final FlVideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    print('======PlayerWithControls===build');
    double _calculateAspectRatio() {
      final size = MediaQuery.of(context).size;
      final width = size.width;
      final height = size.height;
      return width > height ? width / height : height / width;
    }

    return SizedBox.expand(
        child: AspectRatio(
            aspectRatio: _calculateAspectRatio(),
            child: ColoredBox(
                color: Colors.black,
                child: Stack(children: <Widget>[
                  controller.placeholder ?? const SizedBox(),
                  Center(
                      child: AspectRatio(
                    aspectRatio: controller.aspectRatio ??
                        controller.videoPlayerController.value.aspectRatio,
                    child: VideoPlayer(controller.videoPlayerController),
                  )),
                  if (controller.overlay != null) controller.overlay!,
                  if (controller.controls != null)
                    controller.isFullScreen
                        ? SafeArea(bottom: false, child: controller.controls!)
                        : controller.controls!
                ]))));
  }
}

extension FormatDuration on Duration {
  String formatDuration() {
    final ms = inMilliseconds;

    int seconds = ms ~/ 1000;
    final int hours = seconds ~/ 3600;
    seconds = seconds % 3600;
    final minutes = seconds ~/ 60;
    seconds = seconds % 60;

    final hoursString = hours >= 10
        ? '$hours'
        : hours == 0
            ? '00'
            : '0$hours';

    final minutesString = minutes >= 10
        ? '$minutes'
        : minutes == 0
            ? '00'
            : '0$minutes';

    final secondsString = seconds >= 10
        ? '$seconds'
        : seconds == 0
            ? '00'
            : '0$seconds';

    final formattedTime =
        '${hoursString == '00' ? '' : '$hoursString:'}$minutesString:$secondsString';
    return formattedTime;
  }
}

class CenterPlayButton extends StatelessWidget {
  const CenterPlayButton({
    Key? key,
    required this.backgroundColor,
    this.iconColor,
    required this.show,
    required this.isPlaying,
    required this.isFinished,
    this.onPressed,
  }) : super(key: key);

  final Color backgroundColor;
  final Color? iconColor;
  final bool show;
  final bool isPlaying, isFinished;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.transparent,
        alignment: Alignment.center,
        child: AnimatedOpacity(
            opacity: show ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                    color: backgroundColor, shape: BoxShape.circle),
                child: IconButton(
                  iconSize: 32,
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
    Key? key,
    required this.playing,
    this.size,
    this.color,
  }) : super(key: key);

  final double? size;
  final bool playing;
  final Color? color;

  @override
  _AnimatedPlayPauseState createState() => _AnimatedPlayPauseState();
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
