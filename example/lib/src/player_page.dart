import 'package:app/src/demo.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:fl_video/fl_video.dart';
import 'package:material_ui/material_ui.dart';

/// 播放页：按示例类型创建播放器，并在下方展示说明。
class PlayerPage extends StatefulWidget {
  const PlayerPage({required this.demo, super.key});

  /// 当前演示的示例条目。
  final VideoDemo demo;

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  FlVideoPlayerController? controller;

  /// 当前播放的是否为横屏视频；默认竖屏。
  bool isLandscape = false;

  /// 当前使用的视频资源。
  String get asset => isLandscape ? VideoDemo.landscapeAsset : VideoDemo.portraitAsset;

  @override
  void initState() {
    super.initState();
    controller = _createController();
  }

  @override
  void dispose() {
    // 由本页创建的控制器与底层播放器一并释放（dispose 默认会释放底层播放器）。
    controller?.dispose();
    super.dispose();
  }

  /// 切换横竖屏视频：用新资源重建控制器，并释放旧控制器。
  void _switchOrientation({required bool landscape}) {
    if (landscape == isLandscape) return;
    final FlVideoPlayerController? old = controller;
    setState(() {
      isLandscape = landscape;
      controller = _createController();
    });
    old?.dispose();
  }

  /// 窄屏时只保留图标，避免标题被挤压。
  Widget? _orientationLabel(BuildContext context, String text) {
    return MediaQuery.sizeOf(context).width < 380 ? null : Text(text);
  }

  /// 按示例类型和样式创建控制器；原生 VideoPlayer 示例直接使用底层播放器，返回 null。
  FlVideoPlayerController? _createController() {
    final VideoDemo demo = widget.demo;
    if (demo.kind == VideoDemoKind.plain) return null;
    final VideoPlayerController video = VideoPlayerController.asset(asset);
    final bool isLive = demo.kind == VideoDemoKind.live;
    final bool isCustomSpeed = demo.kind == VideoDemoKind.customSpeed;
    final bool isNormal = demo.kind == VideoDemoKind.normal || isCustomSpeed;
    final Widget controls = demo.style == VideoDemoStyle.cupertino
        ? FlCupertinoControls(
            hideDuration: const Duration(seconds: 5),
            isLive: isLive,
            positionBuilder: (String position) => _TimeText(text: position),
            remainingBuilder: (String remaining) => _TimeText(text: '-$remaining'),
            enableDoubleTap: isNormal,
            enableSpeed: !isLive,
            enableSubtitle: isNormal,
            liveBuilder: isLive ? buildLiveBadge : null,
            // iOS 风格倍速操作表的标题与取消文案，默认分别是英文 Playback Speed 与系统本地化文案。
            speedTitle: '播放速度',
            speedCancelLabel: '取消',
            skipDuration: const Duration(seconds: 10),
            skipForward: CupertinoIcons.goforward_10,
            skipBack: CupertinoIcons.gobackward_10,
            // 自定义倍速示例完全接管点击（onSelect），其余示例使用内置倍速选项。
            speedConfig: isCustomSpeed ? FlVideoSpeedConfig(onSelect: showCupertinoSpeedPicker) : null,
          )
        : FlMaterialControls(
            hideDuration: const Duration(seconds: 5),
            isLive: isLive,
            enableDoubleTap: isNormal,
            enableSpeed: !isLive,
            enableSubtitle: isNormal,
            liveBuilder: isLive ? buildLiveBadge : null,
            // 内置倍速弹窗的标题，默认为英文 Playback Speed。
            speedTitle: '播放速度',
            // 自定义倍速示例完全接管点击（onSelect），其余示例使用内置倍速弹窗。
            speedConfig: isCustomSpeed ? FlVideoSpeedConfig(onSelect: showMaterialSpeedPicker) : null,
            onTap: (FlVideoTapEvent event, FlVideoPlayerController controller) => debugPrint('onTap: $event'),
            onDragProgress: (FlVideoDragProgressEvent event, Duration duration) =>
                debugPrint('onDragProgress: $event $duration'),
          );
    return FlVideoPlayerController(
      videoPlayerController: video,
      autoPlay: true,
      looping: true,
      isLive: isLive,
      fullScreenByDefault: demo.kind == VideoDemoKind.fullScreen,
      overlay: isNormal ? const _DemoOverlay() : null,
      placeholder: const _DemoPlaceholder(),
      controls: controls,
      subtitle: isNormal ? _demoSubtitles : null,
    );
  }

