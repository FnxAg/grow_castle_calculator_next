import 'package:flutter/material.dart';
import 'package:grow_castle_calculator_next/view/page/tool/dragon_simulator_page.dart';
import 'package:grow_castle_calculator_next/view/page/tool/ranking_page.dart';

/// 工具页：独立 Scaffold，与当前用户无关——入口展示全局共享数据。
class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('工具'),
        // backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        children: [
          for (final kind in RankingKind.values)
            ListTile(
              leading: Icon(kind.icon),
              title: Text(kind.title),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // 先释放焦点：避免首页 TextField 的焦点触发
                // PageView(allowImplicitScrolling) 自动滚回首页
                FocusManager.instance.primaryFocus?.unfocus();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => RankingPage(kind: kind),
                  ),
                );
              },
            ),
          ListTile(
            leading: const Icon(Icons.casino_outlined),
            title: const Text('刷龙模拟器'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // 先释放焦点：避免首页 TextField 的焦点触发
              // PageView(allowImplicitScrolling) 自动滚回首页
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DragonSimulatorPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
