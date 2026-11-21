import 'package:material_ui/material_ui.dart';

/// 分支切换/拖动的状态机，独立于 shell 的 Chrome 构建
enum ShellSwitchPhase { idle, switching, settlingForward, settlingBack }

class ShellTransition extends ChangeNotifier {
  ShellTransition({required this.controller});

  final AnimationController controller;

  /// go_router 当前分支索引
  int currentIndex = 0;

  /// 过渡/拖动开始时的分支
  int sourceIndex = 0;

  /// 过渡中的新分支；null 表示没有过渡
  int? incomingIndex;

  /// 过渡中被移出的分支
  int outgoingIndex = 0;

  /// 拖动目标；松手后动画收尾期间仍保留
  int? dragTarget;

  bool dragging = false;

  /// 过渡开始时 source 是否在分支根页
  bool sourceWasRoot = true;

  int slideDirection = 1;
  double dragDistance = 0.0;
  double pageWidth = 0.0;
  ShellSwitchPhase phase = ShellSwitchPhase.idle;

  bool get isBusy =>
      dragging ||
      dragTarget != null ||
      incomingIndex != null ||
      phase != ShellSwitchPhase.idle;

  /// 侧栏/底栏高亮：拖动期间保持源 tab，提交后才切换
  int get displayIndex =>
      (dragging || dragTarget != null) ? sourceIndex : currentIndex;

  /// 当前应显示的页面
  int get activeIndex => incomingIndex ?? currentIndex;

  /// 过渡中正在移出的页面；无过渡时为 null
  int? get outgoingVisibleIndex => incomingIndex == null ? null : outgoingIndex;

  void syncCurrentIndex(int index) {
    if (currentIndex == index) return;
    currentIndex = index;
  }

  void beginSwitch({
    required int from,
    required int to,
    required bool sourceWasRoot,
    required int direction,
  }) {
    sourceIndex = from;
    currentIndex = to;
    incomingIndex = to;
    outgoingIndex = from;
    slideDirection = direction;
    this.sourceWasRoot = sourceWasRoot;
    phase = ShellSwitchPhase.switching;
    notifyListeners();
  }

  void beginDrag({required int source, required bool sourceWasRoot}) {
    sourceIndex = source;
    currentIndex = source;
    outgoingIndex = source;
    incomingIndex = null;
    dragTarget = null;
    dragging = true;
    this.sourceWasRoot = sourceWasRoot;
    dragDistance = 0.0;
    phase = ShellSwitchPhase.idle;
    notifyListeners();
  }

  /// 拖动首次确定目标：先切到目标分支（懒加载），由控制器驱动平移
  void beginDragTarget(int target, int direction) {
    dragTarget = target;
    incomingIndex = target;
    outgoingIndex = sourceIndex;
    currentIndex = target;
    slideDirection = direction;
    notifyListeners();
  }

  void endDrag() {
    dragging = false;
    notifyListeners();
  }

  void setPhase(ShellSwitchPhase value) {
    phase = value;
    notifyListeners();
  }

  void finishForward() {
    incomingIndex = null;
    dragTarget = null;
    dragging = false;
    phase = ShellSwitchPhase.idle;
    notifyListeners();
  }

  void finishRollback(int source) {
    currentIndex = source;
    sourceIndex = source;
    incomingIndex = null;
    dragTarget = null;
    dragging = false;
    phase = ShellSwitchPhase.idle;
    notifyListeners();
  }
}

/// 向分支容器暴露 [ShellTransition]
class ShellTransitionScope extends InheritedWidget {
  const ShellTransitionScope({
    super.key,
    required this.transition,
    required super.child,
  });

  final ShellTransition transition;

  static ShellTransition of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ShellTransitionScope>();
    assert(scope != null, 'ShellTransitionScope not found');
    return scope!.transition;
  }

  @override
  bool updateShouldNotify(ShellTransitionScope oldWidget) =>
      transition != oldWidget.transition;
}
