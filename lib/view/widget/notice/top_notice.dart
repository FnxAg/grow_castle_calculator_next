import 'dart:async';
import 'dart:ui';

import 'package:grow_castle_calculator_next/utils/ui.dart';
import 'package:material_ui/material_ui.dart';

OverlayEntry? _currentEntry;

enum NoticeType { info, content, error }

/// 从顶部弹出的轻提示
void showTopNotice(
  BuildContext context, {
  String? message,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 3),
  Widget? content,
  NoticeType noticeType = NoticeType.info,
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
      actionLabel: actionLabel,
      onAction: onAction,
      duration: actionLabel == null ? duration : const Duration(seconds: 5),
      content: content,
      noticeType: noticeType,
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
    required this.actionLabel,
    required this.onAction,
    required this.duration,
    required this.content,
    required this.onDismissed,
    required this.noticeType,
  });

  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;
  final Widget? content;
  final VoidCallback onDismissed;
  final NoticeType noticeType;

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
    final radius = UIs.cardShape.borderRadius;
    final inkRadius = BorderRadius.circular(UIs.cardRadiusValue);
    final background = switch (widget.noticeType) {
      .error => scheme.errorContainer,
      _ => ListTileTheme.of(context).tileColor,
    };
    final glassTint = background ?? scheme.surface;
    final foreground = switch (widget.noticeType) {
      .error => scheme.onErrorContainer,
      _ => ListTileTheme.of(context).textColor,
    };
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final leading = switch (widget.noticeType) {
      .info => const [
        Icon(Icons.info_outline, size: 20.0),
        SizedBox(width: 10.0),
      ],
      .error => const [
        Icon(Icons.error_outline, size: 20.0),
        SizedBox(width: 10.0),
      ],
      _ => null,
    };

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
                    color: Colors.transparent,
                    elevation: 10.0,
                    shadowColor: scheme.shadow.withValues(alpha: 0.2),
                    borderRadius: radius,
                    clipBehavior: Clip.antiAlias,
                    child: ClipRRect(
                      borderRadius: radius,
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                glassTint.withValues(alpha: 0.82),
                                glassTint.withValues(alpha: 0.70),
                              ],
                            ),
                            border: Border.all(
                              color: scheme.onSurface.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Semantics(
                            liveRegion: true,
                            container: true,
                            child: InkWell(
                              onTap: _dismiss,
                              borderRadius: inkRadius,
                              hoverColor: scheme.onSurface.withValues(
                                alpha: 0.05,
                              ),
                              highlightColor: scheme.onSurface.withValues(
                                alpha: 0.04,
                              ),
                              child: Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      14.0,
                                      6.0,
                                      14.0,
                                      14.0,
                                    ),
                                    child: Row(
                                      children: [
                                        ...?leading,
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
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                            child: Text(widget.actionLabel!),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    left: 14.0,
                                    right: 14.0,
                                    bottom: 8.0,
                                    height: 2.5,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(2.0),
                                      child: ColoredBox(
                                        color: scheme.onSurface.withValues(
                                          alpha: 0.10,
                                        ),
                                        child: AnimatedBuilder(
                                          animation: _countdown,
                                          builder: (context, child) =>
                                              Transform.scale(
                                                scaleX: 1.0 - _countdown.value,
                                                alignment: Alignment.centerLeft,
                                                child: child,
                                              ),
                                          child: ColoredBox(
                                            color:
                                                (foreground ?? scheme.onSurface)
                                                    .withValues(alpha: 0.62),
                                          ),
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
          ),
        ),
      ),
    );
  }
}
