import 'package:flutter/material.dart';

import '../models/drawing.dart';
import '../models/player.dart';
import '../state/tactics_controller.dart';
import 'ball_path_controls.dart';
import 'ball_piece.dart';
import 'bench.dart';
import 'drawing_color_picker.dart';
import 'drawing_layer.dart';
import 'football_pitch.dart';
import 'pitch_image_overlay.dart';
import 'player_piece.dart';
import 'waypoint_track_bar.dart';

/// The pitch surface itself: grass background, drawings, players, ball,
/// rubber-band selection box, the floating bench/ball-path/color-picker/
/// waypoint overlays. Everything here is sized against the box it's laid
/// out in, so it's wrapped in its own [LayoutBuilder].
class PitchCanvas extends StatelessWidget {
  const PitchCanvas({
    super.key,
    required this.controller,
    required this.pitchAreaKey,
    required this.benchAreaKey,
    required this.showBench,
    required this.selectionStart,
    required this.selectionCurrent,
    required this.ballControlsOffset,
    required this.onSelectionPointerDown,
    required this.onSelectionPointerMove,
    required this.onSelectionPointerUp,
    required this.onBallDragEnd,
    required this.buildPlayerToken,
    required this.buildMessageLabels,
    required this.onArrowFinished,
    required this.onPlayerTappedWhileDrawing,
    required this.onDragBallControls,
    required this.onShowMessage,
    required this.onBenchSelectPlayer,
    required this.onBenchDragEnd,
    required this.colorForPlayer,
    required this.onDoubleTapPlayer,
  });

  final TacticsController controller;
  final GlobalKey pitchAreaKey;
  final GlobalKey benchAreaKey;
  final bool showBench;
  final Offset? selectionStart;
  final Offset? selectionCurrent;
  final Offset ballControlsOffset;

  final void Function(
    PointerDownEvent event,
    double maxX,
    double maxY,
    Offset ballCenter,
  )
  onSelectionPointerDown;
  final void Function(PointerMoveEvent event, double maxX, double maxY)
  onSelectionPointerMove;
  final void Function(PointerUpEvent event, double maxX, double maxY)
  onSelectionPointerUp;
  final void Function(DraggableDetails details) onBallDragEnd;
  final Widget Function(Player player, double maxX, double maxY)
  buildPlayerToken;
  final List<Widget> Function(TacticsController controller, Size area)
  buildMessageLabels;
  final void Function(int shapeIndex) onArrowFinished;
  final void Function(String playerId) onPlayerTappedWhileDrawing;
  final void Function(DragUpdateDetails details, Size area) onDragBallControls;
  final void Function(String message) onShowMessage;
  final void Function(String benchPlayerId) onBenchSelectPlayer;
  final void Function(Player player, DraggableDetails details) onBenchDragEnd;
  final Color Function(Player player) colorForPlayer;
  final void Function(Player player) onDoubleTapPlayer;

