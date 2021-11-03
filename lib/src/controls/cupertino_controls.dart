import 'dart:async';
import 'dart:math' as math;

import 'package:fl_video/fl_video.dart';
import 'package:fl_video/src/fl_video_player.dart';
import 'package:fl_video/src/model.dart';
import 'package:fl_video/src/controls/player_with_controls.dart';
import 'package:fl_video/src/controls/progress_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

typedef PositionBuilder = Widget Function(String postion);
typedef RemainingBuilder = Widget Function(String remaining);

class CupertinoControls extends StatefulWidget {
  CupertinoControls({
    Key? key,
    this.hideDuration = const Duration(seconds: 4),
    this.backgroundColor = const Color(0x90000000),
    this.color = const Color(0xFFFFFFFF),
    this.subtitleON = Icons.closed_caption,
    this.subtitleOFF = Icons.closed_caption_off_outlined,
    this.speed = Icons.speed,
    this.fullscreenON = CupertinoIcons.arrow_up_left_arrow_down_right,
    this.fullscreenOFF = CupertinoIcons.arrow_down_right_arrow_up_left,
    this.volumeON = Icons.volume_up,
    this.volumeOFF = Icons.volume_off,
    this.error = Icons.error,
    this.skipForward = CupertinoIcons.gobackward_15,
    this.skipBack = CupertinoIcons.gobackward_15,
    this.enableSubtitle = true,
    this.enableSpeed = true,
    this.enableSkip = true,
    this.enableFullscreen = true,
    this.enableVolume = true,
    this.enablePlay = true,
    this.enablePosition = true,
    this.enableRemaining = true,
    this.positionBuilder,
    this.remainingBuilder,
    this.progressColors = const FlVideoPlayerProgressColors(
        played: Color(0x78ffffff),
        handle: Color(0xffffffff),
        buffered: Color(0x3cffffff),
        background: Color(0x14ffffff)),
    this.playbackSpeeds = const [0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2],
    this.loading = const CircularProgressIndicator(color: Colors.white),
    this.errorBuilder,
  })  : assert(playbackSpeeds.every((speed) => speed > 0),
            'The playbackSpeeds values must all be greater than 0'),
        super(key: key);
  final FlVideoPlayerProgressColors progressColors;
  final Color backgroundColor;
  final Color color;

  /// Enable Subtitle
  final bool enableSubtitle;
  final IconData subtitleON;
  final IconData subtitleOFF;

  /// Enable Speed
  final bool enableSpeed;
  final IconData speed;
  final bool enableSkip;
  final IconData skipForward;
  final IconData skipBack;

  /// Enable Fullscreen
  final bool enableFullscreen;
  final IconData fullscreenON;
  final IconData fullscreenOFF;

  /// Enable Volume
  final bool enableVolume;
  final IconData volumeON;
  final IconData volumeOFF;

  /// error
  final IconData error;

  /// Enable Play
  final bool enablePlay;

  /// Hide the Controls,
  final Duration hideDuration;

  //// loading
  final Widget loading;

  /// Enable Position
  final bool enablePosition;

  /// position
  final PositionBuilder? positionBuilder;

  /// Enable Remaining
  final bool enableRemaining;

  /// remaining
  final RemainingBuilder? remainingBuilder;

  /// Defines the set of allowed playback speeds user can change
  final List<double> playbackSpeeds;

  /// errorBuilder
  final Widget Function(BuildContext context, String errorMessage)?
      errorBuilder;

  @override
  _CupertinoControlsState createState() => _CupertinoControlsState();
}

