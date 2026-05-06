import 'package:fl_video/fl_video.dart';
import 'package:flutter/material.dart';

typedef FlVideoControlsTap = void Function(
    FlVideoTapEvent event, FlVideoPlayerController controller);

typedef FlVideoControlsProgressDrag = void Function(
    FlVideoDragProgressEvent event, Duration duration);

enum FlVideoDragProgressEvent {
  /// drag start
  start,

  /// drag end
  end,
}

enum FlVideoTapEvent {
  /// center playPause Button
  largePlayPause,

  /// playPause Button
  playPause,

  /// volume Button
  volume,

  /// position text Button
  position,

  /// duration text Button  CupertinoControls only
  remaining,

  /// playbackSpeed Button
  speed,

  /// subtitle Button
  subtitle,

  /// fullscreen Button
  fullscreen,

  /// progress Button
  progress,

  /// error Button
  error,

  /// loading Button
  loading,

  /// skip back  CupertinoControls only
  skipBack,

  /// skip back  CupertinoControls only
  skipForward,
}

class FlVideoPlayerProgressColors {
  const FlVideoPlayerProgressColors({
    this.played = const Color(0xb2ff0000),
    this.buffered = const Color(0x331e1ec8),
    this.handle = const Color(0xffc8c8c8),
    this.background = const Color(0x7fc8c8c8),
  });

  final Color played;
  final Color buffered;
  final Color handle;
  final Color background;
}

class Subtitles {
  Subtitles(this.subtitle);

  final List<Subtitle?> subtitle;

  bool get isEmpty => subtitle.isEmpty;

  bool get isNotEmpty => !isEmpty;

  List<Subtitle?> getByPosition(Duration position) {
    final found = subtitle.where((item) {
      if (item != null) return position >= item.start && position <= item.end;
      return false;
    }).toList();
    return found;
  }
}

class Subtitle {
  Subtitle(
      {required this.index,
      required this.start,
      required this.end,
      required this.text});

  Subtitle copyWith(
          {int? index, Duration? start, Duration? end, String? text}) =>
      Subtitle(
          index: index ?? this.index,
          start: start ?? this.start,
          end: end ?? this.end,
          text: text ?? this.text);

  final int index;
  final Duration start;
  final Duration end;
  final String text;

  @override
  String toString() =>
      'Subtitle(index: $index, start: $start, end: $end, text: $text)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Subtitle &&
        other.index == index &&
        other.start == start &&
        other.end == end &&
        other.text == text;
  }

  @override
  int get hashCode =>
      index.hashCode ^ start.hashCode ^ end.hashCode ^ text.hashCode;
}
