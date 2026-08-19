import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Chrome for the docked right-side panel (Diziliş/Taktikler/Araçlar/
/// Kayıtlar) - the collapse toggle and scrollable frame. The actual panel
/// content (which sub-panel to show) is decided by the caller and passed in
/// as [child], so this widget stays agnostic of which one is active.
class PitchSidePanel extends StatelessWidget {
  const PitchSidePanel({
    super.key,
    required this.collapsed,
    required this.onToggleCollapsed,
    required this.child,
  });

  final bool collapsed;
  final VoidCallback onToggleCollapsed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('pitch-side-panel'),
      width: collapsed ? 96 : 210,
      color: AppColors.panelDark,
      padding: EdgeInsets.fromLTRB(
        collapsed ? 4 : 12,
        0,
        collapsed ? 4 : 12,
        12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: collapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.more_horiz, color: Colors.white70),
                tooltip: collapsed ? 'Paneli genişlet' : 'Paneli daralt',
                onPressed: onToggleCollapsed,
              ),
            ],
          ),
          Expanded(child: SingleChildScrollView(child: child)),
        ],
      ),
    );
  }
}
