import 'package:flutter/material.dart';
import 'package:grow_castle_calculator_next/data/res/pages.dart';
import 'package:grow_castle_calculator_next/view/widget/user_page_scaffold.dart';

/// app 根外壳：PageView（阵容/收入/公会/工具/设置）+ 底部导航。
/// 与当前用户相关的页面（阵容/收入/公会）由 [UserPageScaffold] 挂载，
/// 其余页面自带独立 Scaffold。
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _selectIndex = ValueNotifier(0);
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          // 同步底部导航高亮（滑动与点击两种来源都会触发）
          _selectIndex.value = index;
          // 切页即释放输入框焦点：否则焦点仍挂在已被切走的页面上，
          // PageView(allowImplicitScrolling) 为了显示获焦子页会自动滚回来，造成页面抽风
          FocusManager.instance.primaryFocus?.unfocus();
        },
        // 相邻页保活：保留各页输入状态，并支持左右滑动切换
        allowImplicitScrolling: true,
        children: [
          for (final page in mainPages)
            page.userPage
                ? UserPageScaffold(
                    title: page.title,
                    actions: page.actionsBuilder?.call(context) ?? const [],
                    body: page.builder(context),
                  )
                : page.builder(context),
        ],
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: _selectIndex,
        builder: (context, child) {
          return NavigationBar(
            selectedIndex: _selectIndex.value,
            height: kBottomNavigationBarHeight * 1.1,
            animationDuration: const Duration(milliseconds: 250),
            onDestinationSelected: (index) {
              // 立即更新高亮，并带动画切页
              _selectIndex.value = index;
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
              );
            },
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            destinations: [
              for (final page in mainPages)
                NavigationDestination(
                  icon: Icon(page.icon),
                  label: page.title,
                ),
            ],
          );
        },
      ),
    );
  }
}
