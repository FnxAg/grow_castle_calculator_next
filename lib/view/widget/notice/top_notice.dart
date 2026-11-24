import 'dart:async';

import 'package:material_ui/material_ui.dart';

OverlayEntry? _currentEntry;

/// 从顶部弹出的轻提示，替代 SnackBar（悬浮底栏会遮挡底部提示）
void showTopNotice(
  BuildContext context, {
  String? message,
  bool isError = false,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 3),
  Widget? content,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  if (message == null && content == null) {
    throw ArgumentError('Either message or content must be provided.');
  }

  _currentEntry?.remove();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _TopNotice(
      message: message,
      isError: isError,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: actionLabel == null ? duration : const Duration(seconds: 5),
      content: content,
      onDismissed: () {
        entry.remove();
        if (identical(_currentEntry, entry)) _currentEntry = null;
      },
    ),
  );
  _currentEntry = entry;
  overlay.insert(entry);
}

class _TopNotice extends StatefulWidget {
  const _TopNotice({
    required this.message,
    required this.isError,
    required this.actionLabel,
    required this.onAction,
    required this.duration,
    required this.content,
    required this.onDismissed,
  });

  final String? message;
  final bool isError;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;
  final Widget? content;
  final VoidCallback onDismissed;

  @override
  State<_TopNotice> createState() => _TopNoticeState();
}

class _TopNoticeState extends State<_TopNotice> with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    reverseDuration: const Duration(milliseconds: 160),
  );

  /// 自动关闭倒计时，与 Timer 同时启动
  late final AnimationController _countdown;

  Timer? _timer;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _countdown = AnimationController(vsync: this, duration: widget.duration)
      ..forward();
    _timer = Timer(widget.duration, _dismiss);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdown.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (_dismissing) return;
    _dismissing = true;
    _countdown.stop();
    _controller.reverse().whenComplete(() {
      if (mounted) widget.onDismissed();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = widget.isError
        ? scheme.errorContainer
        : ListTileTheme.of(context).tileColor;
    final foreground = widget.isError
        ? scheme.onErrorContainer
        : ListTileTheme.of(context).textColor;
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0.0),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.6),
              end: Offset.zero,
            ).animate(curved),
            child: FadeTransition(
              opacity: curved,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560.0),
                  child: Material(
                    color: background,
                    elevation: 4.0,
                    borderRadius: BorderRadius.circular(14.0),
                    clipBehavior: Clip.antiAlias,
                    child: Semantics(
                      liveRegion: true,
                      container: true,
                      child: InkWell(
                        onTap: _dismiss,
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                14.0,
                                6.0,
                                6.0,
                                6.0,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    widget.isError
                                        ? Icons.error_outline
                                        : Icons.info_outline,
                                    size: 20.0,
                                    color: foreground,
                                  ),
                                  const SizedBox(width: 10.0),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6.0,
                                      ),
                                      child:
                                          widget.content ??
                                          Text(
                                            widget.message!,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: foreground,
                                              fontSize: 14.0,
                                            ),
                                          ),
                                    ),
                                  ),
                                  if (widget.actionLabel != null)
                                    TextButton(
                                      onPressed: () {
                                        widget.onAction?.call();
                                        _dismiss();
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: foreground,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      child: Text(widget.actionLabel!),
                                    ),
                                ],
                              ),
                            ),
                            Positioned(
                              left: 0.0,
                              right: 0.0,
                              bottom: 0.0,
                              height: 2.0,
                              child: ExcludeSemantics(
                                child: AnimatedBuilder(
                                  animation: _countdown,
                                  builder: (context, child) =>
                                      Transform.scale(
                                        scaleX: 1.0 - _countdown.value,
                                        alignment: Alignment.centerLeft,
                                        child: child,
                                      ),
                                  child: ColoredBox(
                                    color: (foreground ?? scheme.onSurface)
                                        .withValues(alpha: 0.35),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
