import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/drawing.dart';
import '../models/player.dart';
import '../state/tactics_controller.dart';
import 'pitch_screen_dialogs.dart';
import '../widgets/ball_piece.dart';
import '../widgets/pitch_canvas.dart';
import '../widgets/pitch_left_rail.dart';
import '../widgets/pitch_message_label.dart';
import '../widgets/pitch_player_token.dart';
import '../widgets/pitch_right_rail.dart';
import '../widgets/pitch_side_panel.dart';
import '../widgets/records_panel.dart';
import '../widgets/pitch_top_bar.dart';
import '../widgets/player_piece.dart';
import '../widgets/tactics_toolbar.dart';
import '../widgets/toast_banner.dart';
import '../widgets/formation_panel.dart';
import '../theme/app_colors.dart';

/// Which right-side sub-panel the left rail currently has open.
enum _SidePanel { none, formation, tools, actions, records }

class PitchScreen extends StatefulWidget {
  const PitchScreen({
    super.key,
    required this.controller,
    required this.onBack,
  });

  final TacticsController controller;
  final VoidCallback onBack;

  @override
  State<PitchScreen> createState() => _PitchScreenState();
}

class _PitchScreenState extends State<PitchScreen> {
  late final TacticsController _controller;
  final _pitchAreaKey = GlobalKey();
  final _benchAreaKey = GlobalKey();
  bool _showBench = false;

  /// How far the ball-path playback panel has been dragged from its default
  /// docked spot (accumulated pointer delta) - applied as a translation so
  /// the panel's ancestor shape never changes and its widget never gets
  /// reparented, which is what previously triggered a GlobalKey assertion.
  Offset _ballControlsOffset = Offset.zero;

  /// Which sub-panel the left rail's "Diziliş"/"Taktikler" buttons currently
  /// show docked on the right (mutually exclusive - only one at a time).
  _SidePanel _activeSidePanel = _SidePanel.none;

  /// When true, the open side panel shrinks to the same width as the left
  /// rail and shows icon-only buttons instead of full labeled ones.
  bool _sidePanelCollapsed = false;

  /// Current feedback message shown in the small bottom-left toast, or null
  /// when none is showing.
  String? _toastMessage;
  Timer? _toastTimer;

  // Rubber-band (drag-to-select) state, in pitch-local coordinates.
  Offset? _selectionStart;
  Offset? _selectionCurrent;

  // Group-drag state: last pointer position while moving a multi-selection.
  Offset? _groupDragLast;

