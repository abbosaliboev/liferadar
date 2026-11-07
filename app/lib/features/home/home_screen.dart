import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/confirm.dart';
import '../../core/l10n_ext.dart';
import '../../core/theme.dart';
import '../../core/toast.dart';
import '../../core/widgets.dart';
import '../../data/calendar_controller.dart';
import '../../data/providers.dart';
import '../../data/session.dart';
import '../../models/models.dart';
import '../event/event_detail_sheet.dart';
import '../event/signal_why_block.dart';
import '../weather/weather_chip.dart';

/// Home'dagi uchta statistika — bir vaqtning o'zida filtr ham.
enum HomeFilter { plans, all, deadlines }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  HomeFilter _filter = HomeFilter.all;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.textStyles;
    final session = ref.watch(sessionProvider);
    final cal = ref.watch(calendarProvider);
    final now = ref.watch(nowProvider);
    final all = ref.watch(insightsProvider).where((i) => i.feedback != InsightFeedback.hidden).toList();
    final forPlans = all.where((i) => i.planId != null).toList();
    final deadlines = all.where((i) => i.kind == InsightKind.deadline).toList()
      ..sort((a, b) => _deadlineOf(ref, a).compareTo(_deadlineOf(ref, b)));
    final shown = switch (_filter) {
      HomeFilter.all => all,
      HomeFilter.plans => forPlans,
      HomeFilter.deadlines => deadlines,
    };
    // Foydalanuvchi o'zi kiritgan ism; bo'lmasa Google'dagi birinchi so'z.
    final name =
        ref.watch(profileNameProvider) ?? (session == null || session.isGuest ? null : session.name?.split(' ').first);

    final counts = {
      HomeFilter.plans: forPlans.length,
      HomeFilter.all: all.length,
      HomeFilter.deadlines: deadlines.length,
    };

    // Kartalar ro'yxati (filtr almashganda yon tomonga siljib almashadi).
    final Widget cards;
    if (cal.isBusy) {
      cards = const Shimmer(
        key: ValueKey('busy'),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: Space.gutter),
          child: Column(
            children: [
              SkeletonCard(lines: 2, leading: false),
              SizedBox(height: Space.md),
              SkeletonCard(lines: 2, leading: false),
            ],
          ),
        ),
      );
    } else if (all.isEmpty) {
      cards = EmptyState(
        key: const ValueKey('empty'),
        icon: Icons.radar,
        title: l10n.homeEmptyTitle,
        body: l10n.homeEmptyBody,
        actions: [
          FilledButton(onPressed: () => context.go('/plans'), child: Text(l10n.connectCalendar)),
          OutlinedButton(onPressed: () => context.push('/interests'), child: Text(l10n.interestsEdit)),
        ],
      );
    } else if (shown.isEmpty) {
      cards = EmptyState(
        key: ValueKey('none-${_filter.name}'),
        icon: Icons.inbox_outlined,
        title: l10n.homeFilterEmpty,
      );
    } else {
      cards = Column(
        key: ValueKey(_filter),
        children: [
          for (var i = 0; i < shown.length; i++)
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.md),
              child: FadeSlideIn(
                key: ValueKey('${_filter.name}-${shown[i].id}'),
                index: i,
                child: InsightCard(insight: shown[i]),
              ),
            ),
        ],
      );
    }

    final d = Motion.of(context, Motion.normal);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        // Yonga surish — filtrlar orasida o'tish (Mening rejalarim ↔ Barchasi ↔ Muddati yaqin).
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragEnd: (e) {
            final v = e.primaryVelocity ?? 0;
            if (v.abs() < 250) return;
            final i = _filter.index + (v < 0 ? 1 : -1);
            if (i >= 0 && i < HomeFilter.values.length) _select(HomeFilter.values[i]);
          },
          child: RefreshIndicator(
            onRefresh: () async {
              if (cal.isConnected) await ref.read(calendarProvider.notifier).sync();
              ref.invalidate(forecastProvider);
            },
            child: CustomScrollView(
              slivers: [
                // ── Sarlavha ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(Space.gutter, Space.lg, Space.gutter, Space.xs),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(DateFormat.MMMMEEEEd(context.lang).format(now), style: t.labelMedium),
                              const SizedBox(height: 2),
                              Text(name == null ? l10n.homeHello : l10n.homeHelloName(name), style: t.headlineSmall),
                            ],
                          ),
                        ),
                        Semantics(
                          button: true,
                          label: l10n.tabProfile,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => context.go('/profile'),
                            child: AppAvatar(photoUrl: session?.photoUrl, name: name, size: 40),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Filtr: tepada qadalgan, aylantirganda shisha "pill"ga aylanadi ──
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _FilterHeader(
                    selected: _filter,
                    counts: counts,
                    onSelect: _select,
                    labels: (l10n.statForPlans, l10n.statAll, l10n.statSoon),
                  ),
                ),

                SliverToBoxAdapter(
                  child: SectionHeader(switch (_filter) {
                    HomeFilter.all => l10n.homeGreeting,
                    HomeFilter.plans => l10n.homeSectionPlans,
                    HomeFilter.deadlines => l10n.homeSectionDeadlines,
                  }),
                ),

                // ── Kartalar ──
                SliverToBoxAdapter(
                  child: AnimatedSwitcher(
                    duration: d,
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    layoutBuilder: (current, previous) =>
                        Stack(alignment: Alignment.topCenter, children: [...previous, ?current]),
                    transitionBuilder: (child, anim) {
                      final incoming = child.key == cards.key;
                      final dx = (incoming == _forward) ? 0.18 : -0.18;
                      return FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween(begin: Offset(dx, 0), end: Offset.zero).animate(anim),
                          child: child,
                        ),
                      );
                    },
                    child: cards,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: Space.xxxl)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Oldinga/orqaga — kartalar qaysi tomonga siljishini belgilaydi.
  bool _forward = true;

  void _select(HomeFilter f) {
    if (f == _filter) return;
    HapticFeedback.selectionClick();
    setState(() {
      _forward = f.index > _filter.index;
      _filter = f;
    });
  }

  static DateTime _deadlineOf(WidgetRef ref, Insight i) {
    final e = i.eventIds.isEmpty ? null : ref.read(eventByIdProvider(i.eventIds.first));
    return e?.deadline ?? DateTime(9999);
  }
}

