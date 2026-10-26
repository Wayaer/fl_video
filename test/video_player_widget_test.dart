import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:fl_video/fl_video.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'controller_test.dart' show SpyVideoPlayerController;

void main() {
  testWidgets('updateConfig 更新 controls / placeholder 后播放器会重建', (WidgetTester tester) async {
    final SpyVideoPlayerController spy = SpyVideoPlayerController();
    final FlVideoPlayerController controller = FlVideoPlayerController(videoPlayerController: spy);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FlVideoPlayer(controller: controller)),
      ),
    );
    expect(find.text('custom-controls'), findsNothing);
    expect(find.text('demo-placeholder'), findsNothing);

    controller.updateConfig(controls: const Text('custom-controls'), placeholder: const Text('demo-placeholder'));
    await tester.pump();

    expect(find.text('custom-controls'), findsOneWidget);
    expect(find.text('demo-placeholder'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('isLive 变化后控制面板会切换直播样式', (WidgetTester tester) async {
    final SpyVideoPlayerController spy = SpyVideoPlayerController();
    final FlVideoPlayerController controller = FlVideoPlayerController(
      videoPlayerController: spy,
      controls: FlMaterialControls(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FlVideoPlayer(controller: controller)),
      ),
    );
    await tester.pump();
    // 非直播时不显示 LIVE 文本
    expect(find.text('LIVE'), findsNothing);

    controller.updateConfig(isLive: true);
    await tester.pump();
    expect(find.text('LIVE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('倍速按钮', () {
    testWidgets('Material 面板默认显示 1X，选择后回显所选倍数', (WidgetTester tester) async {
      await _pumpWithControls(tester, FlMaterialControls());
      expect(find.text('1X'), findsOneWidget);

      await tester.tap(find.text('1X'));
      await tester.pumpAndSettle();
      expect(find.text('Playback Speed'), findsOneWidget);

      await tester.tap(find.text('1.5x'));
      await tester.pumpAndSettle();
      expect(find.text('1.5X'), findsOneWidget, reason: '选择后应回显所选倍数');
    });

    testWidgets('Cupertino 面板使用 iOS 风格文案与操作表，切换后回显', (WidgetTester tester) async {
      // 小屏下操作表条目较多，确认不会溢出
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await _pumpWithControls(tester, FlCupertinoControls());
      // iOS 风格小写 x
      expect(find.text('1x'), findsOneWidget);

      await tester.tap(find.text('1x'));
      await tester.pumpAndSettle();
      // iOS 风格底部操作表：标题 + 选项 + 取消按钮，当前倍数带勾选
      expect(find.byType(CupertinoActionSheet), findsOneWidget);
      expect(find.text('Playback Speed'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.check_mark), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('1.5x').last);
      await tester.pumpAndSettle();
      expect(find.text('1.5x'), findsOneWidget, reason: '选择后应回显所选倍数');
      expect(find.byType(CupertinoActionSheet), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Cupertino 控制栏在较宽时间文本下不会溢出', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await _pumpWithControls(
        tester,
        FlCupertinoControls(
          positionBuilder: (String position) => Text('当前位置 $position', style: const TextStyle(fontSize: 13)),
          remainingBuilder: (String remaining) => Text('剩余 $remaining', style: const TextStyle(fontSize: 13)),
        ),
      );
      expect(find.text('1x'), findsOneWidget);

      // 倍数变长后时间文本仍需被限制，整行不能溢出
      await tester.tap(find.text('1x'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1.5x').last);
      await tester.pumpAndSettle();
      expect(find.text('1.5x'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '控制栏不应溢出');
    });

    testWidgets('Cupertino 操作表的取消文案可自定义', (WidgetTester tester) async {
      await _pumpWithControls(tester, FlCupertinoControls(speedCancelLabel: '取消'));

      await tester.tap(find.text('1x'));
      await tester.pumpAndSettle();
      expect(find.text('取消'), findsOneWidget);
      expect(find.text('Cancel'), findsNothing, reason: '传入自定义文案后不再使用系统本地化文案');

      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoActionSheet), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}

/// 用指定控制面板搭建播放器；先让控制面板初始化完成（约定 200ms 后显示）再返回。
Future<void> _pumpWithControls(WidgetTester tester, Widget controls) async {
  final SpyVideoPlayerController spy = SpyVideoPlayerController();
  final FlVideoPlayerController controller = FlVideoPlayerController(videoPlayerController: spy, controls: controls);
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: FlVideoPlayer(controller: controller)),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}
