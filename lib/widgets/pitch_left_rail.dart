import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class PitchLeftRail extends StatelessWidget {
  const PitchLeftRail({
    super.key,
    required this.showBench,
    required this.onToggleBench,
    required this.onSettingsTap,
    required this.formationActive,
    required this.onToggleFormation,
    required this.tacticsActive,
    required this.onToggleTactics,
    required this.actionsActive,
    required this.onToggleActions,
    required this.recordsActive,
    required this.onToggleRecords,
    required this.onNotesTap,
    required this.onHelpTap,
  });

  final bool showBench;
  final VoidCallback onToggleBench;
  final VoidCallback onSettingsTap;
  final bool formationActive;
  final VoidCallback onToggleFormation;
  final bool tacticsActive;
  final VoidCallback onToggleTactics;
  final bool actionsActive;
  final VoidCallback onToggleActions;
  final bool recordsActive;
  final VoidCallback onToggleRecords;

  /// Notlar has no feature behind it yet, so it's styled as "coming soon"
  /// (dimmed, no active state) instead of looking like a working button
  /// that silently does nothing.
  final VoidCallback onNotesTap;
  final VoidCallback onHelpTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      color: AppColors.panelDark,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          _RailItem(
            icon: Icons.grid_view_rounded,
            label: 'Diziliş',
            active: formationActive,
            onTap: onToggleFormation,
          ),
          _RailItem(
            icon: Icons.person_outline,
            label: 'Oyuncular',
            active: showBench,
            onTap: onToggleBench,
          ),
          _RailItem(
            icon: Icons.hub_outlined,
            label: 'Taktikler',
            active: tacticsActive,
            onTap: onToggleTactics,
          ),
          _RailItem(
            icon: Icons.folder_outlined,
            label: 'Kayıtlar',
            active: recordsActive,
            onTap: onToggleRecords,
          ),
          _RailItem(
            icon: Icons.description_outlined,
            label: 'Notlar',
            enabled: false,
            onTap: onNotesTap,
          ),
          _RailItem(
            icon: Icons.build_outlined,
            label: 'Araçlar',
            active: actionsActive,
            onTap: onToggleActions,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Divider(height: 1, color: Colors.white12),
          ),
          _RailItem(
            icon: Icons.settings_outlined,
            label: 'Ayarlar',
            onTap: onSettingsTap,
          ),
          _RailItem(
            icon: Icons.menu_book_outlined,
            label: 'Kılavuz',
            onTap: onHelpTap,
          ),
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.enabled = true,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;

  /// False dims the button and drops its active-highlight capability, for
  /// features that don't exist yet - so it visually reads as "coming soon"
  /// instead of looking identical to a fully working button.
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = !enabled
        ? Colors.grey.shade700
        : active
        ? Colors.white
        : Colors.grey.shade400;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap ?? () {},
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: enabled && active ? Colors.red.shade600 : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: enabled && active
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
