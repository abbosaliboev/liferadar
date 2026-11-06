import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n_ext.dart';
import '../../core/theme.dart';
import '../../core/toast.dart';
import '../../core/widgets.dart';
import '../../data/calendar_controller.dart';
import '../../data/session.dart';
import 'google_button.dart';

/// Kirish / ro'yxatdan o'tish. Google akkaunt = ro'yxatdan o'tish (alohida forma yo'q).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(sessionProvider.notifier).listenForGoogle(_next, (e) {
      if (mounted) Toast.show(context.l10n.loginError, type: ToastType.error);
    });
  }

  void _next() {
    if (!mounted) return;
    context.go(nextAfterAuthOf(ref)); // ism → qiziqishlar → home
  }

  Future<void> _guest() async {
    await ref.read(sessionProvider.notifier).continueAsGuest();
    _next();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final t = context.textStyles;
    final lang = context.lang;

    return Scaffold(
      body: DecoratedBox(
        // Xush kelibsiz ekrani bilan bir xil yumshoq gradient — oqim uzilmasin.
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0, 0.45, 1],
            colors: [p.primarySoft, p.background, p.background],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: LayoutBuilder(
                builder: (context, c) => SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: Space.xxl),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: c.maxHeight),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => ref.read(localeProvider.notifier).set(Locale(lang == 'ko' ? 'en' : 'ko')),
                            child: Text(lang == 'ko' ? 'English' : '한국어'),
                          ),
                        ),
                        const SizedBox(height: Space.xxl),
                        const Center(child: RadarMark(size: 112)),
                        const SizedBox(height: Space.xxl),
                        Text(l10n.appTitle, textAlign: TextAlign.center, style: t.headlineMedium),
                        const SizedBox(height: Space.sm),
                        Text(
                          l10n.onboardingTagline,
                          textAlign: TextAlign.center,
                          style: t.bodyLarge!.copyWith(color: p.textMuted),
                        ),
                        const SizedBox(height: Space.xxxl),
                        _Benefit(Icons.event_note_outlined, l10n.loginBenefitPlans),
                        _Benefit(Icons.alt_route_rounded, l10n.loginBenefitRoute),
                        _Benefit(Icons.notifications_none_rounded, l10n.loginBenefitSignals),
                        const SizedBox(height: Space.xxxl),
                        if (isGoogleSignInConfigured) ...[
                          Center(
                            child: googleSignInButton(
                              context,
                              languageCode: lang,
                              width: math.min(c.maxWidth - 48, 360),
                            ),
                          ),
                          const SizedBox(height: Space.sm),
                          Text(l10n.loginNewUser, textAlign: TextAlign.center, style: t.bodySmall),
                          const SizedBox(height: Space.xl),
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: Space.md),
                                child: Text(l10n.or, style: t.bodySmall),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: Space.xl),
                        ],
                        OutlinedButton(onPressed: _guest, child: Text(l10n.continueAsGuest)),
                        const SizedBox(height: Space.lg),
                        Text(l10n.loginPrivacy, textAlign: TextAlign.center, style: t.bodySmall),
                        const SizedBox(height: Space.xxl),
                      ],
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

class _Benefit extends StatelessWidget {
  const _Benefit(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Space.sm),
    child: Row(
      children: [
        IconTile(icon, size: 40),
        const SizedBox(width: Space.lg),
        Expanded(child: Text(text, style: context.textStyles.bodyMedium)),
      ],
    ),
  );
}

/// Brend belgisi: konsentrik halqalar + sekin aylanuvchi "sweep" + signal nuqtalari.
class RadarMark extends StatefulWidget {
  const RadarMark({super.key, this.size = 96});
  final double size;

  @override
  State<RadarMark> createState() => _RadarMarkState();
}

class _RadarMarkState extends State<RadarMark> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 6));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _c.stop();
      _c.value = 0.15;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) => CustomPaint(painter: _RadarPainter(_c.value, p.primary, p.primarySoft, p.accent)),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter(this.t, this.color, this.soft, this.accent);
  final double t;
  final Color color, soft, accent;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    canvas.drawCircle(c, r, Paint()..color = soft);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = color.withValues(alpha: 0.35);
    for (final f in [0.33, 0.66, 0.97]) {
      canvas.drawCircle(c, r * f, ring);
    }
    final angle = t * 2 * math.pi;
    final sweep = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi / 2,
        colors: [color.withValues(alpha: 0), color.withValues(alpha: 0.35)],
        transform: GradientRotation(angle - math.pi / 2),
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.97), angle - math.pi / 2, math.pi / 2, true, sweep);
    canvas.drawLine(
      c,
      c + Offset(math.cos(angle), math.sin(angle)) * r * 0.97,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(c, 4, Paint()..color = color);
    canvas.drawCircle(c + Offset(r * 0.42, -r * 0.3), 4.5, Paint()..color = accent);
    canvas.drawCircle(c + Offset(-r * 0.5, r * 0.36), 3.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.t != t || old.color != color;
}
