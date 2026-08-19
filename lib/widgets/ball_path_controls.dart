import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class BallPathControls extends StatelessWidget {
  const BallPathControls({
    super.key,
    required this.isPlaying,
    required this.isPaused,
    required this.speed,
    required this.onPlay,
    required this.onPause,
    required this.onRewind,
    required this.onRestart,
    required this.onSpeedChanged,
    this.onDragPanelUpdate,
  });

  final bool isPlaying;
  final bool isPaused;
  final double speed;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onRewind;
  final VoidCallback onRestart;
  final ValueChanged<double> onSpeedChanged;

  /// When set, a drag handle appears on the left edge of the panel that lets
  /// the user press and hold to freely reposition the whole panel anywhere
  /// over the pitch.
  final GestureDragUpdateCallback? onDragPanelUpdate;

  @override
  Widget build(BuildContext context) {
    final playing = isPlaying && !isPaused;
    const iconButtonConstraints = BoxConstraints(minWidth: 32, minHeight: 32);
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.panelDark.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onDragPanelUpdate != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: onDragPanelUpdate,
              child: const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Tooltip(
                  message: 'Sürükleyerek taşı',
                  child: Icon(
                    Icons.drag_indicator,
                    color: Colors.white54,
                    size: 20,
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Baştan al',
            onPressed: onRestart,
            padding: EdgeInsets.zero,
            constraints: iconButtonConstraints,
            iconSize: 20,
            icon: const Icon(Icons.skip_previous, color: Colors.white),
          ),
          IconButton(
            tooltip: 'Geri sar',
            onPressed: onRewind,
            padding: EdgeInsets.zero,
            constraints: iconButtonConstraints,
            iconSize: 20,
            icon: const Icon(Icons.fast_rewind, color: Colors.white),
          ),
          IconButton(
            tooltip: playing ? 'Durdur' : 'Oynat',
            onPressed: playing ? onPause : onPlay,
            padding: EdgeInsets.zero,
            constraints: iconButtonConstraints,
            iconSize: 26,
            icon: Icon(
              playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.speed, color: Colors.white70, size: 18),
          SizedBox(
            width: 110,
            height: 40,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              ),
              child: Slider(
                value: speed,
                min: 0.25,
                max: 4.0,
                onChanged: onSpeedChanged,
              ),
            ),
          ),
          Text(
            '${speed.toStringAsFixed(2)}x',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
