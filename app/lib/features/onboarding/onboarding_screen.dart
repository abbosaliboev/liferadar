import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n_ext.dart';
import '../../data/providers.dart';
import '../shell/app_shell.dart';

/// Qiziqishlarni tanlash. Birinchi ochilishda ([editing] = false) va
/// keyin "qiziqishlarni o'zgartirish" ([editing] = true) uchun ham ishlatiladi.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.editing = false});

  final bool editing;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final Set<String> _selected = {...ref.read(interestsProvider)};
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref.read(interestsProvider.notifier).save(_selected);
    if (!mounted) return;
    if (widget.editing && context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: widget.editing ? Text(l10n.interestsEdit) : null,
        automaticallyImplyLeading: widget.editing,
        actions: const [LanguageButton()],
      ),
      // Tugma doim ko'rinsin (kichik ekranlarda ham).
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                onPressed: _selected.isEmpty || _saving ? null : _save,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                child: Text(
                  _selected.isEmpty
                      ? l10n.onboardingPickOne
                      : widget.editing
                      ? l10n.save
                      : l10n.onboardingContinue(_selected.length),
                ),
              ),
              if (!widget.editing) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.onboardingPrivacy,
                  textAlign: TextAlign.center,
                  style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                if (!widget.editing) ...[
                  Icon(Icons.radar, size: 48, color: scheme.primary),
                  const SizedBox(height: 12),
                  Text(l10n.appTitle, style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(l10n.onboardingTagline, style: text.bodyLarge),
                  const SizedBox(height: 28),
                ],
                Text(l10n.onboardingTitle, style: text.titleLarge),
                const SizedBox(height: 4),
                Text(l10n.onboardingSubtitle, style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final o in interestOptions)
                      FilterChip(
                        avatar: Icon(o.icon, size: 18),
                        label: Text(context.tr(o.label)),
                        selected: _selected.contains(o.tag),
                        onSelected: (on) => setState(() => on ? _selected.add(o.tag) : _selected.remove(o.tag)),
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

/// AppBar'dagi "qiziqishlarni o'zgartirish" tugmasi.
class EditInterestsButton extends StatelessWidget {
  const EditInterestsButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: context.l10n.interestsEdit,
    icon: const Icon(Icons.tune),
    onPressed: () => context.push('/interests'),
  );
}
