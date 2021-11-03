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
  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'fl.video',
        home: _HomePage());
  }
}

class _HomePage extends StatefulWidget {
  const _HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  late final VideoPlayerController _videoPlayerController1 =
      VideoPlayerController.network(
          'https://assets.mixkit.co/videos/preview/mixkit-daytime-city-traffic-aerial-view-56-large.mp4');
  late final VideoPlayerController _videoPlayerController2 =
      VideoPlayerController.network(
          'https://assets.mixkit.co/videos/preview/mixkit-a-girl-blowing-a-bubble-gum-at-an-amusement-park-1226-large.mp4');
  FlVideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      initializePlayer(_videoPlayerController1);
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> initializePlayer(
      VideoPlayerController videoPlayerController) async {
    await _controller?.pause();
    await _controller?.dispose(false);
    _controller = FlVideoPlayerController(
        videoPlayerController: videoPlayerController,
        autoPlay: true,
        looping: true,
        controls: videoPlayerController == _videoPlayerController1
            ? MaterialControls(
                hideDuration: const Duration(minutes: 30),
                enablePlay: true,
                enableFullscreen: true,
                enableSpeed: true,
                enableVolume: true,
                enableSubtitle: true,
                enablePosition: true,
                positionBuilder: (String position, String all) {
                  return Padding(
                      padding: const EdgeInsets.fromLTRB(6, 6, 0, 6),
                      child: Text('$position / $all',
                          style: const TextStyle(
                              fontSize: 16, color: Colors.red)));
                })
            : CupertinoControls(
                hideDuration: const Duration(minutes: 30),
                enableSpeed: true,
                enableSkip: true,
                enableSubtitle: true,
                enableFullscreen: true,
                enableVolume: true,
                enablePlay: true,
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
              text: 'Hello from subtitles'),
          Subtitle(
              index: 0,
              start: const Duration(seconds: 10),
              end: const Duration(seconds: 20),
              text: 'Whats up? :)'),
        ]));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Example')),
        body: SafeArea(
          bottom: true,
          child: Column(children: <Widget>[
            Expanded(
                child: _controller == null
                    ? const SizedBox()
                    : FlVideoPlayer(controller: _controller!)),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  ElevatedText(
                      onPressed: () {
                        if (_controller!.videoPlayerController !=
                            _videoPlayerController1) {
                          initializePlayer(_videoPlayerController1);
                        }
                      },
                      text: "Landscape Video"),
                  ElevatedText(
                      onPressed: () {
                        if (_controller!.videoPlayerController !=
                            _videoPlayerController2) {
                          initializePlayer(_videoPlayerController2);
                        }
                      },
                      text: 'Portrait Video')
                ]),
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
