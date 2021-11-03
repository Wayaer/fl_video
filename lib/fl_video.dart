library fl_video;

import 'package:flutter/material.dart';

export 'package:video_player/video_player.dart';

export 'src/fl_video_player.dart';
export 'src/controls/cupertino_controls.dart';
export 'src/controls/material_controls.dart';
export 'src/model.dart';

class PlayerNotifier extends ChangeNotifier {
  PlayerNotifier._(bool hideStuff) : _hideStuff = hideStuff;

  bool _hideStuff;

  bool get hideStuff => _hideStuff;

  set hideStuff(bool value) {
    if (_hideStuff != value) {
      _hideStuff = value;
      notifyListeners();
    }
  }

  static PlayerNotifier get init => PlayerNotifier._(true);
}
