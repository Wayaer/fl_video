import 'dart:async';

import 'package:fl_video/fl_video.dart';
import 'package:fl_video/src/controls/player_with_controls.dart';
import 'package:fl_video/src/controls/universal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef FlVideoPlayerRoutePageBuilder = Widget Function(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    FlVideoPlayerControllerProvider controllerProvider);

typedef SubtitlesBuilder = Widget Function(
    BuildContext context, String subtitle);

/// A Video Player with Material and Cupertino skins.
///
/// `video_player` is pretty low level. FlVideoPlayer wraps it in a friendly skin to
/// make it easy to use!
class FlVideoPlayer extends StatefulWidget {
  const FlVideoPlayer({Key? key, required this.controller}) : super(key: key);

  /// The [FlVideoPlayerController]
  final FlVideoPlayerController controller;

  @override
  State<FlVideoPlayer> createState() => _FlVideoPlayerState();
}

class _FlVideoPlayerState extends State<FlVideoPlayer> {
  bool _isFullScreen = false;
  late PlayerNotifier notifier;

  final ValueNotifier<double> _aspectRatio = ValueNotifier<double>(0);

  FlVideoPlayerController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller.addListener(listener);
    notifier = PlayerNotifier.init;
  }

  @override
  void dispose() {
    _aspectRatio.dispose();
    controller.removeListener(listener);
    super.dispose();
  }

  @override
  void didUpdateWidget(FlVideoPlayer oldWidget) {
    if (oldWidget.controller != controller) controller.addListener(listener);
    super.didUpdateWidget(oldWidget);
  }

  Future<void> listener() async {
    if (controller.isFullScreen && !_isFullScreen) {
      _isFullScreen = true;
      await _pushFullScreenWidget(context);
    } else if (_isFullScreen) {
      Navigator.of(context, rootNavigator: true).maybePop();
      _isFullScreen = false;
    }
    if (controller.value.aspectRatio != _aspectRatio.value) {
      _aspectRatio.value = controller.value.aspectRatio;
    }
  }

  @override
  Widget build(BuildContext context) => controllerProvider;

  FlVideoPlayerControllerProvider get controllerProvider {
    double calculateAspectRatio() {
      final size = MediaQuery.of(context).size;
      final width = size.width;
      final height = size.height;
      return width > height ? width / height : height / width;
    }

    return FlVideoPlayerControllerProvider(
        controller: controller,
        child: Universal(
            expand: true,
            color: Colors.black,
            isStack: true,
            aspectRatio: calculateAspectRatio(),
            children: [
              ValueListenableBuilder(
                  valueListenable: _aspectRatio,
                  builder: (_, double aspectRatio, __) => aspectRatio != 0
                      ? Universal(
                          alignment: Alignment.center,
                          aspectRatio: controller
                              .videoPlayerController.value.aspectRatio,
                          child: VideoPlayer(controller.videoPlayerController))
                      : controller.placeholder ?? const SizedBox()),
              if (controller.overlay != null) controller.overlay!,
              if (controller.controls != null)
                controller.isFullScreen
                    ? SafeArea(bottom: false, child: controller.controls!)
                    : controller.controls!
            ]));
  }

  Future<void> _pushFullScreenWidget(BuildContext context) async {
    final TransitionRoute<void> route = PageRouteBuilder<void>(pageBuilder:
        (BuildContext context, Animation<double> animation,
            Animation<double> secondaryAnimation) {
      if (controller.routePageBuilder != null) {
        return controller.routePageBuilder!(
            context, animation, secondaryAnimation, controllerProvider);
      }
      return AnimatedBuilder(
          animation: animation,
          builder: (_, __) => Scaffold(
              backgroundColor: Colors.black,
              resizeToAvoidBottomInset: false,
              body: controllerProvider));
    });
    onEnterFullScreen();
    if (!controller.allowedScreenSleep) {
      Wakelock.enable();
    }
    await Navigator.of(context, rootNavigator: true).push(route);

    _isFullScreen = false;
    controller.exitFullScreen();

    // The wakelock plugins checks whether it needs to perform an action internally,
    // so we do not need to check Wakelock.isEnabled.
    Wakelock.disable();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: controller.systemOverlaysAfterFullScreen);
    SystemChrome.setPreferredOrientations(
        controller.deviceOrientationsAfterFullScreen);
  }

  void onEnterFullScreen() {
    final videoWidth = controller.videoPlayerController.value.size.width;
    final videoHeight = controller.videoPlayerController.value.size.height;

    if (controller.systemOverlaysOnEnterFullScreen != null) {
      /// Optional user preferred settings
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: controller.systemOverlaysOnEnterFullScreen!);
    } else {
      /// Default behavior
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    }

    if (controller.deviceOrientationsOnEnterFullScreen != null) {
      /// Optional user preferred settings
      SystemChrome.setPreferredOrientations(
          controller.deviceOrientationsOnEnterFullScreen!);
    } else {
      final isLandscapeVideo = videoWidth > videoHeight;
      final isPortraitVideo = videoWidth < videoHeight;

      /// Default behavior
      /// Video w > h means we force landscape
      if (isLandscapeVideo) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }

      /// Video h > w means we force portrait
      else if (isPortraitVideo) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      }

      /// Otherwise if h == w (square video)
      else {
        SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      }
    }
  }
}

/// The FlVideoPlayerController is used to configure and drive the FlVideoPlayer Player
/// Widgets. It provides methods to control playback, such as [pause] and
/// [play], as well as methods that control the visual appearance of the player,
/// such as [enterFullScreen] or [exitFullScreen].
///
/// In addition, you can listen to the FlVideoPlayerController for presentational
/// changes, such as entering and exiting full screen mode. To listen for
/// changes to the playback, such as a change to the seek position of the
/// player, please use the standard information provided by the
/// `VideoPlayerController`.
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
    await videoPlayerController.setLooping(looping);

    if ((autoInitialize || autoPlay) &&
        !videoPlayerController.value.isInitialized) {
      await videoPlayerController.initialize();
    }

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
    Key? key,
    required this.controller,
    required Widget child,
  }) : super(key: key, child: child);

  final FlVideoPlayerController controller;

  @override
  bool updateShouldNotify(
          covariant FlVideoPlayerControllerProvider oldWidget) =>
      controller != oldWidget.controller;
}
