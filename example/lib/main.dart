import 'package:fl_video/fl_video.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      title: 'FlVideoPlayer',
      home: const _HomePage()));
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    final tabs = ['VideoPlayer', 'Material', 'Cupertino'];
    return Scaffold(
        appBar: AppBar(title: const Text('Fl Video Player')),
        body: DefaultTabController(
            length: tabs.length,
            child: Column(children: [
              TabBar(tabs: tabs.map((e) => Tab(text: e)).toList()),
              Expanded(
                  child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      const _VideoPlayer(),
                      const _MaterialControlsVideoPlayer(),
                      const _CupertinoControlsVideoPlayer()
                    ]),
              )),
            ])));
  }
}

class _VideoPlayer extends StatefulWidget {
  const _VideoPlayer();

  @override
  State<_VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<_VideoPlayer> {
  late VideoPlayerController controller;

  @override
  void initState() {
    super.initState();
    controller = VideoPlayerController.networkUrl(Uri.parse(
        'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4'));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        alignment: Alignment.center,
        width: double.infinity,
        height: double.infinity,
        child: controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller))
            : CircularProgressIndicator());
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

class _CupertinoControlsVideoPlayer extends StatefulWidget {
  const _CupertinoControlsVideoPlayer();

  @override
  State<_CupertinoControlsVideoPlayer> createState() =>
      _CupertinoControlsVideoPlayerState();
}

class _CupertinoControlsVideoPlayerState
    extends State<_CupertinoControlsVideoPlayer> {
  late FlVideoPlayerController controller;

  @override
  void initState() {
    super.initState();
    controller = FlVideoPlayerController(
        videoPlayerController: VideoPlayerController.asset('assets/h.mp4'),
        autoPlay: true,
        looping: true,
        overlay: const IgnorePointer(
            child: Center(
                child: Text('overlay',
                    style: TextStyle(color: Colors.lightBlue, fontSize: 20)))),
        placeholder: const Center(
            child: Text('placeholder',
                style: TextStyle(color: Colors.red, fontSize: 20))),
        controls: CupertinoControls(
            hideDuration: const Duration(seconds: 5),
            enableSpeed: true,
            enableSkip: true,
            enableSubtitle: true,
            enableFullscreen: true,
            enableVolume: true,
            enablePlay: true,
            enableBottomBar: true,
            onTap: (FlVideoTapEvent event, FlVideoPlayerController controller) {
              debugPrint(event.toString());
            },
            onDragProgress:
                (FlVideoDragProgressEvent event, Duration duration) {
              debugPrint('$event===$duration');
            },
            remainingBuilder: (String position) {
              return Padding(
                  padding: const EdgeInsets.fromLTRB(0, 6, 6, 6),
                  child: Text(position,
                      style: const TextStyle(fontSize: 16, color: Colors.red)));
            },
            positionBuilder: (String position) {
              return Padding(
                  padding: const EdgeInsets.fromLTRB(6, 6, 0, 6),
                  child: Text(position,
                      style: const TextStyle(
                          fontSize: 16, color: Colors.lightBlue)));
            }),
        subtitle: Subtitles([
          Subtitle(
              index: 0,
              start: Duration.zero,
              end: const Duration(seconds: 10),
              text: 'No.1 subtitle'),
          Subtitle(
              index: 0,
              start: const Duration(seconds: 10),
              end: const Duration(seconds: 20),
              text: 'No.2 subtitle)'),
        ]));
  }

  @override
  Widget build(BuildContext context) {
    return FlVideoPlayer(controller: controller);
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }
}

class _MaterialControlsVideoPlayer extends StatefulWidget {
  const _MaterialControlsVideoPlayer();

  @override
  State<_MaterialControlsVideoPlayer> createState() =>
      _MaterialControlsVideoPlayerState();
}

class _MaterialControlsVideoPlayerState
    extends State<_MaterialControlsVideoPlayer> {
  late FlVideoPlayerController controller;

  @override
  void initState() {
    super.initState();
    controller = FlVideoPlayerController(
        videoPlayerController: VideoPlayerController.asset('assets/v.mp4'),
        autoPlay: true,
        looping: true,
        overlay: const IgnorePointer(
            child: Center(
                child: Text('overlay',
                    style: TextStyle(color: Colors.lightBlue, fontSize: 20)))),
        placeholder: const Center(
            child: Text('placeholder',
                style: TextStyle(color: Colors.red, fontSize: 20))),
        controls: MaterialControls(
            hideDuration: const Duration(seconds: 5),
            enablePlay: true,
            enableFullscreen: true,
            enableSpeed: true,
            enableVolume: true,
            enableSubtitle: true,
            enablePosition: true,
            enableBottomBar: true,
            onTap: (FlVideoTapEvent event, FlVideoPlayerController controller) {
              debugPrint(event.toString());
            },
            onDragProgress:
                (FlVideoDragProgressEvent event, Duration duration) {
              debugPrint('$event===$duration');
            }),
        subtitle: Subtitles([
          Subtitle(
              index: 0,
              start: Duration.zero,
              end: const Duration(seconds: 10),
              text: 'No.1 subtitle'),
          Subtitle(
              index: 0,
              start: const Duration(seconds: 10),
              end: const Duration(seconds: 20),
              text: 'No.2 subtitle)'),
        ]));
  }

  @override
  Widget build(BuildContext context) {
    return FlVideoPlayer(controller: controller);
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }
}
