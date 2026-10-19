import 'dart:math' as math;

import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/view/responsive/breakpoints.dart';
import 'package:grow_castle_calculator_next/view/shell/main_pages.dart';
import 'package:grow_castle_calculator_next/view/shell/shell_animations.dart';
import 'package:material_ui/material_ui.dart';

/// 宽屏侧栏：图标栏 / 展开栏
class AppSidebar extends StatefulWidget {
  const AppSidebar({
    super.key,
    required this.expanded,
    required this.selectedIndex,
    required this.pages,
    required this.onSelected,
    required this.canToggleExpanded,
    required this.onToggleExpanded,
  });

  final bool expanded;
  final int selectedIndex;
  final List<MainPageEntry> pages;
  final ValueChanged<int> onSelected;
  final bool canToggleExpanded;
  final VoidCallback onToggleExpanded;

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: shellAnimationDuration,
    value: widget.expanded ? 1.0 : 0.0,
  );

  @override
  void didUpdateWidget(covariant AppSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expanded == widget.expanded) return;
    widget.expanded ? _controller.forward() : _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = shellAnimationCurve.transform(_controller.value);
        final width =
            Breakpoints.railWidth +
            (Breakpoints.expandedWidth - Breakpoints.railWidth) * t;
        return SizedBox(
          width: width,
          child: ColoredBox(
            color: scheme.surfaceContainer,
            child: SelectionContainer.disabled(
              // 内容按展开宽度布局并裁切：收/展时文字随宽度平滑露出
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  minWidth: Breakpoints.expandedWidth,
                  maxWidth: Breakpoints.expandedWidth,
                  child: SizedBox(
                    width: Breakpoints.expandedWidth,
                    height: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SidebarHeader(t: t),
                        Divider(height: 1, color: scheme.outlineVariant),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            children: [
                              for (var i = 0; i < widget.pages.length; i++)
                                _SidebarItem(
                                  icon: widget.pages[i].icon,
                                  label: widget.pages[i].title(l10n),
                                  selected: i == widget.selectedIndex,
                                  expanded: widget.expanded,
                                  t: t,
                                  onTap: () => widget.onSelected(i),
                                ),
                            ],
                          ),
                        ),
                        if (widget.canToggleExpanded) ...[
                          Divider(height: 1, color: scheme.outlineVariant),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                icon: Transform.rotate(
                                  angle: (1 - t) * math.pi,
                                  child: const Icon(Icons.chevron_left),
                                ),
                                tooltip: t >= 0.5
                                    ? l10n.sidebarCollapse
                                    : l10n.sidebarExpand,
                                onPressed: widget.onToggleExpanded,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({required this.t});

  /// 0 = 图标栏，1 = 展开栏
  final double t;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 64,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 26 + (16 - 26) * t),
        child: Row(
          children: [
            Image.asset('assets/images/app_icon.png', width: 28, height: 28),
            const SizedBox(width: 12),
            Opacity(
              opacity: t,
              child: Text(
                'GCC Next',
                maxLines: 1,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.expanded,
    required this.t,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool expanded;

  /// 0 = 图标栏，1 = 展开栏
  final double t;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(12);
    final item = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: selected ? scheme.secondaryContainer : Colors.transparent,
        borderRadius: borderRadius,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: SizedBox(
            width: Breakpoints.expandedWidth - 16,
            height: 48,
            child: Row(
              children: [
                SizedBox(width: 18 + (8 - 18) * t),
                Icon(
                  icon,
                  size: 24,
                  color: selected
                      ? scheme.onSecondaryContainer
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Opacity(
                    opacity: t,
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: selected ? FontWeight.w600 : null,
                        color: selected
                            ? scheme.onSecondaryContainer
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return TooltipVisibility(
      visible: !expanded,
      child: Tooltip(
        message: label,
        child: Semantics(selected: selected, button: true, child: item),
      ),
    );
  }
}
