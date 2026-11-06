import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/l10n_ext.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/providers.dart';
import '../../models/models.dart';
import '../event/event_detail_sheet.dart';
import '../shell/app_shell.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  EventCategory? _category;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.textStyles;
    final interests = ref.watch(interestsProvider);
    final all = ref.watch(eventsProvider);
    final events = all.where((e) => _category == null || e.category == _category).toList()
      ..sort((a, b) {
        final byScore = interestScore(b, interests).compareTo(interestScore(a, interests));
        return byScore != 0 ? byScore : a.start.compareTo(b.start);
      });
    final categories = all.map((e) => e.category).toSet().toList()..sort((a, b) => a.index.compareTo(b.index));
    final myInterests = interestOptions.where((o) => interests.contains(o.tag)).toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabDiscover)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: Space.xxxl),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
            child: Text(l10n.discoverSubtitle, style: t.bodySmall),
          ),
          const SizedBox(height: Space.md),

          // ── Qiziqishlar ──
          Padding(
            padding: const EdgeInsets.only(left: Space.gutter, right: Space.sm),
            child: Row(children: [
              Expanded(
                child: Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final o in myInterests) Pill(context.tr(o.label), icon: o.icon, tone: Tone.primary, dense: true),
                ]),
              ),
              TextButton(onPressed: () => context.push('/interests'), child: Text(l10n.edit)),
            ]),
          ),
          const SizedBox(height: Space.sm),

          // ── Kategoriyalar ──
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
              children: [
                ChoiceChip(
                  label: Text(l10n.discoverAll),
                  selected: _category == null,
                  onSelected: (_) => setState(() => _category = null),
                ),
                for (final c in categories) ...[
                  const SizedBox(width: Space.sm),
                  ChoiceChip(
                    avatar: Icon(categoryIcon(c)),
                    label: Text(context.categoryLabel(c)),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: Space.md),

          // ── Ro'yxat ──
          AnimatedSwitcher(
            duration: Motion.of(context, Motion.normal),
            child: Column(
              key: ValueKey(_category),
              children: [
                for (var i = 0; i < events.length; i++)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.md),
                    child: FadeSlideIn(index: i, child: EventCard(event: events[i], interests: interests)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Event kartasi: sana plitkasi + kategoriya + nom + joy + mos teglar.
class EventCard extends ConsumerWidget {
  const EventCard({super.key, required this.event, required this.interests, this.trailing});

  final RadarEvent event;
  final Set<String> interests;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.textStyles;
    final matched = event.tags.where(interests.contains).toList();
    return Card(
      child: InkWell(
        onTap: () => showEventDetail(context, event, onShowOnMap: () {
          ref.read(mapFocusProvider.notifier).focus(event.id);
          context.go('/map');
        }),
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            DateTile(event.start, monthLabel: DateFormat.MMM(context.lang).format(event.start)),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Pill(context.categoryLabel(event.category), icon: categoryIcon(event.category), dense: true),
                  if (event.isSample) ...[const SizedBox(width: 6), const SampleBadge()],
                ]),
                const SizedBox(height: 6),
                Text(context.tr(event.title), style: t.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                MetaRow(Icons.place_outlined, '${event.venue} · ${event.city}'),
                if (matched.isNotEmpty) ...[
                  const SizedBox(height: Space.sm),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    for (final tag in matched) Pill('#$tag', tone: Tone.primary, dense: true),
                  ]),
                ],
              ]),
            ),
            trailing ?? Icon(Icons.chevron_right_rounded, color: context.palette.textMuted),
          ]),
        ),
      ),
    );
  }
}
