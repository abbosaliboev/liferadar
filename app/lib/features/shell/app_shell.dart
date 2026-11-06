import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n_ext.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

/// Pastki navigatsiya qobig'i (5 tab).
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell, required this.body});

  final StatefulNavigationShell shell;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    NavigationDestination d(IconData icon, IconData selected, String label) => NavigationDestination(
          icon: Icon(icon),
          selectedIcon: Icon(selected),
          label: label,
        );
    return Scaffold(
      body: body,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: p.border))),
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
          destinations: [
            d(Icons.radar_outlined, Icons.radar, l10n.tabHome),
            d(Icons.map_outlined, Icons.map_rounded, l10n.tabMap),
            d(Icons.event_note_outlined, Icons.event_note_rounded, l10n.tabPlans),
            d(Icons.explore_outlined, Icons.explore_rounded, l10n.tabDiscover),
            d(Icons.person_outline_rounded, Icons.person_rounded, l10n.tabProfile),
          ],
        ),
      ),
    );
  }
}

/// Tab'lar orasida yumshoq fade. Har bir tab holatini saqlaydi (Offstage + TickerMode).
class FadeBranchContainer extends StatelessWidget {
  const FadeBranchContainer({super.key, required this.currentIndex, required this.children});

  final int currentIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        for (var i = 0; i < children.length; i++)
          _Branch(active: i == currentIndex, child: children[i]),
      ]);
}

class _Branch extends StatefulWidget {
  const _Branch({required this.active, required this.child});
  final bool active;
  final Widget child;

  @override
  State<_Branch> createState() => _BranchState();
}

class _BranchState extends State<_Branch> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: Motion.normal, value: widget.active ? 1 : 0);

  @override
  void didUpdateWidget(_Branch old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      _c.duration = Motion.of(context, Motion.normal);
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Offstage(
        offstage: !widget.active,
        child: TickerMode(
          enabled: widget.active,
          child: FadeTransition(opacity: CurvedAnimation(parent: _c, curve: Motion.curve), child: widget.child),
        ),
      );
}

/// Namuna ma'lumot ekanini halol ko'rsatadigan kichik belgi.
class SampleBadge extends StatelessWidget {
  const SampleBadge({super.key});

  @override
  Widget build(BuildContext context) => Pill(context.l10n.sampleData, tone: Tone.neutral, dense: true);
}
