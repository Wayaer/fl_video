import 'package:material_ui/material_ui.dart';

/// 示例的功能类型。
enum VideoDemoKind {
  /// 标准控制面板
  normal,

  /// 自定义倍速弹窗
  customSpeed,

  /// 直播样式（不显示进度条）
  live,

  /// 进入后直接全屏播放
  fullScreen,

  /// 原生 VideoPlayer，无控制面板
  plain,
}

/// 控制面板样式。
enum VideoDemoStyle {
  /// Material 风格
  material,

  /// Cupertino 风格
  cupertino,

  /// 不使用控制面板
  none,
}

/// 单个示例条目。
class VideoDemo {
  const VideoDemo({
    required this.kind,
    required this.style,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.tags,
  });

  /// 示例的功能类型。
  final VideoDemoKind kind;

  /// 控制面板样式。
  final VideoDemoStyle style;

  /// 标题。
  final String title;

  /// 列表中的一行简介。
  final String subtitle;

  /// 播放页展示的详细说明。
  final String description;

  /// 列表图标。
  final IconData icon;

  /// 涉及的功能标签。
  final List<String> tags;

  /// 竖屏视频资源（720x1280），播放页可随时切换到横屏资源。
  static const String portraitAsset = 'assets/v.mp4';

  /// 横屏视频资源（1280x720），播放页可随时切换到竖屏资源。
  static const String landscapeAsset = 'assets/h.mp4';
}

/// 内置示例列表：功能类型与控制面板样式交叉展示；每个示例都可在播放页切换横竖屏视频。
const List<VideoDemo> videoDemos = [
  VideoDemo(
    kind: VideoDemoKind.normal,
    style: VideoDemoStyle.material,
    title: 'Material 控制面板',
    subtitle: '完整功能与字幕演示',
    description: '使用 FlMaterialControls，包含播放、音量、进度拖动、倍速按钮（显示当前倍数）、双击暂停、字幕和全屏。',
    icon: Icons.play_circle_outline,
    tags: ['横竖屏切换', '字幕', '倍速回显 1X', '双击暂停', '全屏'],
  ),
  VideoDemo(
    kind: VideoDemoKind.normal,
    style: VideoDemoStyle.cupertino,
    title: 'Cupertino 控制面板',
    subtitle: 'iOS 风格控制条',
    description: '使用 FlCupertinoControls，前进/后退 10 秒、双击暂停、自定义时间文本，倍速按钮显示当前倍数。',
    icon: Icons.phone_iphone,
    tags: ['横竖屏切换', '快进快退 10 秒', '双击暂停', '倍速回显 1X'],
  ),
  VideoDemo(
    kind: VideoDemoKind.customSpeed,
    style: VideoDemoStyle.material,
    title: '自定义倍速弹窗 · Material',
    subtitle: '居中对话框，完全接管点击',
    description: '通过 speedConfig.onSelect 接管倍速按钮：自行用 showDialog 展示居中对话框，并把所选倍速返回给播放器。',
    icon: Icons.speed,
    tags: ['横竖屏切换', 'speedConfig', '居中对话框', '倍速回显'],
  ),
  VideoDemo(
    kind: VideoDemoKind.customSpeed,
    style: VideoDemoStyle.cupertino,
    title: '自定义倍速弹窗 · Cupertino',
    subtitle: 'iOS 风格自定义面板',
    description: '通过 speedConfig.onSelect 接管倍速按钮：自行用 showCupertinoModalPopup 展示毛玻璃面板与胶囊倍数按钮。',
    icon: Icons.tune,
    tags: ['横竖屏切换', 'speedConfig', '毛玻璃面板', '倍速回显'],
  ),
  VideoDemo(
    kind: VideoDemoKind.live,
    style: VideoDemoStyle.material,
    title: '直播样式 · Material',
    subtitle: '隐藏进度条，自定义直播标识',
    description: 'Material 面板将 isLive 设为 true，隐藏进度条并用 liveBuilder 自定义直播标识。',
    icon: Icons.podcasts,
    tags: ['横竖屏切换', 'isLive', '无进度条', '自定义直播标识'],
  ),
  VideoDemo(
    kind: VideoDemoKind.live,
    style: VideoDemoStyle.cupertino,
    title: '直播样式 · Cupertino',
    subtitle: 'iOS 风格直播控制条',
    description: 'Cupertino 面板同样支持 isLive 参数，隐藏进度条并用 liveBuilder 自定义直播标识。',
    icon: Icons.podcasts,
    tags: ['横竖屏切换', 'isLive', '无进度条', '自定义直播标识'],
  ),
  VideoDemo(
    kind: VideoDemoKind.fullScreen,
    style: VideoDemoStyle.material,
    title: '全屏优先 · Material',
    subtitle: '进入即全屏播放',
    description: 'Material 面板配合 fullScreenByDefault，播放开始后自动进入全屏页面；切换横屏视频可验证全屏方向。',
    icon: Icons.fullscreen,
    tags: ['横竖屏切换', 'fullScreenByDefault', '自动全屏'],
  ),
  VideoDemo(
    kind: VideoDemoKind.fullScreen,
    style: VideoDemoStyle.cupertino,
    title: '全屏优先 · Cupertino',
    subtitle: '进入即全屏播放',
    description: 'Cupertino 面板配合 fullScreenByDefault，播放开始后自动进入全屏页面；切换横屏视频可验证全屏方向。',
    icon: Icons.fullscreen,
    tags: ['横竖屏切换', 'fullScreenByDefault', '自动全屏'],
  ),
  VideoDemo(
    kind: VideoDemoKind.plain,
    style: VideoDemoStyle.none,
    title: '原生 VideoPlayer',
    subtitle: '仅使用底层播放器',
    description: '不使用控制面板，直接使用 video_player 的 VideoPlayer 和自定义按钮。',
    icon: Icons.smart_display_outlined,
    tags: ['横竖屏切换', 'VideoPlayer', '自定义 UI'],
  ),
];
