import 'package:flutter/material.dart';

import '../models/app_page.dart';
import '../theme/app_colors.dart';

/// The app's left navigation rail - a narrow icon-only column (logo, main
/// pages, a settings section, and a bottom avatar/theme toggle), matching
/// the reference layout's slim sidebar shape instead of a wide labeled list.
class Sidebar extends StatelessWidget {
  const Sidebar({
    super.key,
    required this.selectedPage,
    required this.onSelectPage,
  });

  final AppPage selectedPage;
  final ValueChanged<AppPage> onSelectPage;

  static const _mainPages = [
    AppPage.dashboard,
    AppPage.dashboard2,
    AppPage.dash1,
    AppPage.pitch,
    AppPage.players,
    AppPage.records,
    AppPage.menuPlayer,
    AppPage.help,
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.panelDark,
      child: SizedBox(
        width: 76,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sports_soccer,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 16),
                Container(width: 28, height: 1, color: Colors.white24),
                const SizedBox(height: 20),
                for (final page in _mainPages)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RailIcon(
                      icon: page.icon,
                      tooltip: page.label,
                      selected: page == selectedPage,
                      onTap: () => onSelectPage(page),
                    ),
                  ),
                const Spacer(),
                Container(width: 28, height: 1, color: Colors.white24),
                const SizedBox(height: 16),
                _RailIcon(
                  icon: AppPage.settings.icon,
                  tooltip: AppPage.settings.label,
                  selected: selectedPage == AppPage.settings,
                  onTap: () => onSelectPage(AppPage.settings),
                ),
                const SizedBox(height: 20),
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white12,
                  child: Icon(
                    Icons.light_mode,
                    color: Colors.white70,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RailIcon extends StatelessWidget {
  const _RailIcon({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.amber.withValues(alpha: 0.18) : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: selected ? Colors.amber : Colors.white54,
            size: 22,
          ),
        ),
      ),
    );
  }
}
