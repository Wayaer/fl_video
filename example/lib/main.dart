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

class _HomePage extends StatefulWidget {
  const _HomePage();

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage>
    with SingleTickerProviderStateMixin {
  late TabController controller;

  final controls = [
    const _MaterialControlsVideoPlayer(),
    const _CupertinoControlsVideoPlayer()
  ];

  @override
  void initState() {
    super.initState();
    controller = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Fl Video Player')),
        body: SafeArea(
          bottom: true,
          child: Column(children: [
            Expanded(
                child: TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    controller: controller,
                    children: controls)),
            const SizedBox(height: 40),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              ElevatedText(
                  onPressed: () {
                    controller.animateTo(0);
                  },
                  text: "MaterialControls"),
              ElevatedText(
                  onPressed: () {
                    controller.animateTo(1);
                  },
                  text: 'CupertinoControls')
            ]),
            const SizedBox(height: 40),
          ]),
        ));
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
  late FlVideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FlVideoPlayerController(
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
    return FlVideoPlayer(controller: _controller);
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
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
  late FlVideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FlVideoPlayerController(
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
    return FlVideoPlayer(controller: _controller);
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }
}

class ElevatedText extends StatelessWidget {
  const ElevatedText({super.key, this.onPressed, required this.text});

  final VoidCallback? onPressed;
  final String text;

  @override
  Widget build(BuildContext context) =>
      ElevatedButton(onPressed: onPressed, child: Text(text));
}