/// Qadalgan filtr sarlavhasi. [t] = 0 — katta karta (raqamlar katta), 1 — ixcham shisha pill
/// (iOS segmented control kabi: siljuvchi indikator, katta radius, orqa fon xiralashadi).
class _FilterHeader extends SliverPersistentHeaderDelegate {
  _FilterHeader({required this.selected, required this.counts, required this.onSelect, required this.labels});

  final HomeFilter selected;
  final Map<HomeFilter, int> counts;
  final ValueChanged<HomeFilter> onSelect;
  final (String, String, String) labels;

  static const _max = 112.0;
  static const _min = 64.0;

  @override
  double get maxExtent => _max;

  @override
  double get minExtent => _min;

  @override
  bool shouldRebuild(_FilterHeader old) =>
      old.selected != selected || old.counts.toString() != counts.toString() || old.labels != labels;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final p = context.palette;
    final t = context.textStyles;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final k = Curves.easeInOut.transform((shrinkOffset / (_max - _min)).clamp(0.0, 1.0));
    double lerp(double a, double b) => a + (b - a) * k;

    final radius = lerp(Radii.lg, 28);
    final hPad = lerp(Space.gutter, Space.gutter + 18);
    final d = Motion.of(context, Motion.normal);
    final index = selected.index;

    Widget cell(HomeFilter f, String label) {
      final on = f == selected;
      final n = counts[f] ?? 0;
      final urgent = f == HomeFilter.deadlines && n > 0;
      final numberColor = on ? p.primary : (urgent ? p.accent : p.text);
      return Expanded(
        child: Semantics(
          button: true,
          selected: on,
          label: '$label $n',
          child: ExcludeSemantics(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelect(f),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Katta raqam — yig'ilganda balandligi va shaffofligi kamayadi.
                  ClipRect(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      heightFactor: 1 - k,
                      child: Opacity(
                        opacity: (1 - k * 1.6).clamp(0.0, 1.0),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text('$n', style: t.headlineSmall!.copyWith(color: numberColor)),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.labelMedium!.copyWith(
                            color: on ? p.primary : p.textMuted,
                            fontWeight: on ? FontWeight.w700 : FontWeight.w600,
                          ),
                        ),
                      ),
                      // Ixcham holatda soni yorliq yonida — kichik "badge".
                      if (k > 0.02)
                        Opacity(
                          opacity: ((k - 0.35) / 0.65).clamp(0.0, 1.0),
                          child: Container(
                            margin: const EdgeInsets.only(left: 5),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: on ? p.primary : (urgent ? p.accent : p.textMuted.withValues(alpha: 0.18)),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$n',
                              style: t.labelSmall!.copyWith(
                                color: on || urgent ? p.onPrimary : p.textMuted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final glass = p.surface.withValues(alpha: lerp(1, dark ? 0.62 : 0.70));
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, lerp(Space.lg, Space.sm), hPad, lerp(Space.sm, 6)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: (dark ? 0.35 : 0.10) * k),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18 * k, sigmaY: 18 * k),
            child: Container(
              decoration: BoxDecoration(
                color: glass,
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: (dark ? Colors.white : p.border).withValues(alpha: dark ? 0.10 : 0.9)),
              ),
              padding: const EdgeInsets.all(4),
              child: Stack(
                children: [
                  // Siljuvchi indikator (tanlangan bo'lak).
                  AnimatedAlign(
                    duration: d,
                    curve: Curves.easeOutCubic,
                    alignment: Alignment(-1 + index.toDouble(), 0),
                    child: FractionallySizedBox(
                      widthFactor: 1 / 3,
                      heightFactor: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: p.primarySoft,
                          borderRadius: BorderRadius.circular(radius - 4),
                          boxShadow: k > 0.5
                              ? [
                                  BoxShadow(
                                    color: p.primary.withValues(alpha: 0.12),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      cell(HomeFilter.plans, labels.$1),
                      cell(HomeFilter.all, labels.$2),
                      cell(HomeFilter.deadlines, labels.$3),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Signalni ochish: event bo'lsa — event oynasi (+ "nega" bloki), bo'lmasa — signal oynasi.
void openSignal(BuildContext context, WidgetRef ref, Insight insight) {
  final event = insight.eventIds.isEmpty ? null : ref.read(eventByIdProvider(insight.eventIds.first));
  if (event != null) {
    showEventDetail(
      context,
      event,
      insight: insight,
      onShowOnMap: event.placeless
          ? null
          : () {
              ref.read(mapFocusProvider.notifier).focus(event.id);
              context.go('/map');
            },
    );
    return;
  }
  ref.read(seenProvider.notifier).mark(['insight:${insight.id}']);
  final plan = insight.planId == null ? null : ref.read(plansProvider).where((p) => p.id == insight.planId).firstOrNull;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SignalWhyBlock(insight: insight, standalone: true),
            if (plan?.location != null) ...[
              const SizedBox(height: Space.md),
              WeatherChip(location: plan!.location!, date: plan.start),
            ],
          ],
        ),
      ),
    ),
  );
}

/// Ixcham signal kartasi: NIMA (sarlavha) · QACHON · QAYERDA · KIM UCHUN (qiziqishlar).
/// Batafsil ("nega muhim", manbalar, banner, havolalar) — bosilganda.
class InsightCard extends ConsumerWidget {
  const InsightCard({super.key, required this.insight});

  final Insight insight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final p = context.palette;
    final t = context.textStyles;
    final now = ref.watch(nowProvider);
    final today = DateTime(now.year, now.month, now.day);
    final interests = ref.watch(interestsProvider);
    final seen = ref.watch(seenProvider);
    final plan = insight.planId == null
        ? null
        : ref.watch(plansProvider).where((x) => x.id == insight.planId).firstOrNull;
    final event = insight.eventIds.isEmpty ? null : ref.watch(eventByIdProvider(insight.eventIds.first));
    final (kindLabel, kindIcon, tone) = insightKindMeta(context, insight.kind);
    final isSeen = seen.contains('insight:${insight.id}') || (event != null && seen.contains('event:${event.id}'));

    // NIMA — event bo'lsa uning nomi (qisqa va aniq), aks holda signal sarlavhasi.
    final what = event != null ? context.tr(event.title) : context.tr(insight.title);

    // QACHON
    String? when;
    if (event != null && event.placeless && event.deadline != null) {
      // Belgi allaqachon "Deadline" desa — takrorlamaymiz.
      final date = context.formatDate(event.deadline!);
      when = insight.kind == InsightKind.deadline ? date : '${l10n.kindDeadline} · $date';
    } else if (event != null) {
      final from = plan != null && event.start.isBefore(plan.start) ? plan.start : event.start;
      when = event.start.isBefore(today) && plan == null
          ? l10n.untilDate(context.formatDate(event.end))
          : (from.hour == 0 && from.minute == 0 ? context.formatDate(from) : context.formatDateTime(from));
    } else if (plan != null) {
      when = context.formatDate(plan.start);
    }

    // QAYERDA
    String? where;
    if (event != null && event.placeless) {
      where = event.city == '전국' ? l10n.nationwide : event.city;
    } else if (event != null) {
      where = [event.venue, event.city].where((s) => s.isNotEmpty).join(' · ');
    } else if (plan != null && plan.locationText.isNotEmpty) {
      where = plan.locationText;
    }

    // KIM UCHUN / NIMA HAQIDA — mos qiziqishlar (ko'pi bilan 2 ta), bo'lmasa kategoriya.
    final matched = [
      for (final tag in event?.tags ?? const <String>[])
        if (interests.contains(tag)) ?interestByTag(tag),
    ].take(2).toList();

    // Muddat yaqin bo'lsa — o'ng yuqorida D-n.
    final dl = event?.deadline;
    final left = dl == null ? null : DateTime(dl.year, dl.month, dl.day).difference(today).inDays;
    final showLeft = left != null && left >= 0 && left <= 14;

    /// 👍/👎: bosilgan holatda yana bosish — bekor qilish (tasdiq bilan).
    /// 👎 berish ham tasdiqlanadi (tasodifan bosib yubormaslik uchun).
    Future<void> react(InsightFeedback f) async {
      final notifier = ref.read(insightFeedbackProvider.notifier);
      final current = insight.feedback;
      if (current == f) {
        final undo = await showConfirm(
          context,
          icon: f == InsightFeedback.like ? Icons.thumb_up_off_alt_rounded : Icons.visibility_outlined,
          title: f == InsightFeedback.like ? l10n.likeUndoTitle : l10n.dislikeUndoTitle,
          body: f == InsightFeedback.like ? l10n.likeUndoBody : l10n.dislikeUndoBody,
          confirmLabel: f == InsightFeedback.like ? l10n.removeLike : l10n.showAgain,
          cancelLabel: l10n.keep,
        );
        if (!undo) return;
        await notifier.clear(insight.id);
        Toast.show(l10n.feedbackCleared, type: ToastType.info);
        return;
      }
      if (f == InsightFeedback.dislike) {
        if (!context.mounted) return;
        final ok = await showConfirm(
          context,
          icon: Icons.thumb_down_alt_outlined,
          title: l10n.dislikeConfirmTitle,
          body: l10n.dislikeConfirmBody,
          confirmLabel: l10n.notForMeConfirm,
          cancelLabel: l10n.keep,
        );
        if (!ok) return;
      }
      await notifier.set(insight.id, f);
      Toast.show(f == InsightFeedback.like ? l10n.feedbackLiked : l10n.feedbackDisliked);
    }

    return AnimatedOpacity(
      duration: Motion.of(context, Motion.normal),
      opacity: isSeen ? 0.6 : 1,
      child: Card(
        child: InkWell(
          onTap: () => openSignal(context, ref, insight),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.sm, Space.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tur + qaysi reja bilan bog'liq + muddat
                Padding(
                  padding: const EdgeInsets.only(right: Space.sm),
                  child: Row(
                    children: [
                      Pill(kindLabel, icon: kindIcon, tone: tone, dense: true),
                      if (plan != null) ...[
                        const SizedBox(width: Space.sm),
                        Flexible(
                          child: Text(
                            plan.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.labelMedium!.copyWith(color: p.textMuted),
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (showLeft) Pill(left == 0 ? l10n.today : 'D-$left', tone: Tone.accent, dense: true),
                    ],
                  ),
                ),
                const SizedBox(height: Space.sm),
                Padding(
                  padding: const EdgeInsets.only(right: Space.sm),
                  child: MarqueeText(what, style: t.titleMedium),
                ),
                const SizedBox(height: 6),
                if (when != null) MetaRow(Icons.schedule_outlined, when),
                if (where != null && where.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  MetaRow(event?.placeless == true ? Icons.apartment_outlined : Icons.place_outlined, where),
                ],
                Row(
                  children: [
                    Expanded(
                      child: QuietTags([
                        for (final o in matched) QuietTag(context.tr(o.label), icon: o.icon),
                        if (matched.isEmpty && event != null)
                          QuietTag(context.categoryLabel(event.category), icon: categoryIcon(event.category)),
                      ]),
                    ),
                    IconButton(
                      tooltip: l10n.helpful,
                      visualDensity: VisualDensity.compact,
                      isSelected: insight.feedback == InsightFeedback.like,
                      selectedIcon: Icon(Icons.thumb_up_rounded, color: p.primary, size: 18),
                      icon: Icon(Icons.thumb_up_outlined, size: 18, color: p.textMuted),
                      onPressed: () => react(InsightFeedback.like),
                    ),
                    IconButton(
                      tooltip: l10n.notForMe,
                      visualDensity: VisualDensity.compact,
                      isSelected: insight.feedback == InsightFeedback.dislike,
                      selectedIcon: Icon(Icons.thumb_down_rounded, color: p.textMuted, size: 18),
                      icon: Icon(Icons.thumb_down_outlined, size: 18, color: p.textMuted),
                      onPressed: () => react(InsightFeedback.dislike),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
