import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_page.dart';
import '../state/tactics_controller.dart';
import 'dashboard_screen.dart';
import 'dashboard2_screen.dart';
import 'dash1_screen.dart';
import 'help_screen.dart';
import 'pitch_screen.dart';
import 'menu_player_screen.dart';
import 'players_screen.dart';
import 'records_screen.dart';
import 'settings_screen.dart';
import '../widgets/sidebar.dart';

/// Local-storage key the whole app's state (tactics, presets, settings) is
/// autosaved under; bump the trailing version if the JSON shape ever needs
/// a breaking change so old saves are ignored instead of crashing on load.
const _storageKey = 'fc_manager_state_v1';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppPage _currentPage = AppPage.pitch;
  TacticsController? _controller;
  Timer? _saveDebounce;

  @override
  void initState() {
    super.initState();
    _loadController();
  }

  Future<void> _loadController() async {
    final controller = TacticsController();
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_storageKey);
      if (saved != null) {
        controller.loadAppStateJson(jsonDecode(saved) as Map<String, dynamic>);
      }
    } catch (_) {
      // Corrupt or outdated save data - keep the fresh default state the
      // constructor already built instead of crashing the app on launch.
    }
    controller.addListener(_scheduleSave);
    if (!mounted) return;
    setState(() => _controller = controller);
  }

  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 800), _saveNow);
  }

  Future<void> _saveNow() async {
    final controller = _controller;
    if (controller == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(controller.toAppStateJson()));
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _controller?.removeListener(_scheduleSave);
    _controller?.dispose();
    super.dispose();
  }

  void _selectPage(AppPage page) {
    if (page == _currentPage) return;
    setState(() {
      _currentPage = page;
    });
  }

  Widget _buildPage(TacticsController controller) {
    switch (_currentPage) {
      case AppPage.pitch:
      case AppPage.dashboard:
        return DashboardScreen(
          controller: controller,
          onSelectPage: _selectPage,
        );
      case AppPage.dashboard2:
        return Dashboard2Screen(
          controller: controller,
          onSelectPage: _selectPage,
        );
      case AppPage.dash1:
        return Dash1Screen(controller: controller, onSelectPage: _selectPage);
      case AppPage.players:
        return PlayersScreen(controller: controller);
      case AppPage.records:
        return RecordsScreen(controller: controller, onSelectPage: _selectPage);
      case AppPage.menuPlayer:
        return MenuPlayerScreen(
          controller: controller,
          onSelectPage: _selectPage,
        );
      case AppPage.settings:
        return SettingsScreen(controller: controller);
      case AppPage.help:
        return HelpScreen(controller: controller);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // The pitch/lineup editor owns its own full-screen chrome (top bar and
    // side rails), so it bypasses the generic sidebar + header shell.
    if (_currentPage == AppPage.pitch) {
      return PitchScreen(
        controller: controller,
        onBack: () => _selectPage(AppPage.dashboard),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          Container(height: 1, color: Theme.of(context).dividerColor),
          Expanded(
            child: Row(
              children: [
                Sidebar(selectedPage: _currentPage, onSelectPage: _selectPage),
                Expanded(child: _buildPage(controller)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
