import 'package:flutter/material.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/view/page/build_gp_page.dart';
import 'package:grow_castle_calculator_next/view/page/income_page.dart';

/// 页面在 AppBar 中声明的操作按钮构建器。
///
/// 页面数据变化通过 store 的 ValueNotifier 驱动 UI 重建，
/// 按钮只需直接调用 store 方法，无需手动刷新。
typedef PageActionsBuilder = List<Widget> Function(BuildContext context);

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
  // 阵容经济计算 AppBar
  DrawerPageEntry(
    title: '阵容经济计算',
    icon: Icons.calculate,
    builder: (_) => FormationCalcPage(),
    actionsBuilder: (context) => [
      IconButton(
        icon: const Icon(Icons.add),
        tooltip: '新增条目',
        // 列表重建由 store 的 cardIdsNotifier 驱动
        onPressed: () => Stores.infoStore.addNewCard(),
      ),
      IconButton(
        icon: const Icon(Icons.list_alt),
        tooltip: '单位金币明细',
        onPressed: () => showModalBottomSheet(
          context: context,
          builder: (sheetContext) {
            final cardIds = Stores.infoStore.getCardIds();
            final totalGold = Stores.infoStore.totalGoldNotifier.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      '单位金币明细',
                      style: Theme.of(sheetContext).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  const Divider(),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: cardIds.length,
                      itemBuilder: (context, index) {
                        final id = cardIds[index];
                        final name = Stores.infoStore.getTextValue(id);
                        final level = Stores.infoStore.getNumberValue(id);
                        final gold = Stores.infoStore.getUnitGold(id);
                        final applied = Stores.infoStore.getApplyFlag(id);
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 14.0,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(fontSize: 12.0),
                            ),
                          ),
                          title: Text(
                            name.isNotEmpty ? name : '单位 $id',
                            style: TextStyle(
                              decoration: applied
                                  ? null
                                  : TextDecoration.lineThrough,
                              color: applied
                                  ? null
                                  : Theme.of(sheetContext).disabledColor,
                            ),
                          ),
                          subtitle: Text(
                            '等级: ${level.isNotEmpty ? level : '0'}',
                          ),
                          trailing: Text(
                            gold.format(fractionDigits: 0),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: applied
                                  ? null
                                  : Theme.of(sheetContext).disabledColor,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 4.0,
                    ),
                    child: Row(
                      children: [
                        Text(
                          '总金币',
                          style: Theme.of(sheetContext).textTheme.titleSmall,
                        ),
                        const Spacer(),
                        Text(
                          totalGold.format(fractionDigits: 0),
                          style: Theme.of(sheetContext)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ],
  ),
  // 收入计算 AppBar
  DrawerPageEntry(
    title: '收入计算',
    icon: Icons.trending_up,
    builder: (_) => IncomePage(),
  ),
];
