import 'package:app/main.dart';
import 'package:app/src/demo.dart';
import 'package:app/src/player_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  for (final size in const [Size(390, 844), Size(320, 568), Size(834, 1112)]) {
    testWidgets('home renders at $size', (WidgetTester tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const FlVideoExampleApp());
      await tester.pumpAndSettle();
      // 大标题样式下 AppBar 会同时渲染折叠与展开两份标题
      expect(find.text('fl_video'), findsWidgets);
      expect(find.text('Flutter 视频播放器'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('player pages render', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final demo in videoDemos) {
      await tester.pumpWidget(MaterialApp(home: PlayerPage(demo: demo)));
      await tester.pump();
      // AppBar 标题与底部说明面板各有一处标题
      expect(find.text(demo.title), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    }
  });
}