  /// Whether the floating color/thickness picker applies to [tool]: every
  /// drawing tool that paints with `shape.color` directly. Excluded:
  /// [DrawingTool.none]/[DrawingTool.select] (not drawing), [playerRun]
  /// (colored by the player's own team automatically), and [heatmap]
  /// (always its own fixed red-to-yellow heat palette, not user-pickable).
  bool _toolHasColorPicker(DrawingTool tool) {
    switch (tool) {
      case DrawingTool.none:
      case DrawingTool.select:
      case DrawingTool.playerRun:
      case DrawingTool.heatmap:
        return false;
      case DrawingTool.arrow:
      case DrawingTool.line:
      case DrawingTool.freehand:
      case DrawingTool.rectangle:
      case DrawingTool.circle:
      case DrawingTool.highlight:
      case DrawingTool.ballPath:
      case DrawingTool.zone:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // The pitch always fills the whole available box edge-to-edge; the
        // bench floats on top of it and never affects this size.
        final area = Size(constraints.maxWidth, constraints.maxHeight);

        final maxX = area.width - PlayerPiece.size;
        final maxY = area.height - PlayerPiece.size;
        final ballMaxX = area.width - BallPiece.size;
        final ballMaxY = area.height - BallPiece.size;
        final ballCenter = Offset(
          (ballMaxX > 0 ? controller.ball.x * ballMaxX : 0) +
              BallPiece.size / 2,
          (ballMaxY > 0 ? controller.ball.y * ballMaxY : 0) +
              BallPiece.size / 2,
        );

        // A function (not a precomputed value) so it can be re-evaluated on
        // every animationTick, reading the ball's current position instead
        // of a stale one captured at the last full rebuild.
        Widget buildBallToken() => Positioned(
          left: ballMaxX > 0 ? controller.ball.x * ballMaxX : 0,
          top: ballMaxY > 0 ? controller.ball.y * ballMaxY : 0,
          child: Draggable<String>(
            data: 'ball',
            dragAnchorStrategy: pointerDragAnchorStrategy,
            feedback: BallPiece.centeredFeedback(
              child: Opacity(
                opacity: 0.85,
                child: BallPiece(onTap: () {}, imagePath: controller.ballImage),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: BallPiece(onTap: () {}, imagePath: controller.ballImage),
            ),
            onDragEnd: onBallDragEnd,
            child: BallPiece(
              onTap: controller.toggleBallLayer,
              imagePath: controller.ballImage,
            ),
          ),
        );

        return Stack(
          children: [
            SizedBox(
              width: area.width,
              height: area.height,
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (event) =>
                    onSelectionPointerDown(event, maxX, maxY, ballCenter),
                onPointerMove: (event) =>
                    onSelectionPointerMove(event, maxX, maxY),
                onPointerUp: (event) => onSelectionPointerUp(event, maxX, maxY),
                // Scoped to just the pitch canvas: rebuilds on every
                // animationTick (ball/run animation, group drag) without
                // forcing the rest of the screen's chrome to rebuild too.
                child: ListenableBuilder(
                  listenable: controller.animationTick,
                  builder: (context, _) => Stack(
                    key: pitchAreaKey,
                    children: [
                      FootballPitch(imagePath: controller.pitchImage),
                      // Sits between the pitch and the players/ball - so
                      // arrows/zones/heat trails read as marks on the pitch
                      // surface instead of a layer floating over the squad.
                      DrawingLayer(
                        controller: controller,
                        area: area,
                        playerColors: {
                          for (final p in controller.players)
                            p.id: colorForPlayer(p),
                        },
                        onArrowFinished: onArrowFinished,
                        onPlayerTappedWhileDrawing: onPlayerTappedWhileDrawing,
                      ),
                      if (!controller.ball.inFront) buildBallToken(),
                      for (final player in controller.pitchPlayers)
                        buildPlayerToken(player, maxX, maxY),
                      if (controller.ball.inFront) buildBallToken(),
                      ...buildMessageLabels(controller, area),
                      if (selectionStart != null && selectionCurrent != null)
                        Positioned.fromRect(
                          rect: Rect.fromPoints(
                            selectionStart!,
                            selectionCurrent!,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.15),
                              border: Border.all(
                                color: Colors.amber,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(
                child: PitchImageOverlay(
                  imageUrl: controller.adBannerImageUrl,
                  width: 220,
                  height: 40,
                  placeholderLabel: 'Reklam Alanı',
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Center(
                child: PitchImageOverlay(
                  imageUrl: controller.adBannerImageUrl,
                  width: 220,
                  height: 40,
                  placeholderLabel: 'Reklam Alanı',
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: PitchImageOverlay(
                imageUrl: controller.channelIconImageUrl,
                width: 56,
                height: 56,
                placeholderLabel: 'Kanal',
                borderRadius: 28,
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: PitchImageOverlay(
                imageUrl: controller.cameraFrameImageUrl,
                width: 96,
                height: 72,
                placeholderLabel: 'Kamera',
              ),
            ),
            if (showBench)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Bench(
                  key: benchAreaKey,
                  controller: controller,
                  homePlayers: controller.benchPlayers('home'),
                  awayPlayers: controller.benchPlayers('away'),
                  selectedPlayerIds: controller.selectedPlayerIds,
                  onSelectPlayer: onBenchSelectPlayer,
                  onDragEnd: onBenchDragEnd,
                  colorForPlayer: colorForPlayer,
                  onDoubleTapPlayer: onDoubleTapPlayer,
                  jerseyImagePath: controller.jerseyImage,
                ),
              ),
            if (controller.hasBallPath)
              Positioned.fill(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Transform.translate(
                      offset: ballControlsOffset,
                      child: BallPathControls(
                        isPlaying: controller.isAnimatingBallPath,
                        isPaused: controller.isBallPathPaused,
                        speed: controller.ballPathSpeed,
                        onPlay: () {
                          if (!controller.playBallPath()) {
                            onShowMessage('Oynatılacak bir top yolu yok.');
                          }
                        },
                        onPause: controller.pauseBallPath,
                        onRewind: controller.rewindBallPath,
                        onRestart: controller.restartBallPath,
                        onSpeedChanged: controller.setBallPathSpeed,
                        onDragPanelUpdate: (details) =>
                            onDragBallControls(details, area),
                      ),
                    ),
                  ),
                ),
              ),
            if (_toolHasColorPicker(controller.activeTool) ||
                controller.activeTool == DrawingTool.heatmap)
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: DrawingColorPicker(
                    selectedColor: controller.drawingColor,
                    onColorChanged: controller.setDrawingColor,
                    selectedThickness: controller.drawingThickness,
                    onThicknessChanged: controller.setDrawingThickness,
                    showColorSwatches:
                        controller.activeTool != DrawingTool.heatmap,
                  ),
                ),
              ),
            if (controller.resolvedBallPathSegmentCount != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 8,
                child: Center(
                  child: WaypointTrackBar(
                    segmentCount: controller.resolvedBallPathSegmentCount!,
                    selectedSegment: controller.selectedSegmentIndex,
                    onSegmentSelected: controller.selectSegment,
                    currentBallDurak: controller.currentBallDurakIndex,
                    selectedDurak: controller.selectedDurakIndex,
                    onDurakSelected: controller.selectDurak,
                    onScrub: controller.scrubBallPathTo,
                    maxWidth: area.width - 24,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
