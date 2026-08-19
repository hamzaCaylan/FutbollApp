import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/tactics_controller.dart';

/// The pitch/squad/appearance settings form, shared by the pitch screen's
/// quick-access dialog and the standalone Ayarlar screen so the two never
/// drift out of sync.
class SettingsPanel extends StatefulWidget {
  const SettingsPanel({super.key, required this.controller, this.onPicked});

  final TacticsController controller;

  /// Called after a one-tap choice (squad-size preset, pitch image) is
  /// applied. The pitch screen's dialog passes a callback that closes the
  /// dialog; the standalone Ayarlar screen leaves this null so the page
  /// stays open.
  final VoidCallback? onPicked;

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  late final TextEditingController _customSquadController;
  late final TextEditingController _adBannerUrlController;
  late final TextEditingController _channelIconUrlController;

  TacticsController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _customSquadController = TextEditingController(
      text: _controller.squadSize == 11 ? '' : _controller.squadSize.toString(),
    );
    _adBannerUrlController = TextEditingController(
      text: _controller.adBannerImageUrl ?? '',
    );
    _channelIconUrlController = TextEditingController(
      text: _controller.channelIconImageUrl ?? '',
    );
  }

  @override
  void dispose() {
    _customSquadController.dispose();
    _adBannerUrlController.dispose();
    _channelIconUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => ListView(
        shrinkWrap: true,
        children: [
          const Text('Sahada kaç oyuncu gösterilsin?'),
          const SizedBox(height: 8),
          ListTile(
            leading: Icon(
              !_controller.showBothTeams && _controller.squadSize == 11
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
            ),
            title: const Text('11 · Tek takım'),
            subtitle: const Text('Sadece kendi kadronuz sahada görünür'),
            onTap: () {
              _controller.setSquadSize(11);
              _controller.setShowBothTeams(false);
              widget.onPicked?.call();
            },
          ),
          ListTile(
            leading: Icon(
              _controller.showBothTeams && _controller.squadSize == 11
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
            ),
            title: const Text('22 · Çift takım'),
            subtitle: const Text('Her iki takım da sahada görünür'),
            onTap: () {
              _controller.setSquadSize(11);
              _controller.setShowBothTeams(true);
              widget.onPicked?.call();
            },
          ),
          ListTile(
            leading: Icon(
              _controller.squadSize != 11
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
            ),
            title: const Text('Custom · Takım başına oyuncu sayısı'),
            subtitle: Row(
              children: [
                SizedBox(
                  width: 70,
                  child: TextField(
                    controller: _customSquadController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: '1-11',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () {
                    final value = int.tryParse(_customSquadController.text);
                    if (value != null) {
                      _controller.setSquadSize(value);
                      widget.onPicked?.call();
                    }
                  },
                  child: const Text('Uygula'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Saha görseli'),
          const SizedBox(height: 8),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: TacticsController.pitchImageOptions.length,
              separatorBuilder: (context, i) => const SizedBox(width: 12),
              itemBuilder: (context, i) => _pitchImageOption(
                TacticsController.pitchImageOptions[i],
                'Saha ${i + 1}',
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Oyuncu görseli'),
          const SizedBox(height: 8),
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: TacticsController.jerseyOptions.length + 1,
              separatorBuilder: (context, i) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return _playerAvatarOption(
                    jerseyPath: null,
                    label: 'Simge',
                    preview: Icon(
                      Icons.person,
                      size: 32,
                      color: Colors.grey.shade300,
                    ),
                  );
                }
                final path = TacticsController.jerseyOptions[i - 1];
                return _playerAvatarOption(
                  jerseyPath: path,
                  label: 'Forma $i',
                  preview: ClipOval(
                    child: Image.asset(
                      path,
                      fit: BoxFit.cover,
                      width: 56,
                      height: 56,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          const Text('Top görseli'),
          const SizedBox(height: 8),
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: TacticsController.ballImageOptions.length + 1,
              separatorBuilder: (context, i) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return _ballOption(
                    ballPath: null,
                    label: 'Simge',
                    preview: Icon(
                      Icons.sports_soccer,
                      size: 32,
                      color: Colors.grey.shade300,
                    ),
                  );
                }
                final path = TacticsController.ballImageOptions[i - 1];
                return _ballOption(
                  ballPath: path,
                  label: 'Top $i',
                  preview: ClipOval(
                    child: Image.asset(
                      path,
                      fit: BoxFit.cover,
                      width: 56,
                      height: 56,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          const Text('Reklam Panosu görseli'),
          const Text(
            'Sahanın alt ve üst orta kısımlarındaki reklam alanlarında '
            'gösterilecek görselin adresi (URL).',
            style: TextStyle(fontSize: 12, color: Colors.white54),
          ),
          const SizedBox(height: 8),
          _imageUrlField(
            controller: _adBannerUrlController,
            currentUrl: _controller.adBannerImageUrl,
            onApply: (url) => _controller.setAdBannerImageUrl(url),
          ),
          const SizedBox(height: 16),
          const Text('Kanal İkonu görseli'),
          const Text(
            'Sahanın sol üst köşesindeki kanal çerçevesinde gösterilecek '
            'görselin adresi (URL).',
            style: TextStyle(fontSize: 12, color: Colors.white54),
          ),
          const SizedBox(height: 8),
          _imageUrlField(
            controller: _channelIconUrlController,
            currentUrl: _controller.channelIconImageUrl,
            onApply: (url) => _controller.setChannelIconImageUrl(url),
          ),
          const SizedBox(height: 16),
          const Text('Tam ekran kısayolu'),
          const Text(
            'ESC tam ekrandan çıkarmaz - yalnızca bu tuş veya tam ekran '
            'butonu çıkarır.',
            style: TextStyle(fontSize: 12, color: Colors.white54),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _fullscreenShortcutOption(LogicalKeyboardKey.f11, 'F11'),
              _fullscreenShortcutOption(LogicalKeyboardKey.keyF, 'F'),
              _fullscreenShortcutOption(LogicalKeyboardKey.space, 'Boşluk'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _imageUrlField({
    required TextEditingController controller,
    required String? currentUrl,
    required void Function(String? url) onApply,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'https://...',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onSubmitted: onApply,
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () => onApply(controller.text),
          child: const Text('Uygula'),
        ),
        if (currentUrl != null) ...[
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Kaldır',
            icon: const Icon(Icons.close),
            onPressed: () {
              controller.clear();
              onApply(null);
            },
          ),
        ],
      ],
    );
  }

  Widget _fullscreenShortcutOption(LogicalKeyboardKey key, String label) {
    final selected = _controller.fullscreenShortcutKey == key;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => _controller.setFullscreenShortcut(key),
    );
  }

  Widget _pitchImageOption(String path, String label) {
    final selected = _controller.pitchImage == path;
    return GestureDetector(
      onTap: () {
        _controller.setPitchImage(path);
        widget.onPicked?.call();
      },
      child: Column(
        children: [
          Container(
            width: 100,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? Colors.amber : Colors.transparent,
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(path, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _ballOption({
    required String? ballPath,
    required String label,
    required Widget preview,
  }) {
    final selected = _controller.ballImage == ballPath;
    return GestureDetector(
      onTap: () => _controller.setBallImage(ballPath),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade700,
              border: Border.all(
                color: selected ? Colors.amber : Colors.transparent,
                width: 2.5,
              ),
            ),
            alignment: Alignment.center,
            child: preview,
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _playerAvatarOption({
    required String? jerseyPath,
    required String label,
    required Widget preview,
  }) {
    final selected = _controller.jerseyImage == jerseyPath;
    return GestureDetector(
      onTap: () => _controller.setJerseyImage(jerseyPath),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade700,
              border: Border.all(
                color: selected ? Colors.amber : Colors.transparent,
                width: 2.5,
              ),
            ),
            alignment: Alignment.center,
            child: preview,
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
