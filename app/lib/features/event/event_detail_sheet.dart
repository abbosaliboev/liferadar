import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/l10n_ext.dart';
import '../../core/theme.dart';
import '../../core/toast.dart';
import '../../core/widgets.dart';
import '../../data/calendar_controller.dart';
import '../../data/providers.dart';
import '../../models/models.dart';
import '../weather/weather_chip.dart';
import 'signal_why_block.dart';

Future<void> showEventDetail(
  BuildContext context,
  RadarEvent event, {
  VoidCallback? onShowOnMap,
  RouteOpportunity? opportunity,
  Insight? insight,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true, // pastki navigatsiyani ham qoplaydi; to'liq ekranga yoyila oladi
    showDragHandle: false, // DetailSheet o'z tutqichini chizadi
    builder: (_) =>
        EventDetailSheet(event: event, onShowOnMap: onShowOnMap, opportunity: opportunity, insight: insight),
  );
}

class EventDetailSheet extends ConsumerStatefulWidget {
  const EventDetailSheet({super.key, required this.event, this.onShowOnMap, this.opportunity, this.insight});

  final RadarEvent event;
  final VoidCallback? onShowOnMap;

  /// Route rejimidan ochilganda: yo'ldan uzoqlik va qo'shimcha yo'l.
  final RouteOpportunity? opportunity;

  /// Home kartasidan ochilganda: signal nega chiqqani (kartada ko'rsatilmaydigan tafsilotlar).
  final Insight? insight;

  @override
  ConsumerState<EventDetailSheet> createState() => _EventDetailSheetState();
}

class _EventDetailSheetState extends ConsumerState<EventDetailSheet> {
  bool _adding = false;

  RadarEvent get event => widget.event;

