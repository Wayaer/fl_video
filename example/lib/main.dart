import 'package:app/src/home_page.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const FlVideoExampleApp());
}

/// 示例应用入口：配置 Material 3 明暗主题并管理主题切换。
class FlVideoExampleApp extends StatefulWidget {
  const FlVideoExampleApp({super.key});

  @override
  State<FlVideoExampleApp> createState() => _FlVideoExampleAppState();
}

class _FlVideoExampleAppState extends State<FlVideoExampleApp> {
  /// 主题种子色
  static const Color _seedColor = Color(0xFF4F46E5);

  ThemeMode themeMode = ThemeMode.dark;

  void toggleThemeMode() {
    setState(() {
      themeMode = themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'fl_video',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: _seedColor)),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _seedColor, brightness: Brightness.dark),
      ),
      themeMode: themeMode,
      home: HomePage(onToggleThemeMode: toggleThemeMode),
    );
  }
}
