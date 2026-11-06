import 'package:flutter/material.dart';

import 'theme.dart';

// Umumiy UI bloklari — barcha ekranlar shulardan yig'iladi.

// ───────────────────────────── Skeleton / Shimmer ─────────────────────────────

/// Ichidagi [SkeletonBox]larga bitta umumiy shimmer to'lqinini beradi.
/// "Animatsiyani kamaytirish" yoqilgan bo'lsa — statik.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});
  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return widget.child;
    final p = context.palette;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (rect) => LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [p.skeleton, p.surfaceAlt.withValues(alpha: 0.9), p.skeleton],
          stops: const [0.25, 0.5, 0.75],
          transform: _SlideGradient(_c.value),
        ).createShader(rect),
        child: child,
      ),
    );
  }
}

class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.t);
  final double t;
  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * (t * 2 - 1), 0, 0);
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, this.height = 14, this.radius = Radii.sm});
  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: context.palette.skeleton, borderRadius: BorderRadius.circular(radius)),
      );
}

/// Karta ko'rinishidagi tayyor skeleton (ro'yxatlar yuklanayotganda).
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.lines = 2, this.leading = true});
  final int lines;
  final bool leading;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (leading) ...[
              const SkeletonBox(width: 44, height: 44, radius: Radii.md),
              const SizedBox(width: Space.md),
            ],
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SkeletonBox(width: 160, height: 16),
                for (var i = 0; i < lines; i++) ...[
                  const SizedBox(height: Space.sm),
                  SkeletonBox(width: i == lines - 1 ? 120 : double.infinity, height: 12),
                ],
              ]),
            ),
          ]),
        ),
      );
}

// ───────────────────────────── Matn / sarlavhalar ─────────────────────────────

/// Bo'lim sarlavhasi: "Kelgusi rejalar ........ Hammasi".
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.padding});
  final String title;
  final Widget? action;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding ?? const EdgeInsets.fromLTRB(Space.gutter, Space.xxl, Space.sm, Space.sm),
        child: Row(children: [
          Expanded(
            child: Semantics(header: true, child: Text(title, style: context.textStyles.titleMedium)),
          ),
          ?action,
        ]),
      );
}

/// Kichik teg: "일정 알림", "D-12", "#ai".
enum Tone { neutral, primary, accent, danger, info }

class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, this.icon, this.tone = Tone.neutral, this.dense = false});
  final String label;
  final IconData? icon;
  final Tone tone;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (bg, fg) = switch (tone) {
      Tone.neutral => (p.surfaceAlt, p.textMuted),
      Tone.primary => (p.primarySoft, p.primary),
      Tone.accent => (p.accentSoft, p.accent),
      Tone.danger => (p.dangerSoft, p.danger),
      Tone.info => (p.infoSoft, p.info),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 6 : Space.sm, vertical: dense ? 2 : 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(Radii.sm)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          ExcludeSemantics(child: Icon(icon, size: dense ? 12 : 14, color: fg)),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.labelSmall!.copyWith(color: fg, fontSize: dense ? 10.5 : 11.5),
          ),
        ),
      ]),
    );
  }
}

/// Ikonka + matn qatori (meta ma'lumot).
class MetaRow extends StatelessWidget {
  const MetaRow(this.icon, this.text, {super.key, this.color, this.maxLines = 1});
  final IconData icon;
  final String text;
  final Color? color;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.palette.textMuted;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(top: 1),
        child: ExcludeSemantics(child: Icon(icon, size: 16, color: c)),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          text,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: context.textStyles.bodySmall!.copyWith(color: c),
        ),
      ),
    ]);
  }
}

// ───────────────────────────── Bloklar ─────────────────────────────

