# fl_video

为 [video_player](https://pub.dev/packages/video_player) 提供 Material 与 Cupertino 两种风格的控制面板，内置字幕、
倍速切换、快进快退、全屏、直播样式等能力。

- **Web 在线示例：<https://wayaer.github.io/fl_video/example/app/web/index.html#/>**
- pub.dev：<https://pub.dev/packages/fl_video>
- GitHub：<https://github.com/Wayaer/fl_video>

## 目录

- [快速开始](#快速开始)
- [核心类](#核心类)
- [数据模型与回调类型](#数据模型与回调类型)
- [内置组件](#内置组件)
- [自定义控制面板](#自定义控制面板)
- [使用说明](#使用说明)
- [平台支持](#平台支持)
- [示例](#示例)

## 快速开始

```yaml
dependencies:
  fl_video: ^2.0.0
```

```dart
class VideoPage extends StatefulWidget {
  const VideoPage({super.key});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  final controller = FlVideoPlayerController(
    videoPlayerController: VideoPlayerController.networkUrl(Uri.parse('https://example.com/video.mp4')),
    autoPlay: true,
    looping: true,
    // 也可换成 FlCupertinoControls() 使用 iOS 风格控制面板。
    controls: FlMaterialControls(),
  );

  @override
  void dispose() {
    // 默认同时释放底层播放器；需要保留底层播放器时传 controller.dispose(false)。
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FlVideoPlayer(controller: controller);
}
```

本库同时导出 `package:video_player` 与 `package:wakelock_plus` 的 API，`VideoPlayerController`、
`VideoPlayerValue`、`WakelockPlus` 等类型无需再单独 import。

## 核心类

### FlVideoPlayer

展示视频画面与控制面板的组件。

| 参数 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `controller` | `FlVideoPlayerController` | 是 | 播放器控制器 |

### FlVideoPlayerController

包装底层 `VideoPlayerController`，统一管理播放状态、字幕、全屏切换与自定义控件；
它转发底层播放器的全部状态变化，可直接作为 `Listenable` 使用。

构造参数：

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `videoPlayerController` | `VideoPlayerController` | — | 必填，底层播放器 |
| `autoInitialize` | `bool` | `false` | 创建后自动初始化 |
| `autoPlay` | `bool` | `false` | 初始化完成后自动播放（同样会触发初始化） |
| `startAt` | `Duration?` | `null` | 初始播放位置，初始化时生效（先跳转再播放） |
| `looping` | `bool` | `false` | 是否循环播放 |
| `fullScreenByDefault` | `bool` | `false` | 首次播放时自动进入全屏，只生效一次 |
| `controls` | `Widget?` | `null` | 控制面板，推荐 `FlMaterialControls` / `FlCupertinoControls` |
| `placeholder` | `Widget?` | `null` | 视频未初始化时显示的占位组件 |
| `overlay` | `Widget?` | `null` | 位于视频之上、控制面板之下的叠加组件 |
| `subtitle` | `FlSubtitles?` | `null` | 字幕数据 |
| `subtitleBuilder` | `FlSubtitlesBuilder?` | `null` | 自定义字幕渲染 |
| `showControlsOnInitialize` | `bool` | `true` | 初始化时短暂显示一次控制面板 |
| `allowedScreenSleep` | `bool` | `true` | 全屏时是否允许息屏；`false` 时保持屏幕常亮 |
| `isLive` | `bool` | `false` | 是否直播流 |
| `systemOverlaysOnEnterFullScreen` | `List<SystemUiOverlay>?` | `null` | 进入全屏时保留的系统 UI；`null` 表示隐藏全部 |
| `deviceOrientationsOnEnterFullScreen` | `List<DeviceOrientation>?` | `null` | 进入全屏时的屏幕方向；`null` 表示按视频宽高比自动选择 |
| `systemOverlaysAfterFullScreen` | `List<SystemUiOverlay>` | `SystemUiOverlay.values` | 退出全屏后恢复的系统 UI |
| `deviceOrientationsAfterFullScreen` | `List<DeviceOrientation>` | `[portraitUp]` | 退出全屏后恢复的屏幕方向 |
| `routePageBuilder` | `FlVideoPlayerRoutePageBuilder?` | `null` | 自定义全屏页面 |

方法：

| 方法 | 说明 |
| --- | --- |
| `initialize()` | 初始化视频；未初始化时才真正初始化，失败后允许重试，重复调用复用同一次初始化 |
| `play()` / `pause()` / `togglePause()` | 播放 / 暂停 / 切换；`pause()` 会记录“用户主动暂停” |
| `seekTo(Duration moment)` | 跳转到指定位置 |
| `setVolume(double volume)` | 设置音量（0.0 ~ 1.0） |
| `setPlaybackSpeed(double speed)` | 设置播放倍速 |
| `setLooping(bool looping)` | 设置循环播放 |
| `setSubtitle(List<FlSubtitle> newSubtitle)` | 替换字幕列表并通知刷新 |
| `updateConfig({...})` | 运行期更新 `controls` / `overlay` / `placeholder` / `subtitleBuilder` / `showControlsOnInitialize` / `allowedScreenSleep` / `isLive`，传 `null` 的项保持不变 |
| `enterFullScreen()` / `exitFullScreen()` / `toggleFullScreen()` | 进入 / 退出 / 切换全屏 |
| `dispose([bool disposeVideoPlayer = true])` | 释放控制器；默认同时释放底层播放器，传 `false` 保留底层播放器 |
| `FlVideoPlayerController.of(context)` | 静态方法，获取当前 `FlVideoPlayer` 的控制器 |

只读属性：`isInitialized`、`isPlaying`、`isBuffering`、`position`、`duration`、`hasError`、
`errorDescription`、`volume`、`buffered`、`playbackSpeed`、`value`、`isFullScreen`、`isLive`、
`subtitle`、`subtitleBuilder`、`controls`、`overlay`、`placeholder`、`showControlsOnInitialize`、
`allowedScreenSleep`、`lastUserPauseAt`、`configRevision`。

### FlMaterialControls

Material 风格控制面板：底部细进度条 + 播放/音量/位置/倍速/字幕/全屏按钮，点击画面淡入淡出。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `progressColors` | `FlVideoPlayerProgressColors` | Material 白色系配色 | 进度条配色 |
| `color` | `Color` | `Color(0xFFFFFFFF)` | 图标与文字颜色 |
| `backgroundColor` | `Color` | `Color(0x90000000)` | 圆形按钮与底部栏背景色 |
| `hideDuration` | `Duration` | `Duration(seconds: 4)` | 无操作后自动隐藏控制面板的时长 |
| `loading` | `Widget` | 白色 `CircularProgressIndicator` | 加载/缓冲时显示的组件 |
| `enablePlay` | `bool` | `true` | 是否显示播放/暂停按钮 |
| `enableVolume` | `bool` | `true` | 是否显示音量按钮 |
| `volumeON` / `volumeOFF` | `IconData` | `Icons.volume_up` / `Icons.volume_off` | 音量图标 |
| `enablePosition` | `bool` | `true` | 是否显示“当前位置 / 总时长”文本 |
| `positionBuilder` | `FlVideoPositionAndAllBuilder?` | `null` | 自定义位置文本 |
| `enableSpeed` | `bool` | `true` | 是否显示倍速按钮（默认展示当前倍数，如 `1X`） |
| `playbackSpeeds` | `List<double>` | `[0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2]` | 可选倍速列表（需全部大于 0） |
| `speedLabelBuilder` | `FlVideoSpeedLabelBuilder?` | `null` | 自定义倍速按钮文案 |
| `speedTitle` | `String` | `'Playback Speed'` | 内置倍速弹窗标题 |
| `speedConfig` | `FlVideoSpeedConfig?` | `null` | 自定义倍速弹窗（见下） |
| `enableSubtitle` | `bool` | `true` | 是否显示字幕按钮 |
| `subtitleOn` | `bool?` | `null` | 字幕初始开关；`null` 时按是否存在字幕自动决定 |
| `subtitleON` / `subtitleOFF` | `IconData` | `Icons.closed_caption` / `Icons.closed_caption_off_outlined` | 字幕开关图标 |
| `enableFullscreen` | `bool` | `true` | 是否显示全屏按钮 |
| `fullscreenON` / `fullscreenOFF` | `IconData` | `Icons.fullscreen` / `Icons.fullscreen_exit` | 全屏图标 |
| `enableDoubleTap` | `bool` | `false` | 是否启用双击画面切换播放/暂停 |
| `enableBottomBar` | `bool` | `true` | 是否显示底部控制栏 |
| `isLive` | `bool` | `false` | 直播样式：隐藏进度条，位置区域显示直播标识 |
| `liveBuilder` | `WidgetBuilder?` | `null` | 自定义直播标识（默认显示 `LIVE` 文本） |
| `error` | `IconData` | `Icons.error` | 错误提示图标 |
| `errorBuilder` | `FlVideoControlsErrorBuilder?` | `null` | 自定义错误界面 |
| `onTap` | `FlVideoControlsTap?` | `null` | 点击控制面板元素时的回调 |
| `onDragProgress` | `FlVideoControlsProgressDrag?` | `null` | 拖动进度条开始/结束时回调 |

### FlCupertinoControls

iOS 风格控制面板：圆角底部控制栏 + 快退/播放/快进、当前位置与剩余时间、粗进度条、倍速、字幕、全屏；
倍速弹窗为 iOS 操作表，播放/音量为带半透明底的可点击图标。

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `progressColors` | `FlVideoPlayerProgressColors` | Cupertino 白色系配色 | 进度条配色 |
| `color` | `Color` | `Color(0xFFFFFFFF)` | 图标与文字颜色 |
| `backgroundColor` | `Color` | `Color(0x90000000)` | 圆形按钮与底部栏背景色 |
| `hideDuration` | `Duration` | `Duration(seconds: 4)` | 无操作后自动隐藏控制面板的时长 |
| `loading` | `Widget` | 白色 `CircularProgressIndicator` | 加载/缓冲时显示的组件 |
| `enablePlay` | `bool` | `true` | 是否显示播放/暂停按钮 |
| `enableSkip` | `bool` | `true` | 是否显示快退/快进按钮 |
| `skipBack` / `skipForward` | `IconData` | `CupertinoIcons.gobackward_15` / `goforward_15` | 快退/快进图标 |
| `skipDuration` | `Duration` | `Duration(seconds: 15)` | 快进/快退跳转时长（需大于 0） |
| `enableVolume` | `bool` | `true` | 是否显示音量按钮 |
| `volumeON` / `volumeOFF` | `IconData` | `CupertinoIcons.speaker_2_fill` / `speaker_slash_fill` | 音量图标 |
| `enablePosition` | `bool` | `true` | 是否显示当前位置文本 |
| `positionBuilder` | `FlVideoPositionBuilder?` | `null` | 自定义当前位置文本 |
| `enableRemaining` | `bool` | `true` | 是否显示剩余时间文本 |
| `remainingBuilder` | `FlVideoRemainingBuilder?` | `null` | 自定义剩余时间文本 |
| `enableSpeed` | `bool` | `true` | 是否显示倍速按钮（默认展示当前倍数，如 `1x`） |
| `playbackSpeeds` | `List<double>` | `[0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2]` | 可选倍速列表（需全部大于 0） |
| `speedLabelBuilder` | `FlVideoSpeedLabelBuilder?` | `null` | 自定义倍速按钮文案 |
| `speedTitle` | `String` | `'Playback Speed'` | 内置倍速操作表标题 |
| `speedCancelLabel` | `String?` | `null` | 操作表取消按钮文案；`null` 时使用系统本地化文案（如 `Cancel` / `取消`） |
| `speedConfig` | `FlVideoSpeedConfig?` | `null` | 自定义倍速弹窗（见下） |
| `enableSubtitle` | `bool` | `true` | 是否显示字幕按钮 |
| `subtitleOn` | `bool?` | `null` | 字幕初始开关；`null` 时按是否存在字幕自动决定 |
| `subtitleON` / `subtitleOFF` | `IconData` | `CupertinoIcons.captions_bubble_fill` / `captions_bubble` | 字幕开关图标 |
| `enableFullscreen` | `bool` | `true` | 是否显示全屏按钮 |
| `fullscreenON` / `fullscreenOFF` | `IconData` | `CupertinoIcons.arrow_up_left_arrow_down_right` / `arrow_down_right_arrow_up_left` | 全屏图标 |
| `enableDoubleTap` | `bool` | `false` | 是否启用双击画面切换播放/暂停 |
| `enableBottomBar` | `bool` | `true` | 是否显示底部控制栏 |
| `isLive` | `bool` | `false` | 直播样式：只保留播放按钮与直播标识 |
| `liveBuilder` | `WidgetBuilder?` | `null` | 自定义直播标识（默认显示 `LIVE` 文本） |
| `error` | `IconData` | `CupertinoIcons.exclamationmark_circle` | 错误提示图标 |
| `errorBuilder` | `FlVideoControlsErrorBuilder?` | `null` | 自定义错误界面 |
| `onTap` | `FlVideoControlsTap?` | `null` | 点击控制面板元素时的回调 |
| `onDragProgress` | `FlVideoControlsProgressDrag?` | `null` | 拖动进度条开始/结束时回调 |

## 数据模型与回调类型

### FlVideoPlayerProgressColors

进度条配色，四个字段：`played`（已播放）、`buffered`（已缓冲）、`handle`（拖动手柄）、`background`（背景）。

```dart
const FlVideoPlayerProgressColors(
  played: Color(0x80FFFFFF),
  buffered: Color(0x55FFFFFF),
  handle: Color(0xFFFFFFFF),
  background: Color(0x35FFFFFF),
)
```

### FlVideoSpeedConfig

倍速选择自定义配置，两种方式二选一，同时传入时 `onSelect` 优先：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `onSelect` | `FlVideoSpeedSelect?` | 完全接管点击事件：弹窗的展示与关闭都由外部处理，返回所选倍速，返回 `null` 表示取消 |
| `contentBuilder` | `FlVideoSpeedContentBuilder?` | 只替换弹窗内部内容，弹窗容器（Material 底部弹窗 / iOS 操作表）仍由控制面板提供 |

```dart
// 只换弹窗内容
FlVideoSpeedConfig(
  contentBuilder: (BuildContext context, List<double> speeds, double selected, ValueChanged<double> onSelected) {
    return Wrap(
      children: [
        for (final double speed in speeds) TextButton(onPressed: () => onSelected(speed), child: Text('$speed')),
      ],
    );
  },
)

// 完全接管点击与弹窗展示
FlVideoSpeedConfig(
  onSelect: (BuildContext context, List<double> speeds, double selected) {
    return showDialog<double>(context: context, builder: (BuildContext context) => ...);
  },
)
```

### 字幕：FlSubtitles / FlSubtitle

```dart
FlSubtitles(<FlSubtitle?>[
  FlSubtitle(index: 0, start: Duration.zero, end: const Duration(seconds: 10), text: '第一段字幕'),
  FlSubtitle(index: 1, start: const Duration(seconds: 10), end: const Duration(seconds: 20), text: '第二段字幕'),
])
```

- `FlSubtitles.subtitle`：字幕列表，允许包含 `null`（表示该条字幕缺失）。
- `FlSubtitles.getByPosition(Duration position)`：取当前应显示的字幕，区间为 `[start, end)`。
- `FlSubtitles.isEmpty` / `isNotEmpty`：是否有字幕。
- `FlSubtitle`：字段为 `index`、`start`、`end`、`text`；提供 `copyWith({index, start, end, text})`，
  并重写了 `==` / `hashCode` / `toString`。
- 运行期更新字幕用 `controller.setSubtitle(List<FlSubtitle>)`，会通知控制面板刷新。

### FlVideoTapEvent

控制面板上可点击区域的事件类型（配合 `onTap` 使用）：
`largePlayPause`（画面中央大按钮）、`playPause`（底部播放/暂停）、`volume`、`position`、`remaining`
（仅 `FlCupertinoControls`）、`speed`、`subtitle`、`fullscreen`、`progress`（点击进度条完成跳转）、
`error`、`loading`、`skipBack` / `skipForward`（仅 `FlCupertinoControls`）。

### FlVideoDragProgressEvent

进度条拖拽事件类型：`start`（开始拖拽）、`end`（结束拖拽或取消）。

### 回调类型（typedef）

| 类型 | 签名 | 用途 |
| --- | --- | --- |
| `FlVideoControlsTap` | `void Function(FlVideoTapEvent event, FlVideoPlayerController controller)` | 点击控制面板元素 |
| `FlVideoControlsProgressDrag` | `void Function(FlVideoDragProgressEvent event, Duration duration)` | 进度条拖动开始/结束 |
| `FlVideoPositionAndAllBuilder` | `Widget Function(String position, String all)` | Material 位置文本 |
| `FlVideoPositionBuilder` | `Widget Function(String position)` | Cupertino 当前位置文本 |
| `FlVideoRemainingBuilder` | `Widget Function(String remaining)` | Cupertino 剩余时间文本 |
| `FlVideoControlsErrorBuilder` | `Widget Function(BuildContext context, String errorMessage)` | 自定义错误界面 |
| `FlVideoSpeedSelect` | `Future<double?> Function(BuildContext context, List<double> speeds, double selected)` | 完全自定义倍速选择流程 |
| `FlVideoSpeedContentBuilder` | `Widget Function(BuildContext context, List<double> speeds, double selected, ValueChanged<double> onSelected)` | 自定义倍速弹窗内容 |
| `FlVideoSpeedLabelBuilder` | `String Function(double speed)` | 自定义倍速按钮文案 |
| `FlSubtitlesBuilder` | `Widget Function(BuildContext context, String subtitle)` | 自定义字幕渲染 |
| `FlVideoPlayerRoutePageBuilder` | `Widget Function(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, FlVideoPlayerControllerProvider controllerProvider)` | 自定义全屏页面 |

### 格式化扩展

| 扩展 | 方法 | 说明 |
| --- | --- | --- |
| `FlVideoDurationExtension`（`Duration`） | `formatDuration()` | 格式化为 `mm:ss`，达到 1 小时时格式化为 `hh:mm:ss`；负数按 0 处理 |
| `FlVideoDoubleExtension`（`double`） | `formatPlaybackSpeed({String suffix = 'X'})` | 格式化为倍速文案，整数不带小数（`1X`、`1.5X`）；传 `suffix: 'x'` 得到 iOS 风格的 `1x` |

## 内置组件

以下组件均已对外导出，可直接用于自定义控制面板：

| 组件 | 构造参数 | 说明 |
| --- | --- | --- |
| `FlVideoProgressBar` | `(VideoPlayerController controller, {colors, onDragStart, onDragEnd, onTap, barHeight, handleHeight, drawShadow})` | 可点击、可拖动的进度条；拖动时 60ms 节流 seek，取消拖动会恢复播放 |
| `FlCenterPlayButton` | `({backgroundColor, iconColor, show, isPlaying, isFinished, onPressed})` | 画面中央的播放/暂停按钮，`show` 为 false 时淡出且不响应点击 |
| `FlAnimatedPlayPause` | `({playing, size, color})` | 播放/暂停图标间的隐式动画 |
| `FlDefaultIcon` | `(IconData icon, {size = 22, color})` | 控制面板默认尺寸图标 |
| `FlDefaultError` | `({color, error, onTap, semanticLabel})` | 默认播放错误提示 |
| `FlPlaybackSpeedDialog` | `({title, speeds, selected, onSelected})` | Material 内置倍速弹窗内容（标题 + 可选中的倍速胶囊） |
| `FlPlayerNotifier` | `FlPlayerNotifier.init` | 控制面板显隐状态通知器，仅供内置控制面板使用 |

## 自定义控制面板

`FlVideoPlayerController.controls` 接受任意 `Widget`，任意子树内可用 `FlVideoPlayerController.of(context)`
取到控制器；把内置组件拼起来即可实现自己的控制面板：

```dart
class MyControls extends StatelessWidget {
  const MyControls({super.key});

  @override
  Widget build(BuildContext context) {
    final FlVideoPlayerController controller = FlVideoPlayerController.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) => Row(
        children: [
          IconButton(
            onPressed: controller.togglePause,
            icon: Icon(controller.isPlaying ? Icons.pause : Icons.play_arrow),
          ),
          Expanded(child: FlVideoProgressBar(controller.videoPlayerController, barHeight: 3, handleHeight: 6, drawShadow: false)),
          Text(controller.position.formatDuration()),
        ],
      ),
    );
  }
}
```

## 使用说明

- 2.x 基于 Flutter 3.47 拆分出的 `material_ui` 与 `cupertino_ui` 包，宿主 App 需先完成迁移
  （`dart fix --apply --code=migrate_design_widgets`）；仍使用 `package:flutter/material.dart` 的项目请继续使用 1.5.0。
- 由播放器创建并持有的底层 `VideoPlayerController`，销毁时调用 `controller.dispose()` 即可释放底层播放器；
  需要保留底层播放器时传 `controller.dispose(false)`。
- 仅当 `autoInitialize` 或 `autoPlay` 为 true 时构造后会自动初始化，否则可随时手动调用 `controller.initialize()`；
  初始化失败后再次调用会重新初始化。
- 退出全屏会按 `systemOverlaysAfterFullScreen` 和 `deviceOrientationsAfterFullScreen` 恢复系统 UI 和屏幕方向；
  屏幕方向默认恢复为竖屏（仅 `portraitUp`），横屏优先或需要保持可旋转的应用请显式传入所需方向（例如 `DeviceOrientation.values`）。
- `FlMaterialControls` / `FlCupertinoControls` 默认在存在字幕时开启字幕，可用 `subtitleOn` 固定初始开关。
- 两种面板的倍速按钮都直接显示当前倍数：Material 用 `1X` 风格，Cupertino 用 iOS 风格的 `1x`，
  选择后回显所选倍数；文案可用 `speedLabelBuilder` 自定义。
- 倍速弹窗沿用各自平台的风格：Material 是带标题的底部弹窗（`speedTitle` 可改标题），
  Cupertino 是 iOS 操作表（列出倍数、当前项带勾选，标题用 `speedTitle`、取消文案用 `speedCancelLabel`
  自定义，取消文案默认为系统本地化文案）；两者都可用 `speedConfig` 自定义。
- `FlMaterialControls` / `FlCupertinoControls` 默认不启用双击播放/暂停，传入 `enableDoubleTap: true` 后双击画面即可切换播放与暂停。
- 直播样式的标识可用 `liveBuilder` 自定义，默认显示 `LIVE` 文本。
- `FlCupertinoControls` 的快进/快退跳转时长由 `skipDuration` 控制（默认 15 秒），修改后请同步替换
  `skipForward` / `skipBack` 图标以匹配文案。
- 运行期想换控制面板、叠加层或占位组件，用 `controller.updateConfig(...)`（会通知刷新），
  不需要重建控制器；`controls` / `overlay` / `placeholder` 不做更新时可传 `SizedBox.shrink()` 移除。
- 控制面板按钮均带有无障碍 `Semantics` 标签，进度条点击会上报 `FlVideoTapEvent.progress`。

## 平台支持

| 平台 | 说明 |
| --- | --- |
| iOS / Android | 完整支持，含屏幕方向、系统 UI 隐藏与屏幕常亮 |
| Web | 支持播放与控制面板；屏幕方向、系统 UI 与常亮由 `SystemChrome` / `wakelock_plus` 静默忽略 |
| 桌面端（macOS / Windows / Linux） | 同 Web，方向与常亮静默忽略 |

## 示例

- **Web 在线示例：<https://wayaer.github.io/fl_video/example/app/web/index.html#/>**
- 本地运行：`cd example && flutter run`（示例支持切换横屏 1280x720 / 竖屏 720x1280 两种视频）
- 示例覆盖：Material 控制面板、Cupertino 控制面板、自定义倍速弹窗（Material / Cupertino）、
  直播样式（Material / Cupertino）、全屏优先（Material / Cupertino）、原生 VideoPlayer 对照，共 9 个场景。

## License

[MIT](LICENSE)