class _CupertinoControlsState extends State<CupertinoControls>
    with SingleTickerProviderStateMixin {
  late PlayerNotifier notifier;
  late VideoPlayerValue _latestValue;
  double? _latestVolume;
  Timer? _hideTimer;
  final marginSize = 5.0;
  Timer? _expandCollapseTimer;
  Timer? _initTimer;
  bool _dragging = false;
  Duration? _subtitlesPosition;
  bool _subtitleOn = false;

  late VideoPlayerController controller;

  // We know that _flVideoController is set in didChangeDependencies
  FlVideoPlayerController get flVideoController => _flVideoController!;
  FlVideoPlayerController? _flVideoController;

  @override
  void initState() {
    super.initState();
    notifier = PlayerNotifier.init;
  }

  @override
  Widget build(BuildContext context) {
    if (_latestValue.hasError) {
      return widget.errorBuilder?.call(
              context,
              flVideoController
                  .videoPlayerController.value.errorDescription!) ??
          Center(child: _Icon(widget.error, size: 42, color: widget.color));
    }

    return MouseRegion(
        onHover: (_) => _cancelAndRestartTimer(),
        child: GestureDetector(
            onTap: _cancelAndRestartTimer,
            child: AbsorbPointer(
                absorbing: notifier.hideStuff,
                child: Stack(children: [
                  _buildHitArea(),
                  Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            AnimatedOpacity(
                                opacity: notifier.hideStuff ? 0.0 : 1.0,
                                duration: const Duration(milliseconds: 300),
                                child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      _buildFullscreen(),
                                      if (widget.enableVolume) _buildVolume(),
                                    ])),
                            const Spacer(),
                            if (_subtitleOn && widget.enableSubtitle)
                              _buildSubtitles(flVideoController.subtitle!),
                            AnimatedOpacity(
                                opacity: notifier.hideStuff ? 0.0 : 1.0,
                                duration: const Duration(milliseconds: 300),
                                child: _buildBottomBar())
                          ]))
                ]))));
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  void _dispose() {
    controller.removeListener(_updateState);
    _hideTimer?.cancel();
    _expandCollapseTimer?.cancel();
    _initTimer?.cancel();
  }

  @override
  void didChangeDependencies() {
    final _oldController = _flVideoController;
    _flVideoController = FlVideoPlayerController.of(context);
    controller = flVideoController.videoPlayerController;
    if (_oldController != flVideoController) {
      _dispose();
      _initialize();
    }
    super.didChangeDependencies();
  }

  Widget _buildSubtitles(Subtitles subtitles) {
    if (_subtitlesPosition == null) {
      return const SizedBox();
    }
    final currentSubtitle = subtitles.getByPosition(_subtitlesPosition!);
    if (currentSubtitle.isEmpty) {
      return const SizedBox();
    }

    if (flVideoController.subtitleBuilder != null) {
      return flVideoController.subtitleBuilder!(
          context, currentSubtitle.first!.text);
    }
    return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(currentSubtitle.first!.text,
            style: TextStyle(fontSize: 18, color: widget.color),
            textAlign: TextAlign.center));
  }

  Widget _buildBottomBar() {
    return SafeArea(
        bottom: flVideoController.isFullScreen,
        child: DecoratedBox(
            decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(10.0)),
            child: flVideoController.isLive
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          _buildPlayPause(),
                          _buildLive(),
                        ]))
                : Row(children: <Widget>[
                    if (widget.enableSkip) _buildSkipBack(),
                    if (widget.enablePlay) _buildPlayPause(),
                    if (widget.enableSkip) _buildSkipForward(),
                    if (widget.enablePosition) _buildPosition(),
                    _buildProgressBar(),
                    if (widget.enablePosition) _buildRemaining(),
                    if (widget.enableSubtitle) _buildSubtitleToggle(),
                    if (widget.enableSpeed) _buildSpeed(),
                  ])));
  }

  Widget _buildLive() =>
      Text('LIVE', style: TextStyle(color: widget.color, fontSize: 12.0));

  Widget _buildFullscreen() => widget.enableFullscreen
      ? _GestureDetectorIcon(
          onTap: _onExpandCollapse,
          addBackdropFilter: true,
          backgroundColor: widget.backgroundColor,
          icon: flVideoController.isFullScreen
              ? widget.fullscreenOFF
              : widget.fullscreenON,
          color: widget.color)
      : const SizedBox();

  _GestureDetectorIcon _buildVolume() => _GestureDetectorIcon(
      addBackdropFilter: true,
      backgroundColor: widget.backgroundColor,
      onTap: () {
        _cancelAndRestartTimer();
        if (_latestValue.volume == 0) {
          controller.setVolume(_latestVolume ?? 0.5);
        } else {
          _latestVolume = controller.value.volume;
          controller.setVolume(0.0);
        }
      },
      icon: _latestValue.volume > 0 ? widget.volumeON : widget.volumeOFF,
      color: widget.color);

  Widget _buildHitArea() {
    if (_latestValue.isBuffering) {
      return Center(child: widget.loading);
    }
    final bool isFinished = _latestValue.position >= _latestValue.duration;
    return _GestureDetectorIcon(
        onTap: _latestValue.isPlaying
            ? _cancelAndRestartTimer
            : () {
                _hideTimer?.cancel();

                setState(() {
                  notifier.hideStuff = false;
                });
              },
        child: CenterPlayButton(
            backgroundColor: widget.backgroundColor,
            iconColor: widget.color,
            isFinished: isFinished,
            isPlaying: controller.value.isPlaying,
            show: !_latestValue.isPlaying && !_dragging,
            onPressed: _playPause));
  }

  _GestureDetectorIcon _buildPlayPause() => _GestureDetectorIcon(
      onTap: _playPause,
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: AnimatedPlayPause(
              color: widget.color, playing: controller.value.isPlaying)));

  Widget _buildPosition() {
    final position = _latestValue.position;
    if (widget.positionBuilder != null) {
      return widget.positionBuilder!(position.formatDuration());
    }
    return Padding(
        padding: const EdgeInsets.only(left: 6, top: 8, bottom: 8),
        child: Text(position.formatDuration(),
            style: TextStyle(color: widget.color, fontSize: 12.0)));
  }

  Widget _buildRemaining() {
    final remaining = _latestValue.duration - _latestValue.position;
    if (widget.remainingBuilder != null) {
      return widget.remainingBuilder!(remaining.formatDuration());
    }
    return Padding(
        padding: const EdgeInsets.only(right: 6, top: 8, bottom: 8),
        child: Text('-${remaining.formatDuration()}',
            style: TextStyle(color: widget.color, fontSize: 12.0)));
  }

  _GestureDetectorIcon _buildSkipBack() => _GestureDetectorIcon(
      onTap: () {
        _cancelAndRestartTimer();
        final beginning = const Duration().inMilliseconds;
        final skip = (_latestValue.position - const Duration(seconds: 15))
            .inMilliseconds;
        controller.seekTo(Duration(milliseconds: math.max(skip, beginning)));
      },
      icon: widget.skipBack,
      color: widget.color);

  _GestureDetectorIcon _buildSkipForward() => _GestureDetectorIcon(
      onTap: () {
        _cancelAndRestartTimer();
        final end = _latestValue.duration.inMilliseconds;
        final skip = (_latestValue.position + const Duration(seconds: 15))
            .inMilliseconds;
        controller.seekTo(Duration(milliseconds: math.min(skip, end)));
      },
      icon: widget.skipForward,
      color: widget.color);

  Widget _buildSubtitleToggle() {
    return _GestureDetectorIcon(
        onTap: () {
          _subtitleOn = !_subtitleOn;
          setState(() {});
        },
        icon: _subtitleOn ? widget.subtitleON : widget.subtitleOFF,
        color: widget.color);
  }

  _GestureDetectorIcon _buildSpeed() => _GestureDetectorIcon(
      onTap: () async {
        _hideTimer?.cancel();
        final chosenSpeed = await showCupertinoModalPopup<double>(
            context: context,
            semanticsDismissible: true,
            useRootNavigator: true,
            builder: (context) => _PlaybackSpeedDialog(
                speeds: widget.playbackSpeeds,
                selected: _latestValue.playbackSpeed));

        if (chosenSpeed != null) controller.setPlaybackSpeed(chosenSpeed);
        if (_latestValue.isPlaying) {
          _startHideTimer();
        }
      },
      icon: widget.speed,
      color: widget.color);

  void _cancelAndRestartTimer() {
    _hideTimer?.cancel();
    notifier.hideStuff = false;
    _startHideTimer();
    setState(() {});
  }

  Future<void> _initialize() async {
    _subtitleOn = flVideoController.subtitle?.isNotEmpty ?? false;
    controller.addListener(_updateState);
    _updateState();
    if (controller.value.isPlaying || flVideoController.autoPlay) {
      _startHideTimer();
    }

    if (flVideoController.showControlsOnInitialize) {
      _initTimer = Timer(const Duration(milliseconds: 200), () {
        notifier.hideStuff = false;
        setState(() {});
      });
    }
  }

  void _onExpandCollapse() {
    notifier.hideStuff = true;
    flVideoController.toggleFullScreen();
    _expandCollapseTimer = Timer(const Duration(milliseconds: 300), () {
      _cancelAndRestartTimer();
      setState(() {});
    });
    setState(() {});
  }

  Widget _buildProgressBar() => Expanded(
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: _CupertinoVideoProgressBar(controller, onDragStart: () {
            _dragging = true;
            setState(() {});
            _hideTimer?.cancel();
          }, onDragEnd: () {
            _dragging = false;
            setState(() {});
            _startHideTimer();
          }, colors: widget.progressColors)));

  void _playPause() {
    final isFinished = _latestValue.position >= _latestValue.duration;
    if (controller.value.isPlaying) {
      notifier.hideStuff = false;
      _hideTimer?.cancel();
      controller.pause();
    } else {
      _cancelAndRestartTimer();

      if (!controller.value.isInitialized) {
        controller.initialize().then((_) {
          controller.play();
        });
      } else {
        if (isFinished) controller.seekTo(const Duration());
        controller.play();
      }
    }
    setState(() {});
  }

  void _startHideTimer() {
    _hideTimer = Timer(widget.hideDuration, () {
      notifier.hideStuff = true;
      setState(() {});
    });
  }

  void _updateState() {
    if (!mounted) return;

    _latestValue = controller.value;
    _subtitlesPosition = controller.value.position;
    setState(() {});
  }
}