  /// 自定义直播标识：红色「直播中」胶囊。
  Widget buildLiveBadge(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(4)),
    child: const Text('直播中', style: TextStyle(color: Colors.white, fontSize: 12)),
  );

  /// 完全自定义的 Material 倍速弹窗：居中对话框，展示与关闭全部由本方法负责。
  Future<double?> showMaterialSpeedPicker(BuildContext context, List<double> speeds, double selected) {
    return showDialog<double>(
      context: context,
      builder: (BuildContext dialogContext) {
        final ColorScheme scheme = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.speed, color: scheme.primary),
              const SizedBox(width: 8),
              const Text('选择播放速度'),
            ],
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: speeds.map((double speed) {
                final bool active = speed == selected;
                return ListTile(
                  selected: active,
                  leading: Icon(
                    active ? Icons.check_circle : Icons.circle_outlined,
                    color: active ? scheme.primary : null,
                  ),
                  title: Text('${speed}x'),
                  trailing: active ? Text('当前', style: TextStyle(color: scheme.primary, fontSize: 12)) : null,
                  onTap: () => Navigator.of(dialogContext).pop(speed),
                );
              }).toList(),
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('取消'))],
        );
      },
    );
  }

  /// 完全自定义的 iOS 倍速弹窗：模糊面板 + 胶囊倍数按钮，展示与关闭全部由本方法负责。
  Future<double?> showCupertinoSpeedPicker(BuildContext context, List<double> speeds, double selected) {
    return showCupertinoModalPopup<double>(
      context: context,
      builder: (BuildContext popupContext) {
        final Color primaryColor = CupertinoTheme.of(popupContext).primaryColor;
        final Color surfaceColor = CupertinoColors.systemBackground.resolveFrom(popupContext);
        // 弹窗内没有 Material 祖先，显式提供默认文字样式，避免 Text 落到报错样式（红字 + 黄下划线）。
        return DefaultTextStyle(
          style: TextStyle(color: CupertinoColors.label.resolveFrom(popupContext), fontSize: 15),
          child: Center(
            child: CupertinoPopupSurface(
              child: Container(
                width: 300,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                decoration: BoxDecoration(
                  color: surfaceColor.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('选择播放速度', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 10,
                      children: speeds.map((double speed) {
                        final bool active = speed == selected;
                        return CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          minimumSize: Size.zero,
                          borderRadius: BorderRadius.circular(999),
                          color: active ? primaryColor : CupertinoColors.tertiarySystemFill.resolveFrom(popupContext),
                          onPressed: () => Navigator.of(popupContext).pop(speed),
                          child: Text(
                            // iOS 风格倍数文案：整数不带小数（1x），其余保持原样（1.5x）。
                            speed == speed.truncateToDouble() ? '${speed.toInt()}x' : '${speed}x',
                            style: TextStyle(fontSize: 15, color: active ? CupertinoColors.white : null),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final FlVideoPlayerController? playerController = controller;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.demo.title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SegmentedButton<bool>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: Colors.white70,
                selectedForegroundColor: Colors.white,
                selectedBackgroundColor: Colors.white24,
                side: const BorderSide(color: Colors.white24),
              ),
              segments: [
                ButtonSegment<bool>(
                  value: false,
                  tooltip: '竖屏视频 720x1280',
                  icon: const Icon(Icons.stay_current_portrait, size: 18),
                  label: _orientationLabel(context, '竖屏'),
                ),
                ButtonSegment<bool>(
                  value: true,
                  tooltip: '横屏视频 1280x720',
                  icon: const Icon(Icons.stay_current_landscape, size: 18),
                  label: _orientationLabel(context, '横屏'),
                ),
              ],
              selected: {isLandscape},
              onSelectionChanged: (Set<bool> selection) => _switchOrientation(landscape: selection.first),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: playerController == null
                ? _PlainVideoPlayer(key: ValueKey<String>(asset), asset: asset)
                : FlVideoPlayer(controller: playerController),
          ),
          _InfoPanel(demo: widget.demo, isLandscape: isLandscape),
        ],
      ),
    );
  }
}

/// 示例字幕：前 20 秒交替显示两段文本。
FlSubtitles get _demoSubtitles => FlSubtitles([
  FlSubtitle(index: 0, start: Duration.zero, end: const Duration(seconds: 10), text: '示例字幕 · 第一段'),
  FlSubtitle(index: 0, start: const Duration(seconds: 10), end: const Duration(seconds: 20), text: '示例字幕 · 第二段'),
]);

/// 叠加在视频上方的示例内容。
class _DemoOverlay extends StatelessWidget {
  const _DemoOverlay();

  @override
  Widget build(BuildContext context) => const IgnorePointer(
    child: Padding(
      padding: EdgeInsets.only(top: 12),
      child: Align(
        alignment: Alignment.topCenter,
        child: Text('overlay', style: TextStyle(color: Colors.lightBlueAccent, fontSize: 14)),
      ),
    ),
  );
}

/// 视频未初始化时显示的占位内容。
class _DemoPlaceholder extends StatelessWidget {
  const _DemoPlaceholder();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.hourglass_empty, color: Colors.white54, size: 32),
        SizedBox(height: 8),
        Text('placeholder', style: TextStyle(color: Colors.white54)),
      ],
    ),
  );
}

/// 自定义时间文本。
class _TimeText extends StatelessWidget {
  const _TimeText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(999)),
    child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
  );
}

