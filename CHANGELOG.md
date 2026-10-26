## 2.0.0

> Note: This release has breaking changes.

* **BREAKING** 库内公开类统一加 `Fl` 前缀，以标识属于 `fl_video`：`MaterialControls` → `FlMaterialControls`、
  `CupertinoControls` → `FlCupertinoControls`、`PlayerNotifier` → `FlPlayerNotifier`、
  `VideoProgressBar` → `FlVideoProgressBar`、`CenterPlayButton` → `FlCenterPlayButton`、
  `AnimatedPlayPause` → `FlAnimatedPlayPause`、`DefaultIcon` → `FlDefaultIcon`、`DefaultError` → `FlDefaultError`、
  `PlaybackSpeedDialog` → `FlPlaybackSpeedDialog`、`Subtitles` → `FlSubtitles`、`Subtitle` → `FlSubtitle`、
  `SubtitlesBuilder` → `FlSubtitlesBuilder`
* **BREAKING** Migrate to the standalone `material_ui` and `cupertino_ui` packages for Flutter 3.47
* Requires Flutter >= 3.47 and Dart >= 3.13
* 控制面板读取 `material_ui` / `cupertino_ui` 的 `Theme` 与本地化，宿主 App 需先完成迁移
  （`dart fix --apply --code=migrate_design_widgets`）；仍使用 `package:flutter/material.dart` 的项目请继续使用 1.5.0
* `deviceOrientationsAfterFullScreen` 默认由「允许全部方向」改为「仅竖屏」，退出全屏后会恢复为竖屏；
  需要保持横屏可旋转的应用请显式传入 `DeviceOrientation.values`
* `FlMaterialControls` / `FlCupertinoControls` 新增 `speedConfig`，支持只替换弹窗内容（`contentBuilder`）
  或完全接管点击与弹窗展示（`onSelect`）两种倍速选择自定义方式
* 内置倍速弹窗统一为「标题 + 倍速选项」样式，标题可用 `speedTitle` 自定义（默认英文 `Playback Speed`），
  原 `CupertinoControls` 的 `CupertinoActionSheet` 弹窗不再使用
* `FlCupertinoControls` 新增 `skipDuration`，可自定义快进/快退时长（默认 15 秒）
* 两种控制面板新增 `enableDoubleTap`（默认关闭），启用后可双击画面切换播放/暂停
* 两种控制面板新增 `liveBuilder`，可自定义直播标识（默认显示 `LIVE` 文本）
* `FlCupertinoControls` 新增 `isLive` 参数，与 `FlMaterialControls` 保持一致
* `FlVideoSpeedConfig.onTap` 重命名为 `onSelect`；`PositionBuilder` / `RemainingBuilder` / `PositionAndAllBuilder`
  统一为 `FlVideoPositionBuilder` / `FlVideoRemainingBuilder` / `FlVideoPositionAndAllBuilder` 并移到 `model.dart`
* `FlVideoPlayerController.subtitle` 改为只读，统一用 `setSubtitle` 更新以触发刷新
* `FlVideoPlayerController.dispose()` 默认释放底层播放器；初始化失败后允许重试；`startAt` 改为先跳转再播放
* 修复进度条拖动被取消后不恢复播放、进度条绘制盒高度为 0 导致的命中错位
* 修复全屏切换后的自动恢复播放可能覆盖用户暂停操作
* 修复 `fullScreenByDefault` 下退出全屏后会被立刻再次拉回全屏
* 修复默认配置（未开启 `autoInitialize` / `autoPlay`）时 `initialize()` 不生效导致视频永远无法初始化
* 新增 `FlVideoPlayerController.updateConfig`，可在运行期更新 `controls` / `overlay` / `placeholder` /
  `subtitleBuilder` / `isLive` 等展示配置，无需重建控制器
* 导出内置组件 `player_with_controls.dart`：`FlVideoProgressBar`、`FlCenterPlayButton`、`FlAnimatedPlayPause`、
  `FlDefaultError`、`FlPlaybackSpeedDialog` 可直接用于自定义控制面板
* 导出格式化扩展：`FlVideoDurationExtension.formatDuration()` 与
  `FlVideoDoubleExtension.formatPlaybackSpeed()`，自定义控制面板可直接复用时间与倍速文案
* `FlVideoProgressBar` 移除未使用的 `onDragUpdate`，拖动时的 seek 增加 60ms 节流；`FlCenterPlayButton`
  改用 `tooltip` 提供无障碍标签，避免语义重复
* wakelock 失败不再抛出未处理的异步异常；退出全屏的收尾不再于组件销毁后执行
* 恢复播放会同时参考控制面板触摸与主动暂停记录，避免覆盖用户暂停
* 倍速按钮由图标改为直接展示当前倍数（默认 `1X`，选择后回显所选倍数），移除 `speed` 图标参数，
  新增 `speedLabelBuilder` 用于自定义倍数文案；`FlCupertinoControls` 同样支持倍速切换
* `FlCupertinoControls` 的倍速选择沿用 iOS 风格：底部操作表（标题取自 `speedTitle`，当前倍数带勾选、
  带取消按钮），按钮文案使用小写 `1x`；不再复用 Material 样式的弹窗
* `FlCupertinoControls` 新增 `speedCancelLabel`，可自定义 iOS 操作表的取消文案（默认为系统本地化文案）
* 修复 `FlCupertinoControls` 控制栏在较宽的自定义时间文本、窄屏或倍数文案变长时可能溢出
* 新增 `test/` 回归测试（初始化、释放、全屏、配置、字幕、时长格式化）
* 内部重构：两种控制面板的公共逻辑（字幕、状态刷新、播放暂停、双击、全屏、静音、自动隐藏、
  倍速弹窗流程）与图标按钮统一抽到共享基类与 `FlGestureDetectorIcon`，公开构造签名不变
* 控制面板按钮补充无障碍 `Semantics` 标签，进度条点击会上报 `FlVideoTapEvent.progress`

## 1.5.0

* Update version