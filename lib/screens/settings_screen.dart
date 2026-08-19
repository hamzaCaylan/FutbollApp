import 'package:flutter/material.dart';

import '../state/tactics_controller.dart';
import '../widgets/settings_panel.dart';

/// Standalone Ayarlar page - the same [SettingsPanel] the pitch screen's
/// quick-access dialog uses, reachable without entering the pitch first.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});

  final TacticsController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: SettingsPanel(controller: controller),
    );
  }
}
