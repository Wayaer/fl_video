import 'package:flutter/material.dart';

class Universal extends StatelessWidget {
  const Universal({
    Key? key,
    this.decoration,
    this.padding,
    this.onTap,
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
  }) : super(key: key);
  final Widget? child;

  /// [DecoratedBox]
  final Decoration? decoration;

  /// [Padding]
  final EdgeInsetsGeometry? padding;

  /// [GestureDetector]
  final GestureTapCallback? onTap;

  /// [Flex]
  final List<Widget>? children;
  final Axis direction;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  /// [SafeArea]
  final bool left;
  final bool top;
  final bool right;
  final bool bottom;

  /// [SizedBox.expand()]
  final bool expand;

  /// [Stack]
  final bool isStack;

  /// [AbsorbPointer]
  final bool? absorbing;

  /// [AspectRatio]
  final double? aspectRatio;

  /// [ColoredBox]
  final Color? color;

  /// [Align]
  final Alignment? alignment;

  @override
  Widget build(BuildContext context) {
    Widget current = SizedBox(child: child);
    if (children != null) {
      if (child != null) children!.insert(0, child!);
      if (isStack) {
        current = Stack(children: children!);
      } else {
        current = Flex(
            mainAxisSize: mainAxisSize,
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            direction: direction,
            children: children!);
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
    if (onTap != null) {
      current = GestureDetector(onTap: onTap, child: current);
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
      current = SafeArea(
          left: left, top: top, right: right, bottom: bottom, child: current);
    }
    return current;
  }
}
