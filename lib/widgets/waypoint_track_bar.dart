import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The "Durak Çizgisi" (stop/waypoint track): renders the active ball
/// path's waypoints as `x----x------x------>` and lets the user tap the
/// connector between two consecutive stops to target that segment for a
/// player-run assignment.
class WaypointTrackBar extends StatelessWidget {
  const WaypointTrackBar({
    super.key,
    required this.segmentCount,
    required this.selectedSegment,
    required this.onSegmentSelected,
    this.currentBallDurak,
    this.selectedDurak,
    this.onDurakSelected,
    this.onScrub,
    this.maxWidth,
  });

  /// Number of segments (waypoint count - 1) in the active ball path.
  final int segmentCount;
  final int? selectedSegment;
  final ValueChanged<int> onSegmentSelected;

  /// Which Durak (0-based) the ball currently occupies during playback -
  /// highlighted independently of [selectedSegment], which marks the
  /// segment targeted for a player-run assignment instead.
  final int? currentBallDurak;

  /// Which durak is selected for tagging new arrow drawings to (see
  /// TacticsController.selectedDurakIndex) - tapping a dot toggles it.
  final int? selectedDurak;
  final ValueChanged<int>? onDurakSelected;

  /// Dragging left/right across the bar scrubs the ball (and any assigned
  /// players) to that point of the path, forward or backward - like a
  /// video seek bar. Given progress in 0..1 across the whole path.
  final ValueChanged<double>? onScrub;

  /// The widest this bar is allowed to grow (usually the pitch area's
  /// width, with some margin) - long ball paths shrink each segment's
  /// connector to fit instead of overflowing off the edge of the pitch.
  final double? maxWidth;

  static const double _dotSize = 20;
  static const double _connectorHorizontalMargin = 8;
  static const double _maxSegmentWidth = 170;
  static const double _minSegmentWidth = 16;

  double get _segmentWidth {
    final bound = maxWidth;
    if (bound == null || segmentCount <= 0) return _maxSegmentWidth;
    final waypointCount = segmentCount + 1;
    final reserved =
        waypointCount * _dotSize +
        segmentCount * _connectorHorizontalMargin +
        24; // outer padding
    final available = bound - reserved;
    return (available / segmentCount).clamp(_minSegmentWidth, _maxSegmentWidth);
  }

  @override
  Widget build(BuildContext context) {
    final waypointCount = segmentCount + 1;
    final segmentWidth = _segmentWidth;
    final track = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.panelDark.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < waypointCount; i++) ...[
            _durakDot(
              i,
              isBallHere: currentBallDurak == i,
              isSelected: selectedDurak == i,
            ),
            if (i < segmentCount) _segmentConnector(i, segmentWidth),
          ],
        ],
      ),
    );

    if (onScrub == null) return track;
    return Builder(
      builder: (trackContext) {
        void handleScrub(Offset localPosition) {
          final box = trackContext.findRenderObject() as RenderBox?;
          if (box == null || box.size.width <= 0) return;
          final progress = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
          onScrub!(progress);
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (details) =>
              handleScrub(details.localPosition),
          onHorizontalDragUpdate: (details) =>
              handleScrub(details.localPosition),
          child: track,
        );
      },
    );
  }

  Widget _durakDot(
    int index, {
    required bool isBallHere,
    required bool isSelected,
  }) {
    final number = index + 1;
    final dot = Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isBallHere ? Colors.greenAccent.shade400 : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected
              ? Colors.amber
              : (isBallHere ? Colors.white : Colors.transparent),
          width: isSelected ? 3 : 2,
        ),
      ),
      child: Text(
        '$number',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isBallHere ? Colors.black : Colors.black87,
        ),
      ),
    );
    return GestureDetector(
      onTap: onDurakSelected == null ? null : () => onDurakSelected!(index),
      child: Tooltip(
        message: isSelected
            ? 'Durak $number (seçili - yeni oklar buraya bağlanır)'
            : 'Durak $number (seçmek için tıkla)',
        child: dot,
      ),
    );
  }

  Widget _segmentConnector(int segmentIndex, double width) {
    final isSelected = selectedSegment == segmentIndex;
    return GestureDetector(
      onTap: () => onSegmentSelected(segmentIndex),
      child: Tooltip(
        message: 'Segment ${segmentIndex + 1}: oyuncu koşusu ata',
        child: Container(
          width: width,
          height: isSelected ? 6 : 4,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.amber : Colors.white54,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}
