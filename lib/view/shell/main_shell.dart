import 'package:flutter/material.dart';
import 'package:grow_castle_calculator_next/view/tab/home_tab.dart';
import 'package:grow_castle_calculator_next/view/tab/setting_tab.dart';
import 'package:grow_castle_calculator_next/view/tab/tools_tab.dart';

/// app 根外壳：PageView（首页/工具/设置）+ 底部导航。
/// 每个 tab 使用各自独立的 Scaffold（抽屉属于首页，见 [HomeTab]）。
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
          // 离开首页时释放输入框焦点：否则焦点仍挂在首页 TextField 上，
          // 之后打开对话框（如设置页"关于"）关闭时焦点会恢复回首页，
          // PageView(allowImplicitScrolling) 为了显示获焦子页会自动滚回首页，造成页面抽风
          if (index != 0) {
            FocusManager.instance.primaryFocus?.unfocus();
          }
        },
        // 相邻页保活：保留首页滚动位置，并支持左右滑动切换
        allowImplicitScrolling: true,
        children: [
          const HomeTab(),
          const ToolsTab(),
          const SettingTab(),
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
              NavigationDestination(
                icon: const Icon(Icons.home),
                label: '首页',
              ),
              NavigationDestination(
                icon: const Icon(Icons.handyman),
                label: '工具',
              ),
              NavigationDestination(
                icon: const Icon(Icons.settings),
                label: '设置',
              ),
            ],
          );
        },
      ),
    );
  }
}
