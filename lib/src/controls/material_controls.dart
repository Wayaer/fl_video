import 'dart:async';

import 'package:fl_video/fl_video.dart';
import 'package:fl_video/src/fl_video_player.dart';
import 'package:fl_video/src/controls/player_with_controls.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

typedef PositionAndAllBuilder = Widget Function(String position, String all);
typedef ErrorBuilder = Widget Function(
    BuildContext context, String errorMessage);

class MaterialControls extends StatefulWidget {
  MaterialControls({
    Key? key,
    this.progressColors = const FlVideoPlayerProgressColors(
        played: Color(0x80FFFFFF),
        handle: Color(0xFFFFFFFF),
        buffered: Color(0x55FFFFFF),
        background: Color(0x35FFFFFF)),
    this.subtitleON = Icons.closed_caption,
    this.subtitleOFF = Icons.closed_caption_off_outlined,
    this.speed = Icons.speed,
    this.fullscreenON = Icons.fullscreen,
    this.fullscreenOFF = Icons.fullscreen_exit,
    this.volumeON = Icons.volume_up,
    this.volumeOFF = Icons.volume_off,
    this.error = Icons.error,
    this.backgroundColor = const Color(0x90000000),
    this.color = const Color(0xFFFFFFFF),
    this.hideDuration = const Duration(seconds: 4),
    this.enableSubtitle = true,
    this.enableSpeed = true,
    this.enableFullscreen = true,
    this.enableVolume = true,
    this.enablePlay = true,
    this.enablePosition = true,
    this.isLive = false,
    this.playbackSpeeds = const [0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2],
    this.loading = const CircularProgressIndicator(color: Colors.white),
    this.positionBuilder,
    this.errorBuilder,
    this.onTap,
    this.onDragProgress,
  })  : assert(playbackSpeeds.every((speed) => speed > 0),
            'The playbackSpeeds values must all be greater than 0'),
        super(key: key);

  /// Enable Subtitle
  final bool enableSubtitle;
  final IconData subtitleON;
  final IconData subtitleOFF;

  /// Enable Speed
  final bool enableSpeed;
  final IconData speed;

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

  /// Enable Position
  final bool enablePosition;

  /// position
  final PositionAndAllBuilder? positionBuilder;

  /// is Live
  final bool isLive;

  /// ProgressColor
  final FlVideoPlayerProgressColors progressColors;

  /// All icon and text color
  final Color color;
  final Color backgroundColor;

  /// Hide the Controls,
  final Duration hideDuration;

  //// loading
  final Widget loading;

  /// Defines the set of allowed playback speeds user can change
  final List<double> playbackSpeeds;

  /// errorBuilder
  final ErrorBuilder? errorBuilder;

  /// tap event
  final FlVideoControlsTap? onTap;

  /// Sliding progress bar
  final FlVideoControlsProgressDrag? onDragProgress;

  @override
  _MaterialControlsState createState() => _MaterialControlsState();
}

