import 'package:fl_video/fl_video.dart';
import 'package:material_ui/material_ui.dart';

/// 控制面板点击回调：事件类型 + 当前控制器。
typedef FlVideoControlsTap = void Function(FlVideoTapEvent event, FlVideoPlayerController controller);

/// 进度条拖拽回调：拖拽状态 + 当前播放位置。
typedef FlVideoControlsProgressDrag = void Function(FlVideoDragProgressEvent event, Duration duration);

/// 构建“当前位置 / 总时长”文本。
typedef FlVideoPositionAndAllBuilder = Widget Function(String position, String all);

/// 构建当前位置文本。
typedef FlVideoPositionBuilder = Widget Function(String position);

/// 构建剩余时间文本。
typedef FlVideoRemainingBuilder = Widget Function(String remaining);

/// 构建播放错误界面。
typedef FlVideoControlsErrorBuilder = Widget Function(BuildContext context, String errorMessage);

/// 完全自定义倍速选择流程，返回所选倍速，返回 null 表示取消。
typedef FlVideoSpeedSelect = Future<double?> Function(BuildContext context, List<double> speeds, double selected);

/// 自定义倍速弹窗内容；调用 [onSelected] 会关闭弹窗并应用所选倍速。
typedef FlVideoSpeedContentBuilder = Widget Function(
  BuildContext context,
  List<double> speeds,
  double selected,
  ValueChanged<double> onSelected,
);

/// 构建倍速按钮上展示的倍数文案，例如 `1X`、`1.5X`。
typedef FlVideoSpeedLabelBuilder = String Function(double speed);

/// 倍速弹窗自定义配置。
///
/// 两种方式二选一，同时传入时 [onSelect] 优先：
/// - [onSelect]：完全接管点击事件，弹窗的展示与关闭都由外部处理；
/// - [contentBuilder]：只替换弹窗内部内容，底部弹窗容器仍由控制面板提供。
class FlVideoSpeedConfig {
  const FlVideoSpeedConfig({this.onSelect, this.contentBuilder});

  /// 完全自定义倍速选择流程。
  ///
  /// 外部自行展示弹窗，并返回用户选择的倍速；返回 null 表示取消。
  /// 传入后控制面板不再展示任何默认弹窗。
  final FlVideoSpeedSelect? onSelect;

  /// 仅自定义弹窗内部内容，弹窗容器仍由控制面板负责；仅在 [onSelect] 为空时生效。
  final FlVideoSpeedContentBuilder? contentBuilder;
}

/// 进度条拖拽事件类型。
enum FlVideoDragProgressEvent {
  /// 开始拖拽
  start,

  /// 结束拖拽
  end,
}

/// 控制面板上可点击的区域。
enum FlVideoTapEvent {
  /// 画面中心的大播放/暂停按钮
  largePlayPause,

  /// 底部播放/暂停按钮
  playPause,

  /// 音量按钮
  volume,

  /// 播放位置文本
  position,

  /// 剩余时间文本（仅 FlCupertinoControls）
  remaining,

  /// 倍速按钮
  speed,

  /// 字幕按钮
  subtitle,

  /// 全屏按钮
  fullscreen,

  /// 点击进度条并完成跳转
  progress,

  /// 错误提示区域
  error,

  /// 加载中区域
  loading,

  /// 快退一段（时长由 FlCupertinoControls.skipDuration 控制，仅 FlCupertinoControls）
  skipBack,

  /// 快进一段（时长由 FlCupertinoControls.skipDuration 控制，仅 FlCupertinoControls）
  skipForward,
}

/// 进度条配色。
class FlVideoPlayerProgressColors {
  const FlVideoPlayerProgressColors({
    this.played = const Color(0xb2ff0000),
    this.buffered = const Color(0x331e1ec8),
    this.handle = const Color(0xffc8c8c8),
    this.background = const Color(0x7fc8c8c8),
  });

  /// 已播放部分颜色。
  final Color played;

  /// 已缓冲部分颜色。
  final Color buffered;

  /// 拖动手柄颜色。
  final Color handle;

  /// 进度条背景色。
  final Color background;
}

/// 字幕集合。
class FlSubtitles {
  FlSubtitles(this.subtitle);

  /// 字幕列表，允许包含 null（表示该条字幕缺失）。
  final List<FlSubtitle?> subtitle;

  /// 是否没有字幕。
  bool get isEmpty => subtitle.isEmpty;

  /// 是否有字幕。
  bool get isNotEmpty => !isEmpty;

  /// 取指定播放位置正在显示的字幕，区间为 [start, end)。
  List<FlSubtitle?> getByPosition(Duration position) {
    final found = subtitle.where((item) {
      if (item != null) return position >= item.start && position < item.end;
      return false;
    }).toList();
    return found;
  }
}

/// 单条字幕。
class FlSubtitle {
  FlSubtitle({required this.index, required this.start, required this.end, required this.text});

  /// 复制并替换指定字段。
  FlSubtitle copyWith({int? index, Duration? start, Duration? end, String? text}) =>
      FlSubtitle(index: index ?? this.index, start: start ?? this.start, end: end ?? this.end, text: text ?? this.text);

  /// 字幕序号。
  final int index;

  /// 开始时间。
  final Duration start;

  /// 结束时间（不包含）。
  final Duration end;

  /// 字幕内容。
  final String text;

  @override
  String toString() => 'FlSubtitle(index: $index, start: $start, end: $end, text: $text)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FlSubtitle &&
        other.index == index &&
        other.start == start &&
        other.end == end &&
        other.text == text;
  }

  @override
  int get hashCode => index.hashCode ^ start.hashCode ^ end.hashCode ^ text.hashCode;
}

/// Duration 格式化扩展。
extension FlVideoDurationExtension on Duration {
  /// 格式化为 `mm:ss`，时长达到 1 小时时格式化为 `hh:mm:ss`；负数按 0 处理。
  String formatDuration() {
    final ms = inMilliseconds < 0 ? 0 : inMilliseconds;
    final int totalSeconds = ms ~/ 1000;
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;

    final String mmss = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    return hours > 0 ? '${hours.toString().padLeft(2, '0')}:$mmss' : mmss;
  }
}

/// 倍速格式化扩展。
extension FlVideoDoubleExtension on double {
  /// 格式化为倍速文案：整数不带小数，例如 `1X`、`1.5X`；[suffix] 可换成 iOS 风格的 `x`。
  String formatPlaybackSpeed({String suffix = 'X'}) {
    final String value = this == truncateToDouble() ? toStringAsFixed(0) : toString();
    return '$value$suffix';
  }
}
