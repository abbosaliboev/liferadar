import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n_ext.dart';
import '../../core/theme.dart';
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
    final interests = ref.watch(interestsProvider);
    final events = ref
        .watch(eventsProvider)
        .where((e) => _category == null || e.category == _category)
        .toList()
      ..sort((a, b) {
        final byScore = interestScore(b, interests).compareTo(interestScore(a, interests));
        return byScore != 0 ? byScore : a.start.compareTo(b.start);
      });
    final categories = ref.watch(eventsProvider).map((e) => e.category).toSet().toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabDiscover), actions: const [LanguageButton()]),
      body: Column(children: [
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              ChoiceChip(
                label: Text(l10n.discoverAll),
                selected: _category == null,
                onSelected: (_) => setState(() => _category = null),
              ),
              for (final c in categories) ...[
                const SizedBox(width: 6),
                ChoiceChip(
                  avatar: Icon(categoryIcon(c), size: 16),
                  label: Text(context.categoryLabel(c)),
                  selected: _category == c,
                  onSelected: (_) => setState(() => _category = c),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: events.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _EventTile(event: events[i], interests: interests),
          ),
        ),
      ]),
    );
  }
}

class _EventTile extends ConsumerWidget {
  const _EventTile({required this.event, required this.interests});

  final RadarEvent event;
  final Set<String> interests;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matched = event.tags.where(interests.contains);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: AppColors.recommended,
          foregroundColor: Colors.white,
          child: Icon(categoryIcon(event.category)),
        ),
        title: Text(context.tr(event.title)),
        subtitle: Text(
          '${context.formatDate(event.start)} · ${event.city}'
          '${matched.isEmpty ? '' : '\n${matched.map((t) => '#$t').join(' ')}'}',
        ),
        isThreeLine: matched.isNotEmpty,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => showEventDetail(context, event, onShowOnMap: () {
          ref.read(mapFocusProvider.notifier).focus(event.id);
          context.go('/map');
        }),
      ),
    );
  }
}
