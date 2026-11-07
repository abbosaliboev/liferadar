import 'package:flutter/material.dart';
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

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            if (cal.isConnected) await ref.read(calendarProvider.notifier).sync();
            ref.invalidate(forecastProvider);
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: Space.xxxl),
            children: [
              // ── Sarlavha ──
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.gutter, Space.lg, Space.gutter, 0),
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

              // ── Statistika = filtr ──
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.gutter, Space.xl, Space.gutter, 0),
                child: _FilterBar(
                  selected: _filter,
                  counts: {
                    HomeFilter.plans: forPlans.length,
                    HomeFilter.all: all.length,
                    HomeFilter.deadlines: deadlines.length,
                  },
                  onSelect: (f) => setState(() => _filter = f),
                ),
              ),

              SectionHeader(switch (_filter) {
                HomeFilter.all => l10n.homeGreeting,
                HomeFilter.plans => l10n.homeSectionPlans,
                HomeFilter.deadlines => l10n.homeSectionDeadlines,
              }),

              // ── Kartalar ──
              if (cal.isBusy)
                const Shimmer(
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
                )
              else if (all.isEmpty)
                EmptyState(
                  icon: Icons.radar,
                  title: l10n.homeEmptyTitle,
                  body: l10n.homeEmptyBody,
                  actions: [
                    FilledButton(onPressed: () => context.go('/plans'), child: Text(l10n.connectCalendar)),
                    OutlinedButton(onPressed: () => context.push('/interests'), child: Text(l10n.interestsEdit)),
                  ],
                )
              else if (shown.isEmpty)
                EmptyState(icon: Icons.inbox_outlined, title: l10n.homeFilterEmpty)
              else
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
          ),
        ),
      ),
    );
  }

  static DateTime _deadlineOf(WidgetRef ref, Insight i) {
    final e = i.eventIds.isEmpty ? null : ref.read(eventByIdProvider(i.eventIds.first));
    return e?.deadline ?? DateTime(9999);
  }
}

/// Uchta bo'lak: tanlangani aniq ko'rinadi (fon + rang + qalin), boshqalari bosiladigan.
class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.counts, required this.onSelect});

  final HomeFilter selected;
  final Map<HomeFilter, int> counts;
  final ValueChanged<HomeFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final t = context.textStyles;
    final d = Motion.of(context, Motion.fast);

    Widget cell(HomeFilter f, String label) {
      final on = f == selected;
      final urgent = f == HomeFilter.deadlines && (counts[f] ?? 0) > 0;
      final numberColor = on ? p.primary : (urgent ? p.accent : p.text);
      return Expanded(
        child: Semantics(
          button: true,
          selected: on,
          label: '$label ${counts[f]}',
          child: ExcludeSemantics(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(Radii.md),
                onTap: () => onSelect(f),
                child: AnimatedContainer(
                  duration: d,
                  curve: Motion.curve,
                  padding: const EdgeInsets.symmetric(vertical: Space.md),
                  decoration: BoxDecoration(
                    color: on ? p.primarySoft : Colors.transparent,
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  child: Column(
                    children: [
                      Text('${counts[f] ?? 0}', style: t.headlineSmall!.copyWith(color: numberColor)),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.labelMedium!.copyWith(
                          color: on ? p.primary : p.textMuted,
                          fontWeight: on ? FontWeight.w700 : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.xs + 2),
        child: Row(
          children: [
            cell(HomeFilter.plans, l10n.statForPlans),
            const SizedBox(width: Space.xs),
            cell(HomeFilter.all, l10n.statAll),
            const SizedBox(width: Space.xs),
            cell(HomeFilter.deadlines, l10n.statSoon),
          ],
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
            SignalWhyBlock(insight: insight, showTitle: true),
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
