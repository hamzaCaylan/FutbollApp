import 'package:flutter/material.dart';

import '../models/drawing.dart';

/// Right-side sub-panel shown when "Taktikler" is toggled open on the left
/// rail. Picking a tool here activates it (the caller validates
/// preconditions and keeps the panel open so tools can be swapped quickly).
class TacticsToolbar extends StatelessWidget {
  const TacticsToolbar({
    super.key,
    required this.activeTool,
    required this.onSelect,
    required this.onFinishActive,
    required this.hidePlayerRuns,
    required this.onToggleHidePlayerRuns,
    required this.dimBallPath,
    required this.onToggleDimBallPath,
    required this.hasBallPathSelected,
    required this.hasSegmentSelected,
    required this.hasSinglePlayerSelected,
    this.compact = false,
  });

  /// The tool currently active on the pitch, so its button can be
  /// highlighted; tapping that same button again finishes its draft
  /// instead of re-selecting it.
  final DrawingTool activeTool;
  final ValueChanged<DrawingTool> onSelect;
  final VoidCallback onFinishActive;

  /// Whether assigned players are currently hidden from ball-path playback
  /// (only the ball animates).
  final bool hidePlayerRuns;
  final VoidCallback onToggleHidePlayerRuns;

  /// Whether the ball path is currently painted at reduced opacity.
  final bool dimBallPath;
  final VoidCallback onToggleDimBallPath;

  /// The three preconditions "Oyuncu Koşusu" needs before it can start
  /// (see TacticsController.beginPlayerRun) - surfaced as a standing
  /// checklist so the user sees the whole flow instead of discovering one
  /// missing step at a time via toast after each failed tap.
  final bool hasBallPathSelected;
  final bool hasSegmentSelected;
  final bool hasSinglePlayerSelected;

