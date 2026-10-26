import 'package:app/src/demo.dart';
import 'package:app/src/player_page.dart';
import 'package:material_ui/material_ui.dart';

/// 首页：展示所有播放器示例。
class HomePage extends StatelessWidget {
  const HomePage({required this.onToggleThemeMode, super.key});

  /// 切换明暗主题。
  final VoidCallback onToggleThemeMode;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('fl_video'),
            actions: [
              IconButton(
                tooltip: isDark ? '切换到浅色模式' : '切换到深色模式',
                onPressed: onToggleThemeMode,
                icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(child: _Header(theme: theme)),
          const SliverToBoxAdapter(
            child: Padding(padding: EdgeInsets.fromLTRB(20, 20, 20, 8), child: Text('示例')),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList.builder(
              itemCount: videoDemos.length,
              itemBuilder: (BuildContext context, int index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DemoCard(demo: videoDemos[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 顶部渐变介绍卡片。
class _Header extends StatelessWidget {
  const _Header({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primaryContainer, scheme.tertiaryContainer],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Flutter 视频播放器',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '基于 video_player，提供 Material 与 Cupertino 两套控制面板，开箱即用。',
            style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onPrimaryContainer),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              '字幕',
              '倍速',
              '音量',
              '全屏',
              '直播',
            ].map((String text) => _Tag(text: text, theme: theme)).toList(),
          ),
        ],
      ),
    );
  }
}

/// 渐变卡片上的小标签。
class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.theme});

  final String text;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: theme.colorScheme.surface.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(text, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface)),
  );
}

/// 示例列表项。
class _DemoCard extends StatelessWidget {
  const _DemoCard({required this.demo});

  final VideoDemo demo;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (BuildContext context) => PlayerPage(demo: demo))),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(colors: [scheme.primary, scheme.tertiary]),
                ),
                child: Icon(demo.icon, color: scheme.onPrimary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(demo.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(demo.subtitle, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
