import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n_ext.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/calendar_controller.dart';
import '../../data/providers.dart';
import '../../data/session.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final p = context.palette;
    final t = context.textStyles;
    final session = ref.watch(sessionProvider);
    final interests = ref.watch(interestsProvider);
    final cal = ref.watch(calendarProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final guest = session == null || session.isGuest;

    Future<void> signOut() async {
      await ref.read(sessionProvider.notifier).signOut();
      if (context.mounted) context.go('/login');
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabProfile)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: Space.xxxl),
        children: [
          // ── Foydalanuvchi ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(Space.lg),
                child: Row(children: [
                  AppAvatar(photoUrl: session?.photoUrl, name: guest ? null : session.name, size: 56),
                  const SizedBox(width: Space.lg),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(guest ? l10n.guestName : (session.name ?? session.email ?? ''), style: t.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        guest ? l10n.guestSubtitle : (session.email ?? ''),
                        style: t.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ]),
                  ),
                  if (guest) TextButton(onPressed: signOut, child: Text(l10n.signIn)),
                ]),
              ),
            ),
          ),

          // ── Qiziqishlar ──
          SectionHeader(
            l10n.interestsEdit,
            action: TextButton(onPressed: () => context.push('/interests'), child: Text(l10n.edit)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
            child: Wrap(spacing: Space.sm, runSpacing: Space.sm, children: [
              for (final o in interestOptions.where((o) => interests.contains(o.tag)))
                Pill(context.tr(o.label), icon: o.icon, tone: Tone.primary),
              if (interests.isEmpty) Text(l10n.onboardingPickOne, style: t.bodySmall),
            ]),
          ),

          // ── Ulangan xizmatlar ──
          SectionHeader(l10n.sectionConnections),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
            child: GroupCard(children: [
              ListTile(
                leading: const IconTile(Icons.calendar_month_outlined, size: 36),
                title: Text(l10n.sourceCalendar),
                subtitle: Text(cal.isConnected ? l10n.connected : l10n.notConnected),
                trailing: cal.isBusy
                    ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : cal.isConnected
                        ? TextButton(
                            onPressed: () => ref.read(calendarProvider.notifier).disconnect(),
                            child: Text(l10n.calendarDisconnect, style: TextStyle(color: p.danger)),
                          )
                        : TextButton(
                            onPressed: () => ref.read(calendarProvider.notifier).connect(),
                            child: Text(l10n.connect),
                          ),
              ),
            ]),
          ),

          // ── Sozlamalar ──
          SectionHeader(l10n.sectionSettings),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
            child: GroupCard(children: [
              _SettingRow(
                icon: Icons.contrast_rounded,
                label: l10n.theme,
                child: SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: ThemeMode.system, label: Text(l10n.themeSystem)),
                    ButtonSegment(value: ThemeMode.light, label: Text(l10n.themeLight)),
                    ButtonSegment(value: ThemeMode.dark, label: Text(l10n.themeDark)),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (s) => ref.read(themeModeProvider.notifier).set(s.first),
                ),
              ),
              _SettingRow(
                icon: Icons.translate_rounded,
                label: l10n.language,
                child: SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: 'system', label: Text(l10n.themeSystem)),
                    const ButtonSegment(value: 'ko', label: Text('한국어')),
                    const ButtonSegment(value: 'en', label: Text('English')),
                  ],
                  selected: {locale?.languageCode ?? 'system'},
                  onSelectionChanged: (s) =>
                      ref.read(localeProvider.notifier).set(s.first == 'system' ? null : Locale(s.first)),
                ),
              ),
            ]),
          ),

          // ── Ma'lumot ──
          SectionHeader(l10n.sectionAbout),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
            child: GroupCard(children: [
              ListTile(
                leading: const Icon(Icons.shield_outlined),
                title: Text(l10n.privacy),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(l10n.privacy),
                    content: Text('${l10n.calendarPrivacy}\n\n${l10n.onboardingPrivacy}'),
                    actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.ok))],
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: Text(l10n.version),
                trailing: Text('0.1.0 · MVP', style: t.bodySmall),
              ),
            ]),
          ),

          const SizedBox(height: Space.xxl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: p.danger),
              onPressed: signOut,
              icon: const Icon(Icons.logout_rounded),
              label: Text(guest ? l10n.exitGuest : l10n.logout),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.icon, required this.label, required this.child});
  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.lg, Space.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 20, color: context.palette.textMuted),
            const SizedBox(width: Space.md),
            Text(label, style: context.textStyles.titleSmall),
          ]),
          const SizedBox(height: Space.md),
          SizedBox(width: double.infinity, child: child),
        ]),
      );
}