  @override
  void initState() {
    super.initState();
    // Ko'rilgan deb belgilaymiz (kartalar xira bo'ladi). Build tugagach — provider'ni build ichida o'zgartirmaslik uchun.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(seenProvider.notifier).mark([
        'event:${event.id}',
        if (widget.insight != null) 'insight:${widget.insight!.id}',
      ]);
    });
  }

  /// Google Calendar'ga qo'shish. Ulanmagan bo'lsa Google ruxsat oynasi ochiladi.
  Future<void> _addToCalendar() async {
    final l10n = context.l10n;
    var title = context.tr(event.title);
    // E'lon: ko'p haftalik event emas — muddat kuni 09:00 da 1 soatlik eslatma.
    var target = event;
    if (event.placeless && event.deadline != null) {
      final d = event.deadline!;
      target = RadarEvent.fromJson({
        ...event.toJson(),
        'start': DateTime(d.year, d.month, d.day, 9).toIso8601String(),
        'end': DateTime(d.year, d.month, d.day, 10).toIso8601String(),
      });
      title = '${l10n.kindDeadline}: $title';
    }
    setState(() => _adding = true);
    try {
      await ref.read(calendarProvider.notifier).addEvent(target, title: title);
      Toast.show(l10n.addedToCalendar);
    } catch (e) {
      final notConfigured = e.toString().contains('not-configured');
      Toast.show(
        notConfigured ? l10n.calendarNotConfigured : l10n.calendarAddFailed,
        type: notConfigured ? ToastType.warning : ToastType.error,
      );
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final t = context.textStyles;
    final interests = ref.watch(interestsProvider);
    final matched = event.tags.where(interests.contains).toList();
    final o = widget.opportunity;
    final now = ref.watch(nowProvider);
    final ongoing = event.start.isBefore(DateTime(now.year, now.month, now.day));

    final addButton = FilledButton.icon(
      onPressed: _adding ? null : _addToCalendar,
      icon: _adding ? AppSpinner(color: p.textMuted) : const Icon(Icons.event_available_outlined),
      label: Text(_adding ? l10n.addingToCalendar : l10n.addToCalendar),
    );

    return DetailSheet(
      bodyBuilder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.xl),
        children: [
          if (event.imageUrl != null) ...[_Poster(event.imageUrl!), const SizedBox(height: Space.lg)],

          // ── Nima: kategoriya (sokin) + sarlavha ──
          QuietTags([
            QuietTag(context.categoryLabel(event.category), icon: categoryIcon(event.category)),
            if (ongoing) QuietTag(l10n.ongoing),
            if (event.isSample) QuietTag(l10n.sampleData),
          ]),
          const SizedBox(height: Space.sm),
          Text(context.tr(event.title), style: t.headlineSmall!.copyWith(height: 1.3)),
          const SizedBox(height: Space.lg),

          // ── Bir qarashda: qachon · qayerda · narx · muddat ──
          _FactsCard(
            children: [
              if (event.placeless)
                _Fact(
                  icon: Icons.event_available_outlined,
                  label: l10n.applicationLabel,
                  value: '${context.formatDate(event.start)} – ${context.formatDate(event.end)}',
                )
              else
                _Fact(
                  icon: Icons.calendar_today_outlined,
                  label: l10n.planWhen,
                  value: _dateRange(context, event),
                  sub: _timeRange(context, event),
                  extra: WeatherChip(location: event.location, date: event.start),
                ),
              if (event.placeless)
                _Fact(
                  icon: Icons.apartment_outlined,
                  label: l10n.organizer,
                  value: event.venue.isEmpty ? l10n.nationwide : event.venue,
                  sub: event.city == '전국' ? l10n.nationwide : event.city,
                )
              else
                _Fact(
                  icon: Icons.place_outlined,
                  label: l10n.planWhere,
                  value: event.venue,
                  sub: event.city,
                  trailing: widget.onShowOnMap == null
                      ? null
                      : IconButton.filledTonal(
                          tooltip: l10n.showOnMap,
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onShowOnMap!();
                          },
                          icon: const Icon(Icons.map_outlined, size: 20),
                        ),
                ),
              if (event.isFree == true || event.price != null)
                _Fact(
                  icon: Icons.confirmation_number_outlined,
                  label: l10n.eventPrice,
                  value: event.isFree == true ? l10n.free : event.price!,
                  tone: event.isFree == true ? Tone.primary : Tone.neutral,
                ),
              if (event.deadline != null)
                _Fact(
                  icon: Icons.hourglass_bottom_rounded,
                  label: l10n.kindDeadline,
                  value: context.formatDate(event.deadline!),
                  tone: Tone.accent,
                  trailing: _daysLeft(context, event.deadline!),
                ),
              if (o != null)
                _Fact(
                  icon: Icons.alt_route_rounded,
                  label: l10n.onYourWay,
                  value: o.detourKm != null
                      ? l10n.routeDetour(o.detourKm!.toStringAsFixed(1), o.detourMinutes!)
                      : l10n.routeFromRoute(o.distanceFromRouteKm.toStringAsFixed(1)),
                  tone: Tone.primary,
                ),
            ],
          ),

          // ── Nega ko'rsatildi (signal) ──
          if (widget.insight != null) ...[const SizedBox(height: Space.md), SignalWhyBlock(insight: widget.insight!)],

          // ── Nima haqida ──
          SectionHeader(l10n.eventAbout, padding: const EdgeInsets.fromLTRB(0, Space.xl, 0, Space.sm)),
          _ExpandableText(context.tr(event.description)),

          if (matched.isNotEmpty) ...[
            const SizedBox(height: Space.lg),
            Text(l10n.matchesYou, style: t.labelMedium),
            const SizedBox(height: Space.xs),
            QuietTags([
              for (final x in matched)
                if (interestByTag(x) case final o?) QuietTag(context.tr(o.label), icon: o.icon),
            ]),
          ],

          // ── Manba (ochiq ma'lumot litsenziyasi — atribut majburiy) + tarjima izohi ──
          if (!event.isSample) ...[
            const SizedBox(height: Space.xl),
            Divider(color: p.border, height: 1),
            const SizedBox(height: Space.md),
            if (context.lang != 'ko' && event.title.en != event.title.ko)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.xs),
                child: Row(
                  children: [
                    Icon(Icons.translate_rounded, size: 14, color: p.textMuted),
                    const SizedBox(width: Space.sm),
                    Expanded(child: Text(l10n.aiTranslated, style: t.labelSmall)),
                  ],
                ),
              ),
            Row(
              children: [
                Icon(Icons.verified_outlined, size: 14, color: p.textMuted),
                const SizedBox(width: Space.sm),
                Expanded(child: Text(l10n.dataSource(event.sourceName ?? event.source), style: t.labelSmall)),
                if (event.url != null)
                  TextButton(
                    onPressed: () => launchUrl(Uri.parse(event.url!), mode: LaunchMode.externalApplication),
                    child: Text(l10n.openSource),
                  ),
              ],
            ),
          ],
        ],
      ),
      // ── Harakatlar (doim ko'rinadi) ──
      bottom: DecoratedBox(
        decoration: BoxDecoration(
          color: p.surface,
          border: Border(top: BorderSide(color: p.border)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Space.gutter, Space.md, Space.gutter, Space.md),
            child: Row(
              children: [
                if (event.registerUrl != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => launchUrl(Uri.parse(event.registerUrl!), mode: LaunchMode.externalApplication),
                      child: Text(event.placeless ? l10n.applyNow : l10n.register),
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                ],
                Expanded(flex: 2, child: addButton),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Fri, Nov 20" yoki "Thu, Nov 19 – Sun, Nov 22".
String _dateRange(BuildContext context, RadarEvent e) {
  final sameDay = DateUtils.isSameDay(e.start, e.end);
  return sameDay ? context.formatDate(e.start) : '${context.formatDate(e.start)} – ${context.formatDate(e.end)}';
}

/// "19:30 – 21:30" (bir kunlik) yoki "10:00 – 18:00 (har kuni)" o'rniga oddiy vaqt oralig'i.
String _timeRange(BuildContext context, RadarEvent e) {
  String hm(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  return '${hm(e.start)} – ${hm(e.end)}';
}

Widget? _daysLeft(BuildContext context, DateTime deadline) {
  final now = DateTime.now();
  final left = DateTime(
    deadline.year,
    deadline.month,
    deadline.day,
  ).difference(DateTime(now.year, now.month, now.day)).inDays;
  if (left < 0 || left > 30) return null;
  return Pill(left == 0 ? context.l10n.today : 'D-$left', tone: Tone.accent, dense: true);
}

/// "Bir qarashda" kartasi: qatorlar ingichka chiziq bilan ajratilgan.
class _FactsCard extends StatelessWidget {
  const _FactsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.xs),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: p.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: Divider(height: 1, color: p.border),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Bitta fakt: rangli ikonka · kichik yorliq · qalin qiymat · (ixtiyoriy) izoh / qo'shimcha / tugma.
class _Fact extends StatelessWidget {
  const _Fact({
    required this.icon,
    required this.label,
    required this.value,
    this.sub,
    this.extra,
    this.trailing,
    this.tone = Tone.neutral,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? sub;
  final Widget? extra;
  final Widget? trailing;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.textStyles;
    final valueColor = switch (tone) {
      Tone.primary => p.primary,
      Tone.accent => p.accent,
      _ => p.text,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(icon, size: 36, tone: tone == Tone.neutral ? Tone.primary : tone),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: t.labelSmall),
                const SizedBox(height: 2),
                Text(value, style: t.titleSmall!.copyWith(color: valueColor)),
                if (sub != null && sub!.isNotEmpty) ...[const SizedBox(height: 1), Text(sub!, style: t.bodySmall)],
                if (extra != null) ...[const SizedBox(height: Space.sm), extra!],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: Space.sm), trailing!],
        ],
      ),
    );
  }
}

/// Uzun tavsif: 6 qatorgacha, qolgani "Ko'proq" bilan.
class _ExpandableText extends StatefulWidget {
  const _ExpandableText(this.text);
  final String text;

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _open = false;
  static const _lines = 6;

  @override
  Widget build(BuildContext context) {
    final t = context.textStyles;
    final style = t.bodyLarge!.copyWith(height: 1.6);
    return LayoutBuilder(
      builder: (context, c) {
        final tp = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: _lines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: c.maxWidth);
        final long = tp.didExceedMaxLines;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SmoothSize(
              alignment: Alignment.topCenter,
              child: Text(
                widget.text,
                style: style,
                maxLines: _open || !long ? null : _lines,
                overflow: _open || !long ? null : TextOverflow.ellipsis,
              ),
            ),
            if (long)
              TextButton(
                style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                onPressed: () => setState(() => _open = !_open),
                child: Text(_open ? context.l10n.showLess : context.l10n.showMore),
              ),
          ],
        );
      },
    );
  }
}

/// Event posteri. Web'da boshqa domendagi rasm CORS'siz bo'lishi mumkin — HTML <img> ga qaytamiz.
class _Poster extends StatelessWidget {
  const _Poster(this.url);
  final String url;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.lg),
      child: Container(
        height: 200,
        color: p.surfaceAlt,
        alignment: Alignment.center,
        child: Image.network(
          url,
          fit: BoxFit.contain,
          height: 200,
          webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
          errorBuilder: (_, _, _) => Icon(Icons.image_not_supported_outlined, color: p.textMuted),
          loadingBuilder: (context, child, progress) =>
              progress == null ? child : const Shimmer(child: SkeletonBox(height: 200)),
        ),
      ),
    );
  }
}