/// 播放页底部的说明面板。
class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.demo, required this.isLandscape});

  final VideoDemo demo;

  /// 当前是否为横屏视频。
  final bool isLandscape;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(demo.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(demo.description, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoTag(text: isLandscape ? '横屏视频 1280x720' : '竖屏视频 720x1280', theme: theme),
              ...demo.tags.map((String tag) => _InfoTag(text: tag, theme: theme)),
            ],
          ),
        ],
      ),
    );
  }
}

/// 说明面板上的功能标签。
class _InfoTag extends StatelessWidget {
  const _InfoTag({required this.text, required this.theme});

  final String text;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(text, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
  );
}

/// 原生 VideoPlayer 示例：不使用控制面板，自行控制播放。
class _PlainVideoPlayer extends StatefulWidget {
  const _PlainVideoPlayer({required this.asset, super.key});

  final String asset;

  @override
  State<_PlainVideoPlayer> createState() => _PlainVideoPlayerState();
}

class _PlainVideoPlayerState extends State<_PlainVideoPlayer> {
  late final VideoPlayerController controller = VideoPlayerController.asset(widget.asset);

  @override
  void initState() {
    super.initState();
    controller.addListener(_onUpdate);
    _initialize();
  }

  /// 初始化后自动循环播放，失败时仅打印日志。
  Future<void> _initialize() async {
    try {
      await controller.initialize();
      if (!mounted) return;
      await controller.setLooping(true);
      await controller.play();
      setState(() {});
    } catch (error) {
      debugPrint('VideoPlayer initialize error: $error');
    }
  }

  @override
  void dispose() {
    controller.removeListener(_onUpdate);
    controller.dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        Center(
          child: AspectRatio(aspectRatio: controller.value.aspectRatio, child: VideoPlayer(controller)),
        ),
        IconButton.filledTonal(
          iconSize: 32,
          onPressed: () {
            if (controller.value.isPlaying) {
              controller.pause();
            } else {
              controller.play();
            }
          },
          icon: Icon(controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
        ),
      ],
    );
  }
}
