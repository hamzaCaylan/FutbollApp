import 'package:flutter/material.dart';

/// Right-side sub-panel shown when "Araçlar" is toggled open on the left
/// rail: board-wide actions (move/delete/captain/search/templates/heatmap)
/// that used to live in their own always-visible rail.
class PitchRightRail extends StatelessWidget {
  const PitchRightRail({
    super.key,
    required this.onMove,
    required this.onDelete,
    required this.onCaptain,
    required this.onCard,
    required this.onNationality,
    required this.onAddNote,
    required this.onSearchPlayer,
    required this.onTemplates,
    required this.onHeatmap,
    required this.heatmapActive,
    required this.onSave,
    required this.onShare,
    required this.canUndo,
    required this.canRedo,
    required this.onUndo,
    required this.onRedo,
    required this.onExportJson,
    required this.onImportJson,
    required this.onImportRecords,
    required this.onToggleFullscreen,
    this.compact = false,
  });

  final VoidCallback onMove;
  final VoidCallback onDelete;
  final VoidCallback onCaptain;

  /// Cycles the single selected player's card status
  /// none -> yellow -> red -> none.
  final VoidCallback onCard;

  /// Cycles the single selected player's nationality status
  /// local -> foreignU23 -> foreignOver23 -> local.
  final VoidCallback onNationality;
  final VoidCallback onAddNote;
  final VoidCallback onSearchPlayer;

  /// Opens the drawing-preset (template) library: save the current drawn
  /// shapes as a reusable set, or drop a previously saved one onto the
  /// board.
  final VoidCallback onTemplates;

  /// Activates the heat-map drawing tool (red-hot core fading to yellow at
  /// the edges); [heatmapActive] highlights the button while it's the
  /// active tool, matching the Taktikler panel's convention.
  final VoidCallback onHeatmap;
  final bool heatmapActive;

  /// Board-wide actions that used to live in the top bar - relocated here
  /// so the top bar could be trimmed down to just Geri/Yeni Plan.
  final VoidCallback onSave;
  final VoidCallback onShare;
  final bool canUndo;
  final bool canRedo;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onExportJson;
  final VoidCallback onImportJson;

  /// Bulk-imports every .json plan in a folder the user picks as new
  /// entries in the Kayıtlar list.
  final VoidCallback onImportRecords;
  final VoidCallback onToggleFullscreen;

  /// When true, renders as a narrow icon-only column that fits the left
  /// rail's width instead of the full labeled list.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact)
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Araçlar',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        _action(Icons.open_with, 'Taşı', onMove),
        const SizedBox(height: 6),
        _action(Icons.delete_outline, 'Sil', onDelete),
        const SizedBox(height: 6),
        _action(Icons.star_outline, 'Kaptan', onCaptain),
        const SizedBox(height: 6),
        _action(Icons.style_outlined, 'Kart Ver', onCard),
        const SizedBox(height: 6),
        _action(Icons.public, 'Uyruk', onNationality),
        const SizedBox(height: 6),
        _action(Icons.note_add_outlined, 'Not Ekle', onAddNote),
        const SizedBox(height: 6),
        _action(Icons.search, 'Oyuncu Ara', onSearchPlayer),
        const SizedBox(height: 6),
        _action(Icons.dashboard_customize_outlined, 'Şablonlar', onTemplates),
        const SizedBox(height: 6),
        _action(
          Icons.whatshot,
          'Isı Haritası',
          onHeatmap,
          active: heatmapActive,
        ),
        const Divider(color: Colors.white12, height: 20),
        _action(Icons.save_outlined, 'Kaydet', onSave),
        const SizedBox(height: 6),
        _action(Icons.ios_share, 'Paylaş', onShare),
        const SizedBox(height: 6),
        _action(Icons.undo, 'Geri Al', onUndo, enabled: canUndo),
        const SizedBox(height: 6),
        _action(Icons.redo, 'Yinele', onRedo, enabled: canRedo),
        const SizedBox(height: 6),
        _action(Icons.file_download_outlined, 'JSON Dışa Aktar', onExportJson),
        const SizedBox(height: 6),
        _action(Icons.file_upload_outlined, 'JSON İçe Aktar', onImportJson),
        const SizedBox(height: 6),
        _action(
          Icons.drive_folder_upload_outlined,
          'Kayıtları İçe Al',
          onImportRecords,
        ),
        const SizedBox(height: 6),
        _action(Icons.fullscreen, 'Tam Ekran', onToggleFullscreen),
      ],
    );
  }

  Widget _action(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool active = false,
    bool enabled = true,
  }) {
    final style = OutlinedButton.styleFrom(
      alignment: compact ? Alignment.center : Alignment.centerLeft,
      foregroundColor: active ? Colors.black : Colors.white,
      backgroundColor: active ? Colors.amber : null,
      side: BorderSide(color: active ? Colors.amber : Colors.white24),
    );
    final pressed = enabled ? onTap : null;
    if (compact) {
      return Tooltip(
        message: label,
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: pressed,
            style: style,
            child: Icon(icon, size: 18),
          ),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: pressed,
        style: style,
        icon: Icon(icon, size: 18),
        label: Text(label, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
