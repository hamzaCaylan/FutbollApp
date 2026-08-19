import 'package:flutter/material.dart';

enum AppPage { dashboard, dashboard2, dash1, pitch, players, settings, help }

extension AppPageExtension on AppPage {
  String get label {
    switch (this) {
      case AppPage.dashboard:
        return 'Dashboard';
      case AppPage.dashboard2:
        return 'Dashboard 2';
      case AppPage.dash1:
        return 'Dash 1';
      case AppPage.pitch:
        return 'Tactics';
      case AppPage.players:
        return 'Players';
      case AppPage.settings:
        return 'Settings';
      case AppPage.help:
        return 'Kılavuz';
    }
  }

  IconData get icon {
    switch (this) {
      case AppPage.dashboard:
        return Icons.dashboard_customize;
      case AppPage.dashboard2:
        return Icons.stadium;
      case AppPage.dash1:
        return Icons.badge_outlined;
      case AppPage.pitch:
        return Icons.sports_soccer;
      case AppPage.players:
        return Icons.group;
      case AppPage.settings:
        return Icons.settings;
      case AppPage.help:
        return Icons.menu_book_outlined;
    }
  }
}