class _MaterialControlsState extends State<MaterialControls>
    with SingleTickerProviderStateMixin {
  late PlayerNotifier notifier;
  late VideoPlayerValue _latestValue;
  double? _latestVolume;
  Timer? _hideTimer;
  Timer? _initTimer;

  // late final Duration _position = const Duration();
  bool _subtitleOn = false;
  Timer? _showAfterExpandCollapseTimer;
  bool _dragging = false;
  bool _displayTapped = false;

  late VideoPlayerController controller;
  FlVideoPlayerController? _flVideoController;

  // We know that _flVideoController is set in didChangeDependencies
  FlVideoPlayerController get flVideoController => _flVideoController!;

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
          DefaultError(
              color: widget.color,
              error: widget.error,
              onTap: widget.onTap == null
                  ? null
                  : () {
                      widget.onTap
                          ?.call(FlVideoTapEvent.error, flVideoController);
                    });
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            if (_subtitleOn && widget.enableSubtitle)
                              _buildSubtitles(),
                            AnimatedOpacity(
                                opacity: notifier.hideStuff ? 0.0 : 1.0,
                                duration: const Duration(milliseconds: 300),
                                child: _buildBottomBar()),
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
    _initTimer?.cancel();
    _showAfterExpandCollapseTimer?.cancel();
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

  Widget _buildSubtitles() {
    final currentSubtitle =
        _flVideoController!.subtitle!.getByPosition(_latestValue.position);
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

  SafeArea _buildBottomBar() {
    return SafeArea(
        bottom: flVideoController.isFullScreen,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (!flVideoController.isLive)
            SizedBox(
                width: double.infinity,
                child: _MaterialVideoProgressBar(controller, onDragStart: () {
                  widget.onDragProgress?.call(
                      FlVideoDragProgressEvent.start, _latestValue.position);
                  _dragging = true;
                  setState(() {});
                  _hideTimer?.cancel();
                }, onDragEnd: () {
                  widget.onDragProgress?.call(
                      FlVideoDragProgressEvent.start, _latestValue.position);
                  _dragging = false;
                  setState(() {});
                  _startHideTimer();
                }, colors: widget.progressColors)),
          Row(children: <Widget>[
            if (widget.enablePlay) _buildPlayPause(),
            if (widget.enableVolume) _buildVolume(),
            if (widget.enablePosition) _buildPosition(),
            const Spacer(),
            if (widget.enableSpeed) _buildPlaybackSpeed(),
            if (widget.enableSubtitle) _buildSubtitle(),
            if (widget.enableFullscreen) _buildFullscreenButton(),
          ]),
        ]));
  }

  _GestureDetectorIcon _buildSubtitle() => _GestureDetectorIcon(
      onTap: () {
        widget.onTap?.call(FlVideoTapEvent.subtitle, flVideoController);
        _subtitleOn = !_subtitleOn;
        setState(() {});
      },
      isStartLeft: false,
      isFirst: !widget.enableFullscreen,
      color: widget.color,
      icon: _subtitleOn ? widget.subtitleON : widget.subtitleOFF);

  _GestureDetectorIcon _buildPlaybackSpeed() => _GestureDetectorIcon(
      isStartLeft: false,
      icon: widget.speed,
      color: widget.color,
      isFirst: !widget.enableFullscreen && !widget.enableSubtitle,
      onTap: () async {
        widget.onTap?.call(FlVideoTapEvent.speed, flVideoController);
        _hideTimer?.cancel();
        final chosenSpeed = await showModalBottomSheet<double>(
            context: context,
            isScrollControlled: true,
            useRootNavigator: true,
            builder: (context) => _PlaybackSpeedDialog(
                speeds: widget.playbackSpeeds,
                selected: _latestValue.playbackSpeed));

        if (chosenSpeed != null) {
          controller.setPlaybackSpeed(chosenSpeed);
        }
        if (_latestValue.isPlaying) {
          _startHideTimer();
        }
      });

  _GestureDetectorIcon _buildFullscreenButton() => _GestureDetectorIcon(
      onTap: _onFullscreen,
      isStartLeft: false,
      isFirst: true,
      color: widget.color,
      icon: flVideoController.isFullScreen
          ? widget.fullscreenOFF
          : widget.fullscreenON);

  Widget _buildHitArea() {
    if (_latestValue.isBuffering) {
      var loading = widget.loading;
      if (widget.onTap != null) {
        loading.onTap(() {
          widget.onTap!(FlVideoTapEvent.loading, flVideoController);
        });
      }
      return Center(child: loading);
    }
    final bool isFinished = _latestValue.position >= _latestValue.duration;
    return _GestureDetectorIcon(
        onTap: () {
          if (_latestValue.isPlaying) {
            if (_displayTapped) {
              notifier.hideStuff = true;
              setState(() {});
            } else {
              _cancelAndRestartTimer();
            }
          } else {
            _playPause();
            notifier.hideStuff = true;
            setState(() {});
          }
        },
        child: CenterPlayButton(
            backgroundColor: widget.backgroundColor,
            iconColor: widget.color,
            isFinished: isFinished,
            isPlaying: controller.value.isPlaying,
            show: !_latestValue.isPlaying && !_dragging,
            onPressed: () {
              widget.onTap
                  ?.call(FlVideoTapEvent.largePlayPause, flVideoController);
              _playPause();
            }));
  }

  _GestureDetectorIcon _buildVolume() => _GestureDetectorIcon(
      onTap: () {
        widget.onTap?.call(FlVideoTapEvent.volume, flVideoController);
        _cancelAndRestartTimer();
        if (_latestValue.volume == 0) {
          controller.setVolume(_latestVolume ?? 0.5);
        } else {
          _latestVolume = controller.value.volume;
          controller.setVolume(0.0);
        }
      },
      isFirst: !widget.enablePlay,
      color: widget.color,
      icon: _latestValue.volume > 0 ? widget.volumeON : widget.volumeOFF);

  _GestureDetectorIcon _buildPlayPause() => _GestureDetectorIcon(
      onTap: () {
        widget.onTap?.call(FlVideoTapEvent.playPause, flVideoController);
        _playPause();
      },
      child: AnimatedPlayPause(
          playing: controller.value.isPlaying, color: widget.color));

  Widget _buildPosition() {
    if (widget.isLive) {
      return Expanded(
          child: Text('LIVE', style: TextStyle(color: widget.color)));
    }
    final duration = _latestValue.duration;
    final position = _latestValue.position;
    if (widget.positionBuilder != null) {
      return widget.positionBuilder!(
          position.formatDuration(), duration.formatDuration());
    }
    Widget text = Text(
        '${position.formatDuration()} / ${duration.formatDuration()}',
        style: TextStyle(fontSize: 14.0, color: widget.color));
    if (!widget.enableVolume) {
      text = Padding(
          padding: EdgeInsets.only(left: widget.enablePlay ? 6 : 0),
          child: text);
    }
    if (widget.onTap != null) {
      return GestureDetector(
          child: text,
          onTap: () {
            widget.onTap!(FlVideoTapEvent.position, flVideoController);
          });
    }
    return text;
  }

  void _cancelAndRestartTimer() {
    _hideTimer?.cancel();
    _startHideTimer();
    notifier.hideStuff = false;
    _displayTapped = true;
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

  void _onFullscreen() {
    widget.onTap?.call(FlVideoTapEvent.fullscreen, flVideoController);
    setState(() {
      notifier.hideStuff = true;
      flVideoController.toggleFullScreen();
      _showAfterExpandCollapseTimer =
          Timer(const Duration(milliseconds: 300), () {
        _cancelAndRestartTimer();
        setState(() {});
      });
    });
  }

  void _playPause() {
    final isFinished = _latestValue.position >= _latestValue.duration;
    setState(() {
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
          if (isFinished) {
            controller.seekTo(const Duration());
          }
          controller.play();
        }
      }
    });
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
    setState(() {});
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
      this.color})
      : super(key: key);
  final GestureTapCallback? onTap;
  final Widget? child;
  final IconData? icon;
  final bool isStartLeft;
  final bool isFirst;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    double right = 6;
    double left = 6;
    if (!isStartLeft) {
      if (isFirst) right = 0;
    } else {
      if (isFirst) left = 0;
    }
    return GestureDetector(
        onTap: onTap,
        child: child ??
            Padding(
                padding: EdgeInsets.only(
                    left: left, right: right, bottom: 4, top: 4),
                child: child ??
                    DefaultIcon(icon ?? Icons.add_box_outlined, color: color)));
  }
}

class _MaterialVideoProgressBar extends VideoProgressBar {
  const _MaterialVideoProgressBar(
    VideoPlayerController controller, {
    FlVideoPlayerProgressColors colors = const FlVideoPlayerProgressColors(),
    Function()? onDragStart,
    Function()? onDragEnd,
    Function()? onDragUpdate,
  }) : super(controller,
            barHeight: 3,
            handleHeight: 6,
            drawShadow: false,
            colors: colors,
            onDragEnd: onDragEnd,
            onDragStart: onDragStart,
            onDragUpdate: onDragUpdate);
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
    final Color selectedColor = Theme.of(context).primaryColor;
    return ListView.builder(
        shrinkWrap: true,
        physics: const ScrollPhysics(),
        itemBuilder: (context, index) {
          final _speed = _speeds[index];
          return ListTile(
              dense: true,
              title: Row(children: [
                if (_speed == _selected)
                  Icon(Icons.check, size: 20.0, color: selectedColor)
                else
                  Container(width: 20.0),
                const SizedBox(width: 16.0),
                Text(_speed.toString()),
              ]),
              selected: _speed == _selected,
              onTap: () {
                Navigator.of(context).pop(_speed);
              });
        },
        itemCount: _speeds.length);
  }
}
