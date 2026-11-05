import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/l10n_ext.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../models/models.dart';
import '../shell/app_shell.dart';

Future<void> showEventDetail(BuildContext context, RadarEvent event, {VoidCallback? onShowOnMap}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => EventDetailSheet(event: event, onShowOnMap: onShowOnMap),
  );
}

class EventDetailSheet extends ConsumerWidget {
  const EventDetailSheet({super.key, required this.event, this.onShowOnMap});

  final RadarEvent event;
  final VoidCallback? onShowOnMap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final interests = ref.watch(interestsProvider);
    final matched = event.tags.where(interests.contains).toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      maxChildSize: 0.9,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Row(children: [
            Icon(categoryIcon(event.category), size: 18, color: scheme.primary),
            const SizedBox(width: 6),
            Text(context.categoryLabel(event.category), style: text.labelLarge),
            const Spacer(),
            if (event.isSample) const SampleBadge(),
          ]),
          const SizedBox(height: 8),
          Text(context.tr(event.title), style: text.headlineSmall),
          const SizedBox(height: 12),
          _InfoRow(Icons.schedule, '${context.formatDateTime(event.start)} – ${context.formatDateTime(event.end)}'),
          _InfoRow(Icons.place_outlined, '${event.venue} · ${event.city}'),
          if (event.deadline != null) _InfoRow(Icons.timer_outlined, '⏰ ${context.formatDate(event.deadline!)}'),
          const SizedBox(height: 12),
          Text(context.tr(event.description), style: text.bodyLarge),
          if (matched.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              color: scheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  Icon(Icons.auto_awesome, color: scheme.onPrimaryContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${l10n.whyForYou}: ${l10n.matchesInterests(matched.map((t) => '#$t').join(' '))}',
                      style: TextStyle(color: scheme.onPrimaryContainer),
                    ),
                  ),
                ]),
              ),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: event.registerUrl == null
                ? null
                : () => launchUrl(Uri.parse(event.registerUrl!), mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.how_to_reg),
            label: Text(event.registerUrl == null ? l10n.noRegisterLink : l10n.register),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            // TODO(D7): Google Calendar events.insert
            onPressed: () => ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('${l10n.addToCalendar}: ${l10n.comingSoon}'))),
            icon: const Icon(Icons.event_available),
            label: Text(l10n.addToCalendar),
          ),
          if (onShowOnMap != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onShowOnMap!();
              },
              icon: const Icon(Icons.map_outlined),
              label: Text(l10n.showOnMap),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ]),
      );
}
