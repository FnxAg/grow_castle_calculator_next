import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/view/page/build_gp_page.dart';
import 'package:grow_castle_calculator_next/view/page/income_page.dart';

/// 页面在 AppBar 中声明的操作按钮构建器
///
/// [refresh] 用于操作后刷新框架（等价于框架的 setState），
/// 使页面 body 重新从 store 读取数据。
typedef PageActionsBuilder =
    List<Widget> Function(BuildContext context, void Function() refresh);

/// 抽屉页面注册表：新增页面只需在此追加一条记录，
/// 首页框架（[HomeTab]）会自动在抽屉中列出并支持切换。
class DrawerPageEntry {
  const DrawerPageEntry({
    required this.title,
    required this.icon,
    required this.builder,
    this.actionsBuilder,
  });

  final String title;
  final IconData icon;
  final WidgetBuilder builder;

  /// 该页面在 AppBar 中显示的操作按钮；未提供则无
  final PageActionsBuilder? actionsBuilder;
}

/// 抽屉中按顺序显示的页面
final List<DrawerPageEntry> drawerPages = [
  DrawerPageEntry(
    title: '阵容经济计算',
    icon: Icons.calculate,
    builder: (_) => const FormationCalcPage(),
    actionsBuilder: (context, refresh) => [
      IconButton(
        icon: const Icon(Icons.add),
        tooltip: '新增条目',
        onPressed: () {
          Stores.infoStore.addNewCard();
          refresh();
        },
      ),
      // 手动输入 wave 和 seasonWave
      IconButton(
        icon: const Icon(Icons.edit),
        tooltip: '设置波数',
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              final waveController = TextEditingController();
              final seasonWaveController = TextEditingController();
              return AlertDialog(
                title: const Text('设置波数'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: waveController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: '当前波数'),
                    ),
                    TextField(
                      controller: seasonWaveController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: '赛季波数'),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () {
                      final wave = int.tryParse(waveController.text) ?? 1;
                      final seasonWave = int.tryParse(seasonWaveController.text) ?? 0;
                      Stores.infoStore.setWave(wave);
                      Stores.infoStore.setSeasonWave(seasonWave);
                      Navigator.of(context).pop();
                    },
                    child: const Text('保存'),
                  ),
                ],
              );
            },
          );
        },
      ),
    ],
  ),
  DrawerPageEntry(
    title: '收入计算',
    icon: Icons.trending_up,
    builder: (_) => const IncomePage(),
  ),
];