  /// When true, renders as a narrow icon-only column that fits the left
  /// rail's width instead of the full labeled toolbar.
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
              'Taktikler',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        _tool(DrawingTool.arrow, Icons.north_east, 'Tekli Ok'),
        const SizedBox(height: 6),
        _tool(DrawingTool.ballPath, Icons.route, 'Top Yolu'),
        const SizedBox(height: 6),
        _tool(DrawingTool.zone, Icons.crop_free, 'Alan Tarama'),
        const SizedBox(height: 6),
        _tool(DrawingTool.playerRun, Icons.directions_run, 'Oyuncu Koşusu'),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Divider(height: 1, color: Colors.white24),
        ),
        _tool(DrawingTool.line, Icons.horizontal_rule, 'Çizgi'),
        const SizedBox(height: 6),
        _tool(DrawingTool.freehand, Icons.edit, 'Serbest Çizim'),
        const SizedBox(height: 6),
        _tool(DrawingTool.rectangle, Icons.crop_square, 'Dikdörtgen'),
        const SizedBox(height: 6),
        _tool(DrawingTool.circle, Icons.circle_outlined, 'Daire'),
        const SizedBox(height: 6),
        _tool(DrawingTool.highlight, Icons.highlight_alt, 'Vurgula'),
        const SizedBox(height: 6),
        _tool(DrawingTool.select, Icons.touch_app_outlined, 'Seç/Düzenle'),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Divider(height: 1, color: Colors.white24),
        ),
        Tooltip(
          message: hidePlayerRuns
              ? 'Oyuncu Hareketi Gizli - tekrar basınca top yolu oynatılırken '
                    'atanmış oyuncu koşu çizgileri yeniden görünür.'
              : 'Top yolu oynatılırken atanmış oyuncu koşu çizgilerini '
                    'gizler - sadece topun hareketi izlenir.',
          child: compact
              ? SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onToggleHidePlayerRuns,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: hidePlayerRuns
                          ? Colors.amber
                          : Colors.white,
                      side: BorderSide(
                        color: hidePlayerRuns ? Colors.amber : Colors.white24,
                      ),
                    ),
                    child: Icon(
                      hidePlayerRuns ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                    ),
                  ),
                )
              : SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onToggleHidePlayerRuns,
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      foregroundColor: hidePlayerRuns
                          ? Colors.amber
                          : Colors.white,
                      side: BorderSide(
                        color: hidePlayerRuns ? Colors.amber : Colors.white24,
                      ),
                    ),
                    icon: Icon(
                      hidePlayerRuns ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                    ),
                    label: Text(
                      hidePlayerRuns
                          ? 'Oyuncu Hareketi Gizli'
                          : 'Oyuncu Hareketini Gizle',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 6),
        Tooltip(
          message: dimBallPath
              ? 'Top Yolu Soluk - top yolu başta gizli, top hangi durağa '
                    'kadar ilerlediyse o kısım soluk biçimde görünür. Tekrar '
                    'basınca normale döner.'
              : 'Top yolunu soluklaştırır - yol başta tamamen gizlenir, top '
                    'oynatıldıkça geçtiği bölüm soluk biçimde ortaya çıkar.',
          child: compact
              ? SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onToggleDimBallPath,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: dimBallPath
                          ? Colors.amber
                          : Colors.white,
                      side: BorderSide(
                        color: dimBallPath ? Colors.amber : Colors.white24,
                      ),
                    ),
                    child: const Icon(Icons.opacity, size: 18),
                  ),
                )
              : SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onToggleDimBallPath,
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      foregroundColor: dimBallPath
                          ? Colors.amber
                          : Colors.white,
                      side: BorderSide(
                        color: dimBallPath ? Colors.amber : Colors.white24,
                      ),
                    ),
                    icon: const Icon(Icons.opacity, size: 18),
                    label: Text(
                      dimBallPath ? 'Top Yolu Soluk' : 'Top Yolunu Soluklaştır',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
        ),
        if (!compact) ...[
          if (_hint(activeTool) != null) ...[
            const SizedBox(height: 10),
            Text(
              _hint(activeTool)!,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ],
          if (activeTool != DrawingTool.playerRun) ...[
            const SizedBox(height: 10),
            Text(
              'Oyuncu Koşusu:',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 4),
            _step('Top Yolu', hasBallPathSelected),
            const SizedBox(height: 4),
            _step('Durak', hasSegmentSelected),
            const SizedBox(height: 4),
            _step('Oyuncu', hasSinglePlayerSelected),
          ],
        ],
      ],
    );
  }

  String? _hint(DrawingTool tool) {
    switch (tool) {
      case DrawingTool.arrow:
        return 'İpucu: Var olan bir okun orta noktasını sürükleyerek eğri hale getirebilirsiniz.';
      case DrawingTool.ballPath:
        return 'İpucu: Bir durağın orta noktasını sürükleyerek segmenti eğriltebilir, durağa tıklayarak topu oraya taşıyabilirsiniz.';
      case DrawingTool.zone:
        return 'İpucu: Bir köşe noktasını sürükleyerek alanın şeklini değiştirebilirsiniz.';
      case DrawingTool.select:
        return 'İpucu: Bir şekle tıklayarak seçin (Shift ile çoklu seçim), sürükleyerek taşıyın.';
      case DrawingTool.playerRun:
        return 'Koşuyu çizmek için sahaya tıklayın, bitirince Enter\'a basın.';
      default:
        return null;
    }
  }

  Widget _step(String label, bool done) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          done ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 12,
          color: done ? Colors.greenAccent : Colors.grey.shade600,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: done ? Colors.grey.shade300 : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _tool(DrawingTool tool, IconData icon, String label) {
    final isActive = tool == activeTool;
    final onPressed = isActive ? onFinishActive : () => onSelect(tool);
    final style = OutlinedButton.styleFrom(
      alignment: compact ? Alignment.center : Alignment.centerLeft,
      foregroundColor: isActive ? Colors.black : Colors.white,
      backgroundColor: isActive ? Colors.amber : null,
      side: BorderSide(color: isActive ? Colors.amber : Colors.white24),
    );
    final message = '$label\n${_description(tool)}';
    if (compact) {
      return Tooltip(
        message: message,
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onPressed,
            style: style,
            child: Icon(icon, size: 18),
          ),
        ),
      );
    }
    return Tooltip(
      message: message,
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          style: style,
          icon: Icon(icon, size: 18),
          label: Text(label, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }

  /// A short explanation of what each tool does, shown in the hover
  /// tooltip alongside its name so the user can learn a button's function
  /// without having to select it first.
  String _description(DrawingTool tool) {
    switch (tool) {
      case DrawingTool.arrow:
        return 'Seçili oyuncudan başlayan tek bir ok çizer. Var olan bir '
            'okun orta noktasını sürükleyerek eğri hale getirebilirsiniz.';
      case DrawingTool.ballPath:
        return 'Topun izleyeceği yolu, noktalara tıklayarak çizer. Var '
            'olan bir yol varsa ona devam edip etmeyeceğiniz sorulur.';
      case DrawingTool.zone:
        return 'Sahada bir alanı taramak için köşe noktalarına tıklayın '
            '(en az 3 nokta gerekir).';
      case DrawingTool.playerRun:
        return 'Bir top yolu durağı ve tek bir oyuncu seçtikten sonra o '
            'oyuncunun koşusunu çizer.';
      case DrawingTool.line:
        return 'İki nokta arasına düz bir çizgi çizer.';
      case DrawingTool.freehand:
        return 'Sürükleyerek serbest bir çizim yapar.';
      case DrawingTool.rectangle:
        return 'Sahada bir dikdörtgen alan işaretler.';
      case DrawingTool.circle:
        return 'Sahada bir daire çizer.';
      case DrawingTool.highlight:
        return 'Sahanın bir bölgesini vurgular.';
      case DrawingTool.select:
        return 'Bir şekle tıklayarak seçin (Shift ile çoklu seçim), '
            'sürükleyerek taşıyın veya silin.';
      case DrawingTool.none:
      case DrawingTool.heatmap:
        return '';
    }
  }
}
