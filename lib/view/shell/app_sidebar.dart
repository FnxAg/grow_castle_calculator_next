import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/view/responsive/breakpoints.dart';
import 'package:grow_castle_calculator_next/view/shell/main_pages.dart';
import 'package:material_ui/material_ui.dart';

/// 宽屏侧栏：图标栏 / 展开栏
class AppSidebar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      width: expanded ? Breakpoints.expandedWidth : Breakpoints.railWidth,
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
                  _SidebarHeader(expanded: expanded),
                  Divider(height: 1, color: scheme.outlineVariant),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        for (var i = 0; i < pages.length; i++)
                          _SidebarItem(
                            icon: pages[i].icon,
                            label: pages[i].title(l10n),
                            selected: i == selectedIndex,
                            expanded: expanded,
                            onTap: () => onSelected(i),
                          ),
                      ],
                    ),
                  ),
                  if (canToggleExpanded) ...[
                    Divider(height: 1, color: scheme.outlineVariant),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: Icon(
                            expanded ? Icons.chevron_left : Icons.chevron_right,
                          ),
                          tooltip: expanded
                              ? l10n.sidebarCollapse
                              : l10n.sidebarExpand,
                          onPressed: onToggleExpanded,
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
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({required this.expanded});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 64,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: expanded ? 16 : 26),
        child: Row(
          children: [
            Image.asset('assets/images/app_icon.png', width: 28, height: 28),
            const SizedBox(width: 12),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: expanded ? 1 : 0,
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
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool expanded;
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
            width: expanded ? null : Breakpoints.railWidth - 16,
            height: 48,
            child: Row(
              children: [
                SizedBox(width: expanded ? 16 : 20),
                Icon(
                  icon,
                  size: 24,
                  color: selected
                      ? scheme.onSecondaryContainer
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: expanded ? 1 : 0,
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
    return Semantics(
      selected: selected,
      button: true,
      child: expanded ? item : Tooltip(message: label, child: item),
    );
  }
}
