import 'dart:async';

import 'package:fl_video/fl_video.dart';
import 'package:fl_video/src/controls/player_with_controls.dart';
import 'package:fl_video/src/extension.dart';
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
  const FlVideoPlayer({super.key, required this.controller});

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
                  builder: (_, double aspectRatio, __) => aspectRatio != 0 &&
                          controller.videoPlayerController.value.isInitialized
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
      WakelockPlus.enable();
    }
    await Navigator.of(context, rootNavigator: true).push(route);

    _isFullScreen = false;
    controller.exitFullScreen();

    // The wakelock plugins checks whether it needs to perform an action internally,
    // so we do not need to check Wakelock.isEnabled.
    WakelockPlus.disable();

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
