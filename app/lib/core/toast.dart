import 'dart:async';

import 'package:flutter/material.dart';

import 'theme.dart';

/// Holatga qarab toast rangi. Matn har doim oq — fonlar oq matn bilan ≥ 4.5:1 kontrastli
/// (shuning uchun "och yashil" o'rniga o'qiladigan eng och yashil: green-700).
enum ToastType {
  success(Color(0xFF15803D)),
  error(Color(0xFFB91C1C)),
  warning(Color(0xFFB45309)),
  info(Color(0xFF1E293B));

  const ToastType(this.color);
  final Color color;
}

/// Ilova bo'ylab yagona toast: yuqoridan (status bar ostidan) silliq tushadi,
/// ikonka yo'q, bosilsa yoki yuqoriga surilsa yopiladi. Yangisi eskisining o'rnini egallaydi.
///
/// Navigatorning ildiz overlay'iga chiqadi — bottom sheet yopilgandan keyin ham ko'rinadi.
class Toast {
  Toast._();

  /// `GoRouter(navigatorKey: …)` — overlay shu orqali topiladi.
  static final navigatorKey = GlobalKey<NavigatorState>();

  static OverlayEntry? _entry;
  static GlobalKey<_ToastViewState>? _viewKey;

  static void show(String message, {ToastType type = ToastType.success, Duration? duration}) {
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;
    _dismissNow();
    final key = GlobalKey<_ToastViewState>();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastView(
        key: key,
        message: message,
        type: type,
        duration: duration ?? Duration(milliseconds: 1800 + message.length * 30).clampMax(5000),
        onDone: () {
          if (_entry == entry) {
            _entry = null;
            _viewKey = null;
          }
          if (entry.mounted) entry.remove();
        },
      ),
    );
    _entry = entry;
    _viewKey = key;
    overlay.insert(entry);
  }

  static void _dismissNow() {
    final e = _entry;
    _entry = null;
    _viewKey = null;
    if (e != null && e.mounted) e.remove();
  }

  /// Testlar uchun: hozir ko'rinib turgan toast'ni yopish.
  static void hide() => _viewKey?.currentState?._close();
}

extension on Duration {
  Duration clampMax(int ms) => inMilliseconds > ms ? Duration(milliseconds: ms) : this;
}

class _ToastView extends StatefulWidget {
  const _ToastView({super.key, required this.message, required this.type, required this.duration, required this.onDone});

  final String message;
  final ToastType type;
  final Duration duration;
  final VoidCallback onDone;

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    reverseDuration: const Duration(milliseconds: 220),
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  Timer? _timer;
  bool _closing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.status != AnimationStatus.dismissed) return;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _c.value = 1;
    } else {
      _c.forward();
    }
    _timer = Timer(widget.duration, _close);
  }

  Future<void> _close() async {
    if (_closing || !mounted) return;
    _closing = true;
    _timer?.cancel();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _c.value = 0;
    } else {
      await _c.reverse();
    }
    widget.onDone();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + Space.sm;
    return Positioned(
      top: top,
      left: Space.lg,
      right: Space.lg,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: AnimatedBuilder(
              animation: _curve,
              builder: (context, child) => Opacity(
                opacity: _curve.value.clamp(0.0, 1.0),
                child: FractionalTranslation(translation: Offset(0, (1 - _curve.value) * -1.3), child: child),
              ),
              child: GestureDetector(
                onTap: _close,
                onVerticalDragEnd: (d) {
                  if ((d.primaryVelocity ?? 0) < 0) _close();
                },
                child: Semantics(
                  liveRegion: true,
                  container: true,
                  child: Material(
                    color: widget.type.color,
                    elevation: 8,
                    shadowColor: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(Radii.md),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Space.xl, vertical: Space.md + 2),
                      child: Text(
                        widget.message,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
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
