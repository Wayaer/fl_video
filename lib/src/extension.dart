import 'package:flutter/widgets.dart';

/// 为任意 Widget 快捷添加点击手势。
extension ExtensionWidget on Widget {
  /// 用 [GestureDetector] 包裹当前 Widget，并监听 [onTap]。
  GestureDetector onTap(GestureTapCallback? onTap, {Key? key}) => GestureDetector(onTap: onTap, key: key, child: this);
}

/// 通用布局包装器（内部使用）。
///
/// 按固定顺序把内容包装成 Padding、背景、手势、宽高比、AbsorbPointer、
/// 撑满、对齐和 SafeArea。
class Universal extends StatelessWidget {
  const Universal({
    super.key,
    this.decoration,
    this.padding,
    this.onTap,
    this.onDoubleTap,
    this.child,
    this.children,
    this.direction = Axis.vertical,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.left = false,
    this.top = false,
    this.right = false,
    this.bottom = false,
    this.absorbing,
    this.isStack = false,
    this.expand = false,
    this.aspectRatio,
    this.color,
    this.alignment,
  });

  /// 单个子组件；与 [children] 同时存在时作为第一个子项。
  final Widget? child;

  /// 背景装饰（[DecoratedBox]）。
  final Decoration? decoration;

  /// 内边距（[Padding]）。
  final EdgeInsetsGeometry? padding;

  /// 点击回调（[GestureDetector]）。
  final GestureTapCallback? onTap;

  /// 双击回调（[GestureDetector]）。
  final GestureTapCallback? onDoubleTap;

  /// 子组件列表。
  final List<Widget>? children;

  /// [Flex] 排列方向。
  final Axis direction;

  /// [Flex] 主轴对齐方式。
  final MainAxisAlignment mainAxisAlignment;

  /// [Flex] 交叉轴对齐方式。
  final CrossAxisAlignment crossAxisAlignment;

  /// [Flex] 主轴尺寸策略。
  final MainAxisSize mainAxisSize;

  /// SafeArea 左边距。
  final bool left;

  /// SafeArea 上边距。
  final bool top;

  /// SafeArea 右边距。
  final bool right;

  /// SafeArea 下边距。
  final bool bottom;

  /// 是否用 [SizedBox.expand] 撑满父级。
  final bool expand;

  /// 为 true 时使用 [Stack]，否则使用 [Flex]。
  final bool isStack;

  /// 是否用 [AbsorbPointer] 拦截子组件点击。
  final bool? absorbing;

  /// 宽高比（[AspectRatio]）。
  final double? aspectRatio;

  /// 背景色（[ColoredBox]）。
  final Color? color;

  /// 对齐方式（[Align]）。
  final Alignment? alignment;

  @override
  Widget build(BuildContext context) {
    Widget current = SizedBox(child: child);
    if (children != null) {
      final List<Widget> items = [?child, ...children!];
      if (isStack) {
        current = Stack(children: items);
      } else {
        current = Flex(
          mainAxisSize: mainAxisSize,
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: crossAxisAlignment,
          direction: direction,
          children: items,
        );
      }
    }

    if (padding != null) {
      current = Padding(padding: padding!, child: current);
    }
    if (color != null) {
      current = ColoredBox(color: color!, child: current);
    }
    if (decoration != null) {
      current = DecoratedBox(decoration: decoration!, child: current);
    }
    if (onTap != null || onDoubleTap != null) {
      current = GestureDetector(onTap: onTap, onDoubleTap: onDoubleTap, child: current);
    }

    if (aspectRatio != null) {
      current = AspectRatio(aspectRatio: aspectRatio!, child: current);
    }
    if (absorbing != null) {
      current = AbsorbPointer(absorbing: absorbing!, child: current);
    }
    if (expand) current = SizedBox.expand(child: current);

    if (alignment != null) {
      current = Align(alignment: alignment!, child: current);
    }
    if (left || right || bottom || top) {
      current = SafeArea(left: left, top: top, right: right, bottom: bottom, child: current);
    }
    return current;
  }
}
