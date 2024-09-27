import 'package:fl_video/fl_video.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FlVideoPlayerController extends ChangeNotifier {
  FlVideoPlayerController(
      {required this.videoPlayerController,
      this.autoInitialize = false,
      this.autoPlay = false,
      this.startAt,
      this.looping = false,
      this.fullScreenByDefault = false,
      this.placeholder,
      this.overlay,
      this.showControlsOnInitialize = true,
      this.subtitle,
      this.subtitleBuilder,
      this.controls,
      this.allowedScreenSleep = true,
      this.isLive = false,
      this.systemOverlaysOnEnterFullScreen,
      this.deviceOrientationsOnEnterFullScreen,
      this.systemOverlaysAfterFullScreen = SystemUiOverlay.values,
      this.deviceOrientationsAfterFullScreen = DeviceOrientation.values,
      this.routePageBuilder}) {
    _initialize();
  }

  /// Define here your own Widget on how your n'th subtitle will look like
  final SubtitlesBuilder? subtitleBuilder;

  /// Add a List of Subtitles here in `Subtitles.subtitle`
  Subtitles? subtitle;

  /// The controller for the video you want to play
  VideoPlayerController videoPlayerController;

  /// Initialize the Video on Startup. This will prep the video for playback.
  final bool autoInitialize;

  /// Play the video as soon as it's displayed
  final bool autoPlay;

  /// Start video at a certain position
  final Duration? startAt;

  /// Whether or not the video should loop
  final bool looping;

  /// Weather or not to show the controls when initializing the widget.
  final bool showControlsOnInitialize;

  /// Defines customised controls. Check [MaterialControls] or
  /// [CupertinoControls] for reference.
  final Widget? controls;

  /// The placeholder is displayed underneath the Video before it is initialized
  /// or played.
  final Widget? placeholder;

  /// A widget which is placed between the video and the controls
  final Widget? overlay;

  /// Defines if the player will start in fullscreen when play is pressed
  final bool fullScreenByDefault;

  /// Defines if the player will sleep in fullscreen or not
  final bool allowedScreenSleep;

  /// Defines if the controls should be for live stream video
  final bool isLive;

  /// Defines the system overlays visible on entering fullscreen
  final List<SystemUiOverlay>? systemOverlaysOnEnterFullScreen;

  /// Defines the set of allowed device orientations on entering fullscreen
  final List<DeviceOrientation>? deviceOrientationsOnEnterFullScreen;

  /// Defines the system overlays visible after exiting fullscreen
  final List<SystemUiOverlay> systemOverlaysAfterFullScreen;

  /// Defines the set of allowed device orientations after exiting fullscreen
  final List<DeviceOrientation> deviceOrientationsAfterFullScreen;

  /// Defines a custom RoutePageBuilder for the fullscreen
  final FlVideoPlayerRoutePageBuilder? routePageBuilder;

  static FlVideoPlayerController of(BuildContext context) {
    final flVideoControllerProvider = context
        .dependOnInheritedWidgetOfExactType<FlVideoPlayerControllerProvider>()!;
    return flVideoControllerProvider.controller;
  }

  bool _isFullScreen = false;

  bool get isInitialized => videoPlayerController.value.isInitialized;

  bool get isLooping => videoPlayerController.value.isLooping;

  bool get isBuffering => videoPlayerController.value.isBuffering;

  Duration get position => videoPlayerController.value.position;

  Duration get duration => videoPlayerController.value.duration;

  bool get hasError => videoPlayerController.value.hasError;

  double get volume => videoPlayerController.value.volume;

  List<DurationRange> get buffered => videoPlayerController.value.buffered;

  double get playbackSpeed => videoPlayerController.value.playbackSpeed;

  VideoPlayerValue get value => videoPlayerController.value;

  String? get errorDescription => videoPlayerController.value.errorDescription;

  bool get isFullScreen => _isFullScreen;

  bool get isPlaying => videoPlayerController.value.isPlaying;

  Future<void> _initialize() async {
    if ((autoInitialize || autoPlay) &&
        !videoPlayerController.value.isInitialized) {
      await videoPlayerController.initialize();
    }
    await videoPlayerController.setLooping(looping);

    if (autoPlay) {
      if (fullScreenByDefault) enterFullScreen();
      await videoPlayerController.play();
    }
    if (startAt != null) {
      await videoPlayerController.seekTo(startAt!);
    }

    if (fullScreenByDefault) {
      videoPlayerController.addListener(_fullScreenListener);
    }
    notifyListeners();
  }

  void _fullScreenListener() {
    if (videoPlayerController.value.isPlaying && !_isFullScreen) {
      enterFullScreen();
      videoPlayerController.removeListener(_fullScreenListener);
    }
  }

  void enterFullScreen() {
    _isFullScreen = true;
    notifyListeners();
  }

  void exitFullScreen() {
    _isFullScreen = false;
    notifyListeners();
  }

  void toggleFullScreen() {
    _isFullScreen = !_isFullScreen;
    notifyListeners();
  }

  Future<void> togglePause() => isPlaying ? pause() : play();

  Future<void> play() => videoPlayerController.play();

  Future<void> setPlaybackSpeed(double speed) =>
      videoPlayerController.setPlaybackSpeed(speed);

  Future<void> setLooping(bool looping) =>
      videoPlayerController.setLooping(looping);

  Future<void> pause() => videoPlayerController.pause();

  Future<void> seekTo(Duration moment) => videoPlayerController.seekTo(moment);

  Future<void> setVolume(double volume) =>
      videoPlayerController.setVolume(volume);

  void setSubtitle(List<Subtitle> newSubtitle) {
    subtitle = Subtitles(newSubtitle);
  }

  @override
  Future<void> dispose([bool disposeVideoPlayer = false]) async {
    if (disposeVideoPlayer) await videoPlayerController.dispose();
    super.dispose();
  }
}

class FlVideoPlayerControllerProvider extends InheritedWidget {
  const FlVideoPlayerControllerProvider({
    super.key,
    required this.controller,
    required super.child,
  });

  final FlVideoPlayerController controller;

  @override
  bool updateShouldNotify(
          covariant FlVideoPlayerControllerProvider oldWidget) =>
      controller != oldWidget.controller;
}