/// Sana plitkasi (event ro'yxatlari uchun): "NOV / 20".
class DateTile extends StatelessWidget {
  const DateTile(this.date, {super.key, this.color, this.monthLabel});
  final DateTime date;
  final Color? color;
  final String? monthLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = color ?? p.primary;
    return Container(
      width: 48,
      height: 52,
      decoration: BoxDecoration(color: p.surfaceAlt, borderRadius: BorderRadius.circular(Radii.md)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(monthLabel ?? '${date.month}', style: context.textStyles.labelSmall!.copyWith(color: c, fontSize: 10.5)),
        Text('${date.day}', style: context.textStyles.titleLarge!.copyWith(height: 1.1)),
      ]),
    );
  }
}

/// Ikonkali kvadrat (kategoriya/holat belgisi).
class IconTile extends StatelessWidget {
  const IconTile(this.icon, {super.key, this.tone = Tone.primary, this.size = 40});
  final IconData icon;
  final Tone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (bg, fg) = switch (tone) {
      Tone.neutral => (p.surfaceAlt, p.textMuted),
      Tone.primary => (p.primarySoft, p.primary),
      Tone.accent => (p.accentSoft, p.accent),
      Tone.danger => (p.dangerSoft, p.danger),
      Tone.info => (p.infoSoft, p.info),
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(Radii.md)),
      child: ExcludeSemantics(child: Icon(icon, size: size * 0.5, color: fg)),
    );
  }
}

/// Bo'sh holat: ikonka + sarlavha + izoh + harakatlar.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.body, this.actions = const []});
  final IconData icon;
  final String title;
  final String? body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.xxl, vertical: Space.xxxl),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          IconTile(icon, size: 56),
          const SizedBox(height: Space.lg),
          Text(title, style: context.textStyles.titleMedium, textAlign: TextAlign.center),
          if (body != null) ...[
            const SizedBox(height: Space.sm),
            Text(body!, style: context.textStyles.bodyMedium!.copyWith(color: context.palette.textMuted),
                textAlign: TextAlign.center),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: Space.xl),
            Wrap(spacing: Space.sm, runSpacing: Space.sm, alignment: WrapAlignment.center, children: actions),
          ],
        ]),
      );
}

/// Profil rasmi: rasm bo'lmasa bosh harflar.
class AppAvatar extends StatelessWidget {
  const AppAvatar({super.key, this.photoUrl, this.name, this.size = 48});
  final String? photoUrl;
  final String? name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final initials = (name ?? '').trim().isEmpty ? null : name!.trim().characters.first.toUpperCase();
    final fallback = Center(
      child: initials == null
          ? Icon(Icons.person_outline, size: size * 0.5, color: p.primary)
          : Text(initials, style: context.textStyles.titleMedium!.copyWith(color: p.primary, fontSize: size * 0.4)),
    );
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: p.primarySoft, shape: BoxShape.circle),
      child: photoUrl == null
          ? fallback
          : Image.network(photoUrl!, fit: BoxFit.cover, errorBuilder: (_, _, _) => fallback),
    );
  }
}

/// Guruhlangan sozlamalar/ma'lumot bloki (iOS Settings uslubi).
class GroupCard extends StatelessWidget {
  const GroupCard({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
        child: Column(children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(indent: Space.lg, endIndent: Space.lg),
            children[i],
          ],
        ]),
      );
}

// ───────────────────────────── Harakat ─────────────────────────────

/// Ro'yxat elementlari uchun yumshoq kirish: shaffoflik + 8px yuqoriga siljish, [index] bo'yicha kechikish.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({super.key, required this.child, this.index = 0});
  final Widget child;
  final int index;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: Motion.slow);
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Motion.curve);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.isAnimating || _c.isCompleted) return;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _c.value = 1;
      return;
    }
    Future.delayed(Duration(milliseconds: 40 * widget.index.clamp(0, 8)), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _a,
        child: AnimatedBuilder(
          animation: _a,
          child: widget.child,
          builder: (_, child) => Transform.translate(offset: Offset(0, 8 * (1 - _a.value)), child: child),
        ),
      );
}