class _PlaybackSpeedDialog extends StatelessWidget {
  const _PlaybackSpeedDialog({
    Key? key,
    required List<double> speeds,
    required double selected,
  })  : _speeds = speeds,
        _selected = selected,
        super(key: key);

  final List<double> _speeds;
  final double _selected;

  @override
  Widget build(BuildContext context) {
    final selectedColor = CupertinoTheme.of(context).primaryColor;
    return CupertinoActionSheet(
        actions: _speeds
            .map((e) => CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(context).pop(e);
                },
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  if (e == _selected)
                    Icon(Icons.check, size: 20.0, color: selectedColor),
                  Text(e.toString()),
                ])))
            .toList());
  }
}

class _GestureDetectorIcon extends StatelessWidget {
  const _GestureDetectorIcon(
      {Key? key,
      this.onTap,
      this.child,
      this.icon,
      this.isStartLeft = true,
      this.isFirst = false,
      this.color,
      this.addBackdropFilter = false,
      this.backgroundColor})
      : super(key: key);
  final GestureTapCallback? onTap;
  final Widget? child;
  final IconData? icon;
  final bool isStartLeft;
  final bool isFirst;
  final Color? color;
  final Color? backgroundColor;
  final bool addBackdropFilter;

  @override
  Widget build(BuildContext context) {
    Widget widget = child ??
        Padding(
            padding:
                const EdgeInsets.only(left: 6, right: 6, bottom: 4, top: 4),
            child: _Icon(icon ?? Icons.add_box_outlined, color: color));
    return GestureDetector(
        onTap: onTap,
        child: addBackdropFilter
            ? DecoratedBox(
                decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(6)),
                child: widget)
            : widget);
  }
}

class _Icon extends Icon {
  const _Icon(IconData? icon, {double size = 22, Color? color})
      : super(icon, color: color, size: size);
}

class _CupertinoVideoProgressBar extends VideoProgressBar {
  const _CupertinoVideoProgressBar(
    VideoPlayerController controller, {
    FlVideoPlayerProgressColors colors = const FlVideoPlayerProgressColors(),
    Function()? onDragStart,
    Function()? onDragEnd,
    Function()? onDragUpdate,
  }) : super(controller,
            barHeight: 5,
            handleHeight: 6,
            drawShadow: true,
            colors: colors,
            onDragEnd: onDragEnd,
            onDragStart: onDragStart,
            onDragUpdate: onDragUpdate);
}
