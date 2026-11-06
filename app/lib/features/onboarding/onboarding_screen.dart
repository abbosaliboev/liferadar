import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n_ext.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';

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
    final p = context.palette;
    final t = context.textStyles;

    return Scaffold(
      appBar: AppBar(
        title: widget.editing ? Text(l10n.interestsEdit) : null,
        automaticallyImplyLeading: widget.editing,
      ),
      // Tugma doim ko'rinsin (kichik ekranlarda ham).
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(color: p.background, border: Border(top: BorderSide(color: p.border))),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Space.gutter, Space.md, Space.gutter, Space.md),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _selected.isEmpty || _saving ? null : _save,
                  child: Text(_selected.isEmpty
                      ? l10n.onboardingPickOne
                      : widget.editing
                          ? l10n.save
                          : l10n.onboardingContinue(_selected.length)),
                ),
              ),
              if (!widget.editing) ...[
                const SizedBox(height: Space.sm),
                Text(l10n.onboardingPrivacy, textAlign: TextAlign.center, style: t.bodySmall),
              ],
            ]),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(Space.gutter, Space.sm, Space.gutter, Space.xxl),
            children: [
              Text(l10n.onboardingTitle, style: t.headlineSmall),
              const SizedBox(height: Space.sm),
              Text(l10n.onboardingSubtitle, style: t.bodyMedium!.copyWith(color: p.textMuted)),
              const SizedBox(height: Space.xxl),
              LayoutBuilder(builder: (context, c) {
                final w = (c.maxWidth - Space.md) / 2;
                return Wrap(spacing: Space.md, runSpacing: Space.md, children: [
                  for (final o in interestOptions)
                    SizedBox(
                      width: w,
                      child: _InterestTile(
                        icon: o.icon,
                        label: context.tr(o.label),
                        selected: _selected.contains(o.tag),
                        onTap: () => setState(
                          () => _selected.contains(o.tag) ? _selected.remove(o.tag) : _selected.add(o.tag),
                        ),
                      ),
                    ),
                ]);
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _InterestTile extends StatelessWidget {
  const _InterestTile({required this.icon, required this.label, required this.selected, required this.onTap});
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final d = Motion.of(context, Motion.fast);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.lg),
          child: AnimatedContainer(
            duration: d,
            curve: Motion.curve,
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: Space.md),
            decoration: BoxDecoration(
              color: selected ? p.primarySoft : p.surface,
              borderRadius: BorderRadius.circular(Radii.lg),
              border: Border.all(color: selected ? p.primary : p.border, width: selected ? 1.5 : 1),
            ),
            child: Row(children: [
              Icon(icon, size: 22, color: selected ? p.primary : p.textMuted),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.titleSmall!.copyWith(color: selected ? p.primary : p.text),
                ),
              ),
              AnimatedScale(
                duration: d,
                scale: selected ? 1 : 0,
                child: Icon(Icons.check_circle_rounded, size: 20, color: p.primary),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
