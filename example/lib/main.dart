import 'package:fl_video/fl_video.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static final light = ThemeData(
      brightness: Brightness.light,
      disabledColor: Colors.grey.shade400,
      visualDensity: VisualDensity.adaptivePlatformDensity);

  static final dark = ThemeData(
      brightness: Brightness.dark,
      disabledColor: Colors.grey.shade400,
      visualDensity: VisualDensity.adaptivePlatformDensity);
}

void main() {
  runApp(const MaterialApp(
      debugShowCheckedModeBanner: false, title: 'FlVideo', home: _HomePage()));
}

class _HomePage extends StatefulWidget {
  const _HomePage({Key? key}) : super(key: key);

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  late final VideoPlayerController _videoPlayerController1 =
      VideoPlayerController.networkUrl(Uri.parse(
          'https://assets.mixkit.co/videos/preview/mixkit-daytime-city-traffic-aerial-view-56-large.mp4'));
  late final VideoPlayerController _videoPlayerController2 =
      VideoPlayerController.networkUrl(Uri.parse(
          'https://assets.mixkit.co/videos/preview/mixkit-a-girl-blowing-a-bubble-gum-at-an-amusement-park-1226-large.mp4'));
  FlVideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    initializePlayer(_videoPlayerController1);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void initializePlayer(VideoPlayerController videoPlayerController) {
    _controller = FlVideoPlayerController(
        videoPlayerController: videoPlayerController,
        autoPlay: true,
        looping: true,
        overlay: const IgnorePointer(
            child: Center(
                child: Text('overlay',
                    style: TextStyle(color: Colors.lightBlue, fontSize: 20)))),
        placeholder: const Center(
            child: Text('placeholder',
                style: TextStyle(color: Colors.red, fontSize: 20))),
        controls: videoPlayerController == _videoPlayerController1
            ? MaterialControls(
                hideDuration: const Duration(seconds: 5),
                enablePlay: true,
                enableFullscreen: true,
                enableSpeed: true,
                enableVolume: true,
                enableSubtitle: true,
                enablePosition: true,
                enableBottomBar: true,
                onTap: (FlVideoTapEvent event,
                    FlVideoPlayerController controller) {
                  debugPrint(event.toString());
                },
                onDragProgress:
                    (FlVideoDragProgressEvent event, Duration duration) {
                  debugPrint('$event===$duration');
                })
            : CupertinoControls(
                hideDuration: const Duration(seconds: 5),
                enableSpeed: true,
                enableSkip: true,
                enableSubtitle: true,
                enableFullscreen: true,
                enableVolume: true,
                enablePlay: true,
                enableBottomBar: true,
                onTap: (FlVideoTapEvent event,
                    FlVideoPlayerController controller) {
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
                          style: const TextStyle(
                              fontSize: 16, color: Colors.red)));
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
    return Scaffold(
        appBar: AppBar(title: const Text('Fl Video Player')),
        body: SafeArea(
          bottom: true,
          child: Column(children: <Widget>[
            Expanded(child: FlVideoPlayer(controller: _controller!)),
            const SizedBox(height: 40),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  ElevatedText(
                      onPressed: () async {
                        if (_controller!.videoPlayerController !=
                            _videoPlayerController1) {
                          await _controller!.dispose();
                          initializePlayer(_videoPlayerController1);
                          setState(() {});
                        }
                      },
                      text: "MaterialControls"),
                  ElevatedText(
                      onPressed: () async {
                        if (_controller!.videoPlayerController !=
                            _videoPlayerController2) {
                          await _controller!.dispose();
                          initializePlayer(_videoPlayerController2);
                          setState(() {});
                        }
                      },
                      text: 'CupertinoControls')
                ]),
            const SizedBox(height: 40),
          ]),
        ));
  }
}

class ElevatedText extends StatelessWidget {
  const ElevatedText({Key? key, this.onPressed, required this.text})
      : super(key: key);
  final VoidCallback? onPressed;
  final String text;

  @override
  Widget build(BuildContext context) =>
      ElevatedButton(onPressed: onPressed, child: Text(text));
}