  final _keyboardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey == _controller.fullscreenShortcutKey) {
      _controller.toggleImmersive();
      return;
    }
    final isCommandKey =
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    if (isCommandKey && event.logicalKey == LogicalKeyboardKey.keyZ) {
      if (HardwareKeyboard.instance.isShiftPressed) {
        _controller.redo();
      } else {
        _controller.undo();
      }
      return;
    }
    if (isCommandKey && event.logicalKey == LogicalKeyboardKey.keyY) {
      _controller.redo();
      return;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (_controller.activeTool == DrawingTool.ballPath) {
        _finishBallPath();
      } else if (_controller.activeTool == DrawingTool.zone) {
        _finishZone();
      } else if (_controller.activeTool == DrawingTool.playerRun) {
        _finishPlayerRun();
      } else {
        _controller.cancelArrowDraft();
      }
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_controller.activeTool == DrawingTool.ballPath) {
        _finishBallPath();
      } else if (_controller.activeTool == DrawingTool.zone) {
        _finishZone();
      } else if (_controller.activeTool == DrawingTool.playerRun) {
        _finishPlayerRun();
      }
    }
  }

  /// Escape/Enter finish the in-progress area scan; below 3 points there's
  /// no valid polygon yet, so warn instead of silently discarding it.
  void _finishZone() {
    if (_controller.zonePoints.length < 3) {
      _showMessage('Alan oluşturmak için en az 3 nokta gerekiyor.');
      _controller.commitZone();
      return;
    }
    _controller.commitZone();
    _showMessage('Alan tarama tamamlandı.');
  }

  /// Escape/Enter finish the in-progress player run; below 2 points there's
  /// no path yet, so warn instead of silently discarding it.
  void _finishPlayerRun() {
    if (_controller.playerRunPoints.length < 2) {
      _showMessage('Koşu çizmek için en az 2 nokta gerekiyor.');
      _controller.cancelPlayerRunDraft();
      return;
    }
    _controller.commitPlayerRun();
    _showMessage('Oyuncu koşusu kaydedildi.');
  }

  Future<void> _handleExportJson() =>
      showExportJsonDialog(context, _controller, _showMessage);

  Future<void> _handleImportJson() =>
      showImportJsonDialog(context, _controller, _showMessage);

  Future<void> _handleImportRecords() =>
      importRecordsFromFolder(_controller, _showMessage);

  Future<void> _handleArrowFinished(int shapeIndex) =>
      showArrowFinishedDialog(context, _controller, shapeIndex);

  Future<void> _finishBallPath() async {
    if (_controller.pathPoints.length < 2) {
      _showMessage('Yolu tamamlamak için en az 2 nokta gerekiyor.');
      _controller.commitBallPath();
      return;
    }
    final pointCount = _controller.pathPoints.length;
    _controller.commitBallPath();
    _showMessage('Top yolu tamamlandı.');
    final shapeIndex = _controller.drawings.length - 1;
    await showBallPathWaypointMessagesDialog(
      context,
      _controller,
      shapeIndex,
      pointCount,
    );
  }

  Color _colorForPlayer(Player player) =>
      player.team == 'home' ? _controller.homeColor : _controller.awayColor;

  bool _within(Offset local, Size size) =>
      local.dx >= 0 &&
      local.dy >= 0 &&
      local.dx <= size.width &&
      local.dy <= size.height;

  void _handlePlayerDragEnd(Player player, DraggableDetails details) {
    final pitchBox =
        _pitchAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (pitchBox != null) {
      final local = pitchBox.globalToLocal(details.offset);
      if (_within(local, pitchBox.size)) {
        _controller.dropPlayerOnPitch(
          player,
          local,
          pitchBox.size,
          PlayerPiece.size,
        );
        return;
      }
    }
    final benchBox =
        _benchAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (benchBox != null) {
      final local = benchBox.globalToLocal(details.offset);
      if (_within(local, benchBox.size)) {
        _controller.benchPlayer(player);
      }
    }
  }

  Offset _playerCenter(Player player, double maxX, double maxY) {
    final left = maxX > 0 ? player.x * maxX : 0.0;
    final top = maxY > 0 ? player.y * maxY : 0.0;
    return Offset(left + PlayerPiece.size / 2, top + PlayerPiece.size / 2);
  }

  Player? _playerNear(Offset local, double maxX, double maxY) {
    const hitRadius = 34.0;
    for (final player in _controller.pitchPlayers) {
      if ((local - _playerCenter(player, maxX, maxY)).distance <= hitRadius) {
        return player;
      }
    }
    return null;
  }

  void _handleSelectionPointerDown(
    PointerDownEvent event,
    double maxX,
    double maxY,
    Offset ballCenter,
  ) {
    // Let the active drawing tool own this gesture instead of starting a
    // rubber-band selection or a group drag.
    if (_controller.activeTool != DrawingTool.none) return;
    final local = event.localPosition;
    // Don't start a rubber-band selection when the press is on the ball -
    // let its own Draggable handle that gesture instead.
    const ballHitRadius = 26.0;
    if ((local - ballCenter).distance <= ballHitRadius) return;
    final nearPlayer = _playerNear(local, maxX, maxY);
    if (nearPlayer != null) {
      final selection = _controller.selectedPlayerIds;
      if (selection.length > 1 && selection.contains(nearPlayer.id)) {
        // Dragging a member of a multi-selection moves the whole group;
        // otherwise let that piece's own Draggable handle it as usual.
        setState(() => _groupDragLast = local);
      }
      return;
    }
    setState(() {
      _selectionStart = local;
      _selectionCurrent = local;
    });
  }

  void _handleSelectionPointerMove(
    PointerMoveEvent event,
    double maxX,
    double maxY,
  ) {
    if (_groupDragLast != null) {
      final delta = event.localPosition - _groupDragLast!;
      _controller.moveSelectedPlayersBy(delta, maxX, maxY);
      _groupDragLast = event.localPosition;
      return;
    }
    if (_selectionStart == null) return;
    setState(() => _selectionCurrent = event.localPosition);
  }

  void _handleSelectionPointerUp(
    PointerUpEvent event,
    double maxX,
    double maxY,
  ) {
    if (_groupDragLast != null) {
      setState(() => _groupDragLast = null);
      return;
    }
    final start = _selectionStart;
    final current = _selectionCurrent;
    setState(() {
      _selectionStart = null;
      _selectionCurrent = null;
    });
    if (start == null || current == null) return;
    final rect = Rect.fromPoints(start, current);
    final ids = <String>{
      for (final player in _controller.pitchPlayers)
        if (rect.contains(_playerCenter(player, maxX, maxY))) player.id,
    };
    _controller.setMultiSelection(ids);
  }

  void _handleBallDragEnd(DraggableDetails details) {
    final pitchBox =
        _pitchAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (pitchBox == null) return;
    final local = pitchBox.globalToLocal(details.offset);
    if (!_within(local, pitchBox.size)) return;
    // Once a ball path exists the ball is "on rails" - dragging it snaps to
    // the nearest point on the path instead of dropping it anywhere, and
    // carries any player assigned a run on that segment along with it.
    if (_controller.hasBallPath) {
      final size = pitchBox.size;
      final maxX = size.width - BallPiece.size;
      final maxY = size.height - BallPiece.size;
      final fx = maxX > 0
          ? (local.dx - BallPiece.size / 2).clamp(0, maxX) / maxX
          : 0.0;
      final fy = maxY > 0
          ? (local.dy - BallPiece.size / 2).clamp(0, maxY) / maxY
          : 0.0;
      _controller.snapBallToPathNear(Offset(fx, fy));
      return;
    }
    _controller.dropBall(local, pitchBox.size, BallPiece.size);
  }

  /// Shows feedback in a small bottom-left toast instead of a SnackBar.
  void _showMessage(String message) {
    _toastTimer?.cancel();
    setState(() => _toastMessage = message);
    _toastTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _toastMessage = null);
    });
  }

  Future<void> _showSearchDialog() =>
      showBenchSearchDialog(context, _controller);

  Future<void> _showRenamePlayerDialog(Player player) =>
      showRenamePlayerDialog(context, _controller, player.id, player.name);

  /// "Yeni Kayıt" in the Kayıtlar panel: prompts for a name and saves the
  /// current live board as a new, separately named entry.
  Future<void> _handleSaveRecordAsNew() =>
      showSaveRecordAsNewDialog(context, _controller, _showMessage);

  /// The Kayıtlar panel's per-record rename (pencil) action.
  Future<void> _handleRenameRecord(String id, String currentName) =>
      showRenameRecordDialog(context, _controller, id, currentName);

  /// Lets the user save the currently drawn shapes (or just the selected
  /// ones) as a reusable, named template independent of any single Tactic,
  /// and browse/apply/delete previously saved templates.
  Future<void> _showDrawingTemplatesDialog() =>
      showDrawingTemplatesDialog(context, _controller, _showMessage);

  Future<void> _showSettingsDialog() =>
      showFormationSettingsDialog(context, _controller);

  void _showHelpScreen() => pushHelpScreen(context, _controller);

  void _handleDelete() {
    if (_controller.activeTool == DrawingTool.playerRun) {
      _controller.deleteCurrentPlayerRun();
      _showMessage('Oyuncu koşusu silindi.');
      return;
    }
    if (_controller.selectedDrawingIndices.isNotEmpty) {
      _controller.deleteSelectedDrawing();
      return;
    }
    final ids = _controller.selectedPlayerIds;
    if (ids.isEmpty) {
      _showMessage('Önce bir oyuncu seçin.');
      return;
    }
    for (final player
        in _controller.players.where((p) => ids.contains(p.id)).toList()) {
      _controller.benchPlayer(player);
    }
    _controller.setMultiSelection({});
  }

  void _handleCaptain() {
    final ids = _controller.selectedPlayerIds;
    if (ids.isEmpty) {
      _showMessage('Kaptan yapmak için önce bir oyuncu seçin.');
      return;
    }
    if (ids.length > 1) {
      _showMessage('Kaptan yapmak için tek bir oyuncu seçin.');
      return;
    }
    _controller.toggleCaptain(ids.first);
  }

  void _handleCard() {
    final ids = _controller.selectedPlayerIds;
    if (ids.isEmpty) {
      _showMessage('Kart vermek için önce bir oyuncu seçin.');
      return;
    }
    if (ids.length > 1) {
      _showMessage('Kart vermek için tek bir oyuncu seçin.');
      return;
    }
    _controller.cycleCard(ids.first);
  }

  /// Taktikler's only job is opening/closing the toolbar - it never cancels
  /// whatever tool is active, and nothing else (picking a tool, etc.)
  /// closes the toolbar; only pressing this button again does.
  void _handleToggleTacticsPanel() {
    setState(() {
      _activeSidePanel = _activeSidePanel == _SidePanel.tools
          ? _SidePanel.none
          : _SidePanel.tools;
    });
  }

  /// Diziliş mirrors Taktikler's toggle behavior for the formation picker;
  /// the two share the same right-side slot, so opening one closes the
  /// other.
  void _handleToggleFormationPanel() {
    setState(() {
      _activeSidePanel = _activeSidePanel == _SidePanel.formation
          ? _SidePanel.none
          : _SidePanel.formation;
    });
  }

  /// Araçlar shares the same right-side slot and toggle behavior as
  /// Diziliş/Taktikler - it used to be its own always-visible rail.
  void _handleToggleActionsPanel() {
    setState(() {
      _activeSidePanel = _activeSidePanel == _SidePanel.actions
          ? _SidePanel.none
          : _SidePanel.actions;
    });
  }

  /// Kayıtlar shares the same right-side slot/toggle behavior as the other
  /// side panels - lists every saved tactic/plan.
  void _handleToggleRecordsPanel() {
    setState(() {
      _activeSidePanel = _activeSidePanel == _SidePanel.records
          ? _SidePanel.none
          : _SidePanel.records;
    });
  }

  /// Accumulates the drag delta so the ball-path playback panel can be
  /// dragged anywhere over the pitch. Applied as a `Transform.translate` on
  /// top of the panel's always-docked layout position (see build()) rather
  /// than by re-parenting it into a differently-shaped `Positioned` -
  /// re-parenting a `GlobalKey`-holding widget between differently shaped
  /// ancestors is what previously tripped a framework assertion.
  void _dragBallControls(DragUpdateDetails details, Size area) {
    setState(() {
      _ballControlsOffset = Offset(
        (_ballControlsOffset.dx + details.delta.dx).clamp(
          -area.width,
          area.width,
        ),
        (_ballControlsOffset.dy + details.delta.dy).clamp(
          -area.height,
          area.height,
        ),
      );
    });
  }

  /// A second click on the already-active tool's own button in the
  /// toolbar finishes its current draft - the mouse equivalent of pressing
  /// Escape/Enter for that tool. The tool itself stays active afterward so
  /// drawing can continue back-to-back.
  void _handleFinishActiveTacticTool() {
    switch (_controller.activeTool) {
      case DrawingTool.arrow:
        _controller.cancelArrowDraft();
        break;
      case DrawingTool.ballPath:
        _finishBallPath();
        break;
      case DrawingTool.zone:
        _finishZone();
        break;
      case DrawingTool.playerRun:
        _finishPlayerRun();
        break;
      default:
        break;
    }
  }

  /// A tap during any drawing tool that lands on a player (instead of empty
  /// pitch space) selects that player and finishes whatever draft is in
  /// progress, rather than placing a new point at their position. Arrow is
  /// exempt: its own tap flow already commits using the exact tap position
  /// regardless of what's underneath, so it only gains the selection.
  void _handlePlayerTappedWhileDrawing(String playerId) {
    _controller.selectPlayer(playerId);
    switch (_controller.activeTool) {
      case DrawingTool.ballPath:
        if (_controller.pathPoints.isNotEmpty) _finishBallPath();
        break;
      case DrawingTool.zone:
        if (_controller.zonePoints.isNotEmpty) _finishZone();
        break;
      case DrawingTool.playerRun:
        if (_controller.playerRunPoints.isNotEmpty) _finishPlayerRun();
        break;
      default:
        break;
    }
  }

  /// Validates and activates a tool chosen from the tactics toolbar. The
  /// toolbar stays open afterward - only the Taktikler button closes it.
  Future<void> _handleSelectTacticTool(DrawingTool choice) async {
    if (choice == DrawingTool.playerRun) {
      if (_controller.resolvedBallPathIndex == null) {
        _showMessage('Önce bir Top Yolu çizmelisiniz.');
        return;
      }
      if (_controller.selectedSegmentIndex == null) {
        _showMessage('Önce durak çizgisinden bir segment seçin.');
        return;
      }
      if (_controller.selectedPlayerIds.length != 1) {
        _showMessage('Koşu atamak için tek bir oyuncu seçin.');
        return;
      }
      _controller.beginPlayerRun();
      return;
    }
    if (choice == DrawingTool.ballPath) {
      if (_controller.hasBallPath) {
        final continueOld = await _askContinueBallPath();
        if (continueOld == null) return;
        if (continueOld) {
          _controller.continueLastBallPath();
        } else {
          _controller.setTool(DrawingTool.ballPath);
        }
        return;
      }
      _controller.setTool(DrawingTool.ballPath);
      return;
    }
    final needsPlayer = choice == DrawingTool.arrow;
    if (needsPlayer && _controller.selectedPlayerIds.isEmpty) {
      _showMessage('Çizim yapmak için önce bir oyuncu seçin.');
      return;
    }
    _controller.setTool(choice);
  }

  Future<bool?> _askContinueBallPath() => askContinueBallPathDialog(context);

  /// Arrow-tip messages are always visible, anchored to the arrow's end.
  /// Ball-path waypoint messages appear once the animated ball has reached
  /// them and stay fixed at that waypoint's own position.
  List<Widget> _buildMessageLabels(TacticsController controller, Size area) {
    final labels = <Widget>[];

    for (final shape in controller.drawings) {
      if (shape.tool != DrawingTool.arrow) continue;
      if (shape.waypointMessages.length < 2) continue;
      final message = shape.waypointMessages[1];
      if (message == null || message.isEmpty) continue;
      final end = shape.points.last;
      labels.add(
        Positioned(
          left: end.dx * area.width + 12,
          top: end.dy * area.height - 14,
          child: PitchMessageLabel(message: message),
        ),
      );
    }

    final animatingIndex = controller.animatingPathIndex;
    if (animatingIndex != null && animatingIndex < controller.drawings.length) {
      final shape = controller.drawings[animatingIndex];
      if (shape.tool == DrawingTool.ballPath) {
        for (final pointIndex in controller.revealedWaypoints) {
          if (pointIndex >= shape.points.length) continue;
          final message = pointIndex < shape.waypointMessages.length
              ? shape.waypointMessages[pointIndex]
              : null;
          if (message == null || message.isEmpty) continue;
          final point = shape.points[pointIndex];
          labels.add(
            Positioned(
              left: point.dx * area.width + 12,
              top: point.dy * area.height - 28,
              child: PitchMessageLabel(message: message),
            ),
          );
        }
      }
    }

    return labels;
  }

  /// Selects the tapped player; if a segment is already targeted on the
  /// waypoint track bar, this immediately starts drawing that player's run
  /// for it instead of requiring a trip back through Taktikler each time.
  void _handlePlayerTapOnPitch(Player player) {
    _controller.selectPlayer(player.id);
    if (_controller.selectedPlayerIds.length == 1 &&
        _controller.selectedPlayerIds.contains(player.id) &&
        _controller.selectedSegmentIndex != null &&
        _controller.resolvedBallPathIndex != null) {
      _controller.beginPlayerRun();
    }
  }

  /// Tapping a bench player while exactly one pitch player is selected
  /// substitutes them (bench player takes the pitch player's spot); with
  /// no such selection, it's a plain select like tapping any other player.
  void _handleBenchPlayerTap(String benchPlayerId) {
    final selected = _controller.selectedPlayerIds;
    if (selected.length == 1) {
      final selectedId = selected.first;
      final selectedPlayer = _controller.players.firstWhere(
        (p) => p.id == selectedId,
      );
      if (selectedPlayer.onPitch) {
        _controller.substitutePlayer(selectedId, benchPlayerId);
        _showMessage('Oyuncu değişikliği yapıldı.');
        return;
      }
    }
    _controller.selectPlayer(benchPlayerId);
  }

  Widget _buildPlayerToken(Player player, double maxX, double maxY) {
    // Members of a multi-selection are moved together via the pitch's
    // group-drag pointer tracking instead of their own individual Draggable.
    final isGroupSelected =
        _controller.selectedPlayerIds.length > 1 &&
        _controller.selectedPlayerIds.contains(player.id);
    return PitchPlayerToken(
      player: player,
      maxX: maxX,
      maxY: maxY,
      color: _colorForPlayer(player),
      overSquadLimit: _controller.isOverSquadLimit(player),
      isSelected: _controller.selectedPlayerIds.contains(player.id),
      isGroupSelected: isGroupSelected,
      jerseyImagePath: _controller.jerseyImage,
      onTap: () => _handlePlayerTapOnPitch(player),
      onDoubleTap: () => _showRenamePlayerDialog(player),
      onDragEnd: (details) => _handlePlayerDragEnd(player, details),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pitchBackground,
      body: KeyboardListener(
        focusNode: _keyboardFocusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final controller = _controller;
            return Stack(
              children: [
                Column(
                  children: [
                    if (!controller.isImmersive)
                      PitchTopBar(
                        onBack: widget.onBack,
                        onNewPlan: () => controller.createTactic(
                          'Yeni Plan ${controller.tactics.length + 1}',
                        ),
                      ),
                    Expanded(
                      child: Row(
                        children: [
                          if (!controller.isImmersive)
                            PitchLeftRail(
                              showBench: _showBench,
                              onToggleBench: () =>
                                  setState(() => _showBench = !_showBench),
                              onSettingsTap: _showSettingsDialog,
                              onNotesTap: () =>
                                  _showMessage('Notlar özelliği yakında.'),
                              onHelpTap: _showHelpScreen,
                              formationActive:
                                  _activeSidePanel == _SidePanel.formation,
                              onToggleFormation: _handleToggleFormationPanel,
                              tacticsActive:
                                  _activeSidePanel == _SidePanel.tools ||
                                  controller.activeTool == DrawingTool.arrow ||
                                  controller.activeTool ==
                                      DrawingTool.ballPath ||
                                  controller.activeTool == DrawingTool.zone ||
                                  controller.activeTool ==
                                      DrawingTool.playerRun,
                              onToggleTactics: _handleToggleTacticsPanel,
                              actionsActive:
                                  _activeSidePanel == _SidePanel.actions,
                              onToggleActions: _handleToggleActionsPanel,
                              recordsActive:
                                  _activeSidePanel == _SidePanel.records,
                              onToggleRecords: _handleToggleRecordsPanel,
                            ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: PitchCanvas(
                                controller: controller,
                                pitchAreaKey: _pitchAreaKey,
                                benchAreaKey: _benchAreaKey,
                                showBench: _showBench,
                                selectionStart: _selectionStart,
                                selectionCurrent: _selectionCurrent,
                                ballControlsOffset: _ballControlsOffset,
                                onSelectionPointerDown:
                                    _handleSelectionPointerDown,
                                onSelectionPointerMove:
                                    _handleSelectionPointerMove,
                                onSelectionPointerUp: _handleSelectionPointerUp,
                                onBallDragEnd: _handleBallDragEnd,
                                buildPlayerToken: _buildPlayerToken,
                                buildMessageLabels: _buildMessageLabels,
                                onArrowFinished: _handleArrowFinished,
                                onPlayerTappedWhileDrawing:
                                    _handlePlayerTappedWhileDrawing,
                                onDragBallControls: _dragBallControls,
                                onShowMessage: _showMessage,
                                onBenchSelectPlayer: _handleBenchPlayerTap,
                                onBenchDragEnd: _handlePlayerDragEnd,
                                colorForPlayer: _colorForPlayer,
                                onDoubleTapPlayer: _showRenamePlayerDialog,
                              ),
                            ),
                          ),
                          if (!controller.isImmersive &&
                              _activeSidePanel != _SidePanel.none)
                            PitchSidePanel(
                              collapsed: _sidePanelCollapsed,
                              onToggleCollapsed: () => setState(
                                () =>
                                    _sidePanelCollapsed = !_sidePanelCollapsed,
                              ),
                              child: switch (_activeSidePanel) {
                                _SidePanel.formation => FormationPanel(
                                  current: controller.homeFormation,
                                  onSelect: (type) =>
                                      controller.applyFormation('home', type),
                                  compact: _sidePanelCollapsed,
                                ),
                                _SidePanel.actions => PitchRightRail(
                                  onMove: () =>
                                      controller.setTool(DrawingTool.none),
                                  onDelete: _handleDelete,
                                  onCaptain: _handleCaptain,
                                  onCard: _handleCard,
                                  onAddNote: () => _showMessage(
                                    'Not ekleme özelliği yakında.',
                                  ),
                                  onSearchPlayer: _showSearchDialog,
                                  onTemplates: _showDrawingTemplatesDialog,
                                  onHeatmap: () =>
                                      controller.setTool(DrawingTool.heatmap),
                                  heatmapActive:
                                      controller.activeTool ==
                                      DrawingTool.heatmap,
                                  onSave: () => saveTacticToJsonFile(
                                    controller,
                                    _showMessage,
                                  ),
                                  onShare: () => _showMessage(
                                    'Paylaşım özelliği yakında.',
                                  ),
                                  canUndo: controller.canUndo,
                                  canRedo: controller.canRedo,
                                  onUndo: controller.undo,
                                  onRedo: controller.redo,
                                  onExportJson: _handleExportJson,
                                  onImportJson: _handleImportJson,
                                  onImportRecords: _handleImportRecords,
                                  onToggleFullscreen:
                                      controller.toggleImmersive,
                                  compact: _sidePanelCollapsed,
                                ),
                                _SidePanel.records => RecordsPanel(
                                  controller: controller,
                                  onSaveAsNew: _handleSaveRecordAsNew,
                                  onRename: _handleRenameRecord,
                                  compact: _sidePanelCollapsed,
                                ),
                                _SidePanel.tools ||
                                _SidePanel.none => TacticsToolbar(
                                  activeTool: controller.activeTool,
                                  onSelect: _handleSelectTacticTool,
                                  onFinishActive: _handleFinishActiveTacticTool,
                                  hidePlayerRuns: controller.hidePlayerRuns,
                                  onToggleHidePlayerRuns:
                                      controller.toggleHidePlayerRuns,
                                  dimBallPath: controller.dimBallPath,
                                  onToggleDimBallPath:
                                      controller.toggleDimBallPath,
                                  hasBallPathSelected:
                                      controller.resolvedBallPathIndex != null,
                                  hasSegmentSelected:
                                      controller.selectedSegmentIndex != null,
                                  hasSinglePlayerSelected:
                                      controller.selectedPlayerIds.length == 1,
                                  compact: _sidePanelCollapsed,
                                ),
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (controller.isImmersive)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: FloatingActionButton.small(
                      heroTag: 'exit-fullscreen',
                      onPressed: controller.toggleImmersive,
                      tooltip: 'Tam ekrandan çık',
                      child: const Icon(Icons.fullscreen_exit),
                    ),
                  ),
                if (_toastMessage != null)
                  Positioned(
                    left: 16,
                    bottom: 16,
                    child: ToastBanner(message: _toastMessage!),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
