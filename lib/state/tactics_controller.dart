import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../models/ball.dart';
import '../models/drawing.dart';
import '../models/formation.dart';
import '../models/player.dart';
import '../models/player_run.dart';
import '../models/tactic.dart';
import '../theme/app_colors.dart';

const List<String> _homeNames = [
  'Ali',
  'Can',
  'Mehmet',
  'Deniz',
  'Emre',
  'Burak',
  'Kaan',
  'Serkan',
  'Onur',
  'Cem',
  'Baris',
  'Tolga',
  'Yusuf',
  'Kerem',
  'Utku',
  'Arda',
];

const List<String> _awayNames = [
  'Selim',
  'Fatih',
  'Murat',
  'Erhan',
  'Tarik',
  'Bora',
  'Umut',
  'Volkan',
  'Ege',
  'Devrim',
  'Sinan',
  'Ozan',
  'Alper',
  'Rasit',
  'Ferhat',
  'Metin',
];

/// Single source of truth for the tactics board: rosters, the ball,
/// drawings, formations and the saved tactic snapshots. UI widgets read
/// from it and call its methods; it notifies listeners on every change.
class TacticsController extends ChangeNotifier {
  TacticsController() {
    players = _buildRoster();
    tactics.add(
      Tactic(
        id: 'default',
        name: 'Maç Planım',
        players: players.map((p) => p.copy()).toList(),
        ball: ball.copy(),
        drawings: const [],
        homeFormation: homeFormation,
        awayFormation: awayFormation,
      ),
    );
    currentTacticId = 'default';
    drawingPresets.addAll(_buildExampleDrawingPresets());
  }

  @override
  void dispose() {
    _stopBallPathTicker();
    animationTick.dispose();
    super.dispose();
  }

  /// Fires on every high-frequency position update - ball-path animation
  /// ticks (~60/sec during playback) and per-pointer-move group drags -
  /// instead of the main [notifyListeners]. The pitch canvas (ball, player
  /// tokens, drawings) listens to this separately from the rest of the
  /// screen, so a moving ball/player repaints just that area each frame
  /// instead of rebuilding the whole screen's chrome (top bar, rails,
  /// bench, toolbars), which was causing visible stutter.
  final ChangeNotifier animationTick = ChangeNotifier();

  // --- Roster & selection -------------------------------------------------

  List<Player> players = [];
  Set<String> selectedPlayerIds = {};
  String benchQuery = '';
  String selectedTeam = 'home';

  /// When false, only the home team is shown (pitch and bench); when true,
  /// both squads are shown. Toggled from the Ayarlar dialog. Defaults to
  /// false so a fresh plan starts at 11 players (one team), matching
  /// squadSize's own default instead of showing 22 (both teams).
  bool showBothTeams = false;

  /// How many starters per team are considered "on the pitch" (1-11).
  /// 11 is a full squad; smaller values suit 5-a-side/7-a-side style plans.
  int squadSize = 11;

  /// The pitch backgrounds offered in the Ayarlar dialog's "Saha görseli"
  /// picker.
  static const List<String> pitchImageOptions = [
    'assets/saha/saha.jpg',
    'assets/saha/Saha2.png',
    'assets/saha/saha3.png',
    'assets/saha/saha4.png',
    'assets/saha/saha5.png',
  ];

  /// Which pitch background photo to render. Chosen from the Ayarlar dialog.
  String pitchImage = 'assets/saha/Saha2.png';

  void setPitchImage(String path) {
    pitchImage = path;
    notifyListeners();
  }

  /// The jerseys offered in the Ayarlar dialog's "Oyuncu görseli" picker.
  static const List<String> jerseyOptions = [
    'assets/forma/forma0.png',
    'assets/forma/forma1.png',
    'assets/forma/forma2.png',
    'assets/forma/forma3.png',
    'assets/forma/forma4.png',
    'assets/forma/forma5.png',
    'assets/forma/forma6.png',
    'assets/forma/forma7.png',
    'assets/forma/forma8.png',
  ];

  /// When non-null, player pieces render this jersey artwork instead of the
  /// plain number-in-circle look. Chosen from the Ayarlar dialog.
  String? jerseyImage = 'assets/forma/forma0.png';

  void setJerseyImage(String? path) {
    jerseyImage = path;
    notifyListeners();
  }

  /// The balls offered in the Ayarlar dialog's "Top görseli" picker.
  static const List<String> ballImageOptions = [
    'assets/forma/ball.png',
    'assets/forma/ball1.png',
    'assets/forma/ball2.png',
    'assets/forma/ball3.png',
    'assets/forma/ball4.png',
  ];

  /// When non-null, the ball piece renders this artwork instead of the
  /// plain sports_soccer icon. Chosen from the Ayarlar dialog.
  String? ballImage;

  void setBallImage(String? path) {
    ballImage = path;
    notifyListeners();
  }

  /// The ad-banner image shown in the two placeholder containers over the
  /// pitch (top-center/bottom-center). A plain image URL rather than a
  /// bundled asset - chosen from the Ayarlar dialog since it's meant to be
  /// swapped per-sponsor rather than picked from a fixed set.
  String? adBannerImageUrl;

  void setAdBannerImageUrl(String? url) {
    adBannerImageUrl = (url == null || url.trim().isEmpty) ? null : url.trim();
    notifyListeners();
  }

  /// The broadcaster's channel logo shown in the top-left frame over the
  /// pitch. Also a plain image URL, chosen from the Ayarlar dialog.
  String? channelIconImageUrl;

  void setChannelIconImageUrl(String? url) {
    channelIconImageUrl = (url == null || url.trim().isEmpty)
        ? null
        : url.trim();
    notifyListeners();
  }

  // --- Fullscreen (immersive) mode ---------------------------------------

  /// True while the top bar and side rails are hidden and the pitch fills
  /// the whole screen. Only [toggleImmersive] (wired to the fullscreen
  /// button and to [fullscreenShortcutKey]) flips this - Escape never
  /// touches it, so a user mid-fullscreen can't exit it by accident while
  /// cancelling a drawing.
  bool isImmersive = false;

  /// The single key that toggles fullscreen, in addition to the on-screen
  /// button. Configurable from Ayarlar; deliberately never [LogicalKeyboardKey.escape].
  LogicalKeyboardKey fullscreenShortcutKey = LogicalKeyboardKey.f11;

  void toggleImmersive() {
    isImmersive = !isImmersive;
    notifyListeners();
  }

  void setFullscreenShortcut(LogicalKeyboardKey key) {
    fullscreenShortcutKey = key;
    notifyListeners();
  }

  List<Player> get pitchPlayers => players
      .where((p) => p.onPitch && (showBothTeams || p.team == 'home'))
      .toList();

  /// True once [player]'s team has more than [squadSize] players on the
  /// pitch and [player] is one of the extras (by roster order, so which
  /// player is flagged self-corrects as the lineup changes) - e.g. a bench
  /// player dragged on manually past the configured squad size. Used to
  /// ring that player in a translucent red warning circle instead of
  /// silently letting the pitch exceed the chosen squad size.
  bool isOverSquadLimit(Player player) {
    if (!player.onPitch) return false;
    final teamOnPitch = players
        .where((p) => p.team == player.team && p.onPitch)
        .toList();
    if (teamOnPitch.length <= squadSize) return false;
    return teamOnPitch.indexOf(player) >= squadSize;
  }

  List<Player> benchPlayers(String team) {
    if (!showBothTeams && team != 'home') return const [];
    return players
        .where((p) => p.team == team && !p.onPitch)
        .where((p) => p.name.toLowerCase().contains(benchQuery.toLowerCase()))
        .toList();
  }

  void setShowBothTeams(bool value) {
    showBothTeams = value;
    // Re-lay-out immediately so the pitch switches between the full-pitch
    // (single team) and half-pitch (both teams) formations right away.
    applyFormation('home', homeFormation);
    applyFormation('away', awayFormation);
  }

  void setSquadSize(int size) {
    squadSize = size.clamp(1, 11);
    _applySquadSizeToTeam('home');
    _applySquadSizeToTeam('away');
    // Reflow the (now smaller/larger) squads into the active formation's
    // shape instead of leaving players at their previous coordinates.
    applyFormation('home', homeFormation);
    applyFormation('away', awayFormation);
  }

  void _applySquadSizeToTeam(String team) {
    final teamPlayers = players.where((p) => p.team == team).toList();
    final onPitchNow = teamPlayers.where((p) => p.onPitch).toList();
    if (onPitchNow.length > squadSize) {
      for (final p in onPitchNow.skip(squadSize)) {
        p.onPitch = false;
      }
    } else if (onPitchNow.length < squadSize) {
      final benched = teamPlayers.where((p) => !p.onPitch).toList();
      final need = squadSize - onPitchNow.length;
      for (final p in benched.take(need)) {
        p.onPitch = true;
      }
    }
  }

  void selectPlayer(String id) {
    if (selectedPlayerIds.length == 1 && selectedPlayerIds.contains(id)) {
      selectedPlayerIds = {};
    } else {
      selectedPlayerIds = {id};
    }
    notifyListeners();
  }

  /// Replaces the selection wholesale, used by rubber-band (drag-to-select)
  /// selection on the pitch.
  void setMultiSelection(Set<String> ids) {
    selectedPlayerIds = ids;
    notifyListeners();
  }

  /// Shifts every selected, unlocked player by the same pixel delta, used to
  /// drag a whole multi-selection across the pitch as one group.
  void moveSelectedPlayersBy(Offset pixelDelta, double maxX, double maxY) {
    if (maxX <= 0 || maxY <= 0 || selectedPlayerIds.isEmpty) return;
    final dxFraction = pixelDelta.dx / maxX;
    final dyFraction = pixelDelta.dy / maxY;
    for (final player in players.where(
      (p) => selectedPlayerIds.contains(p.id) && !p.locked,
    )) {
      player.x = (player.x + dxFraction).clamp(0.0, 1.0);
      player.y = (player.y + dyFraction).clamp(0.0, 1.0);
    }
    animationTick.notifyListeners();
  }

  void setSelectedTeam(String team) {
    selectedTeam = team;
    notifyListeners();
  }

  void setBenchQuery(String query) {
    benchQuery = query;
    notifyListeners();
  }

  void dropPlayerOnPitch(
    Player player,
    Offset local,
    Size pitchSize,
    double pieceSize,
  ) {
    if (player.locked) return;
    final maxX = pitchSize.width - pieceSize;
    final maxY = pitchSize.height - pieceSize;
    player.onPitch = true;
    if (maxX > 0) {
      player.x = (local.dx - pieceSize / 2).clamp(0, maxX) / maxX;
    }
    if (maxY > 0) {
      player.y = (local.dy - pieceSize / 2).clamp(0, maxY) / maxY;
    }
    notifyListeners();
  }

  void benchPlayer(Player player) {
    if (player.locked) return;
    player.onPitch = false;
    notifyListeners();
  }

  /// Swaps [pitchPlayerId] for [benchPlayerId]: the bench player takes the
  /// pitch player's exact spot (position label and x/y) and comes on, the
  /// pitch player goes off. Both are marked [Player.substituted] so their
  /// avatars pick up the swap badge.
  void substitutePlayer(String pitchPlayerId, String benchPlayerId) {
    final pitchPlayer = players.firstWhere((p) => p.id == pitchPlayerId);
    final benchPlayer = players.firstWhere((p) => p.id == benchPlayerId);
    if (pitchPlayer.locked || !pitchPlayer.onPitch || benchPlayer.onPitch) {
      return;
    }
    benchPlayer.x = pitchPlayer.x;
    benchPlayer.y = pitchPlayer.y;
    benchPlayer.position = pitchPlayer.position;
    benchPlayer.onPitch = true;
    benchPlayer.substituted = true;
    pitchPlayer.onPitch = false;
    pitchPlayer.substituted = true;
    selectedPlayerIds = {};
    notifyListeners();
  }

  void toggleLock(String id) {
    players.firstWhere((p) => p.id == id).locked = !players
        .firstWhere((p) => p.id == id)
        .locked;
    notifyListeners();
  }

  void toggleCaptain(String id) {
    final player = players.firstWhere((p) => p.id == id);
    final makingCaptain = !player.isCaptain;
    if (makingCaptain) {
      for (final p in players.where((p) => p.team == player.team)) {
        p.isCaptain = false;
      }
    }
    player.isCaptain = makingCaptain;
    notifyListeners();
  }

  /// Cycles [id]'s card status none -> yellow -> yellow2 (second yellow,
  /// i.e. an implied red) -> red -> none, shown as a small card icon at the
  /// top-left of their jersey.
  void cycleCard(String id) {
    final player = players.firstWhere((p) => p.id == id);
    player.card = switch (player.card) {
      'yellow' => 'yellow2',
      'yellow2' => 'red',
      'red' => 'none',
      _ => 'yellow',
    };
    notifyListeners();
  }

  void renamePlayer(String id, String name) {
    if (name.trim().isEmpty) return;
    players.firstWhere((p) => p.id == id).name = name.trim();
    notifyListeners();
  }

  void setPlayerNumber(String id, int number) {
    players.firstWhere((p) => p.id == id).number = number;
    notifyListeners();
  }

  void setPlayerPosition(String id, String position) {
    if (position.trim().isEmpty) return;
    players.firstWhere((p) => p.id == id).position = position.trim();
    notifyListeners();
  }

  /// Adds a new substitute to [team]'s bench, from the Oyuncular screen
  /// rather than the pitch, so a squad can be built out without dragging
  /// placeholder tokens around first.
  void addPlayer(String team) {
    final teamPlayers = players.where((p) => p.team == team).toList();
    final nextNumber = teamPlayers.isEmpty
        ? 1
        : teamPlayers.map((p) => p.number).reduce(math.max) + 1;
    players.add(
      Player(
        id: '$team-${DateTime.now().microsecondsSinceEpoch}',
        name: 'Yeni Oyuncu',
        number: nextNumber,
        team: team,
        position: 'SUB',
        x: 0.5,
        y: 0.5,
        onPitch: false,
      ),
    );
    notifyListeners();
  }

  void removePlayer(String id) {
    players.removeWhere((p) => p.id == id);
    selectedPlayerIds.remove(id);
    notifyListeners();
  }

  // --- Formations -----------------------------------------------------

  FormationType homeFormation = FormationType.f433;
  FormationType awayFormation = FormationType.f433;
  bool sidesSwapped = false;

  void applyFormation(String team, FormationType type) {
    final starters = players.where((p) => p.team == team && p.onPitch).toList();
    final slots = type.slots;
    final inLeftHalf = (team == 'home') != sidesSwapped;
    // With only one team on the pitch there's no opponent to share the
    // length with, so stretch the formation across the full pitch instead
    // of confining it to a single half.
    final useFullPitch = !showBothTeams && team == 'home';
    for (var i = 0; i < starters.length && i < slots.length; i++) {
      final slot = slots[i];
      starters[i].position = slot.label;
      if (useFullPitch) {
        // Shift left so the goalkeeper sits close to their own goal line
        // instead of drifting toward the middle of the pitch.
        final fullX = (slot.x * 2 - 0.08).clamp(0.0, 1.0);
        starters[i].x = sidesSwapped ? 1 - fullX : fullX;
      } else {
        starters[i].x = inLeftHalf ? slot.x : 1 - slot.x;
      }
      starters[i].y = slot.y;
    }
    if (team == 'home') {
      homeFormation = type;
    } else {
      awayFormation = type;
    }
    notifyListeners();
  }

  void resetPositions() {
    applyFormation('home', homeFormation);
    applyFormation('away', awayFormation);
  }

  void swapSides() {
    sidesSwapped = !sidesSwapped;
    for (final p in players) {
      p.x = 1 - p.x;
    }
    ball.x = 1 - ball.x;
    notifyListeners();
  }

  // --- Team colors ------------------------------------------------------

  Color homeColor = AppColors.teamHomeDefault;
  Color awayColor = AppColors.teamAwayDefault;

  void setHomeColor(Color color) {
    homeColor = color;
    notifyListeners();
  }

  void setAwayColor(Color color) {
    awayColor = color;
    notifyListeners();
  }

  // --- Ball ---------------------------------------------------------------

  Ball ball = Ball();

  void dropBall(Offset local, Size pitchSize, double pieceSize) {
    final maxX = pitchSize.width - pieceSize;
    final maxY = pitchSize.height - pieceSize;
    if (maxX > 0) {
      ball.x = (local.dx - pieceSize / 2).clamp(0, maxX) / maxX;
    }
    if (maxY > 0) {
      ball.y = (local.dy - pieceSize / 2).clamp(0, maxY) / maxY;
    }
    notifyListeners();
  }

  void toggleBallLayer() {
    ball.inFront = !ball.inFront;
    notifyListeners();
  }

  // --- Drawings -------------------------------------------------------

  DrawingTool activeTool = DrawingTool.none;
  Color drawingColor = AppColors.drawYellow;
  double drawingThickness = 4;
  List<DrawingShape> drawings = [];

  /// Indices into [drawings] currently selected. Plain taps/clicks replace
  /// the whole set with a single index; shift-click toggles that index in
  /// or out, building up a multi-selection so several shapes (e.g. every
  /// arrow in one phase of play) can be moved or deleted together.
  Set<int> selectedDrawingIndices = {};
  DrawingShape? draftShape;

  /// Replaces or toggles [index] in [selectedDrawingIndices] depending on
  /// whether Shift is held, so every "tap an existing shape" call site
  /// shares the same multi-select behavior.
  void _selectDrawing(int index) {
    if (HardwareKeyboard.instance.isShiftPressed) {
      selectedDrawingIndices = Set.of(selectedDrawingIndices);
      if (!selectedDrawingIndices.remove(index)) {
        selectedDrawingIndices.add(index);
      }
    } else {
      selectedDrawingIndices = {index};
    }
  }

  /// First click of the arrow tool's start-then-end flow (fraction coords);
  /// null until the user has placed the start point ("X") and is now
  /// choosing where the arrowhead should land.
  Offset? arrowStartPoint;
  Offset? arrowHoverPoint;

  final List<List<DrawingShape>> _undoStack = [];
  final List<List<DrawingShape>> _redoStack = [];
  Offset? _moveDragLast;
  int? _bendDragIndex;

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void setTool(DrawingTool tool) {
    activeTool = tool;
    selectedDrawingIndices = {};
    if (tool != DrawingTool.arrow) {
      arrowStartPoint = null;
      arrowHoverPoint = null;
    }
    if (tool != DrawingTool.ballPath) {
      pathPoints = [];
      pathSegmentBends = [];
      pathHoverPoint = null;
    }
    if (tool != DrawingTool.zone) {
      zonePoints = [];
      zoneHoverPoint = null;
    }
    if (tool != DrawingTool.playerRun) {
      playerRunPoints = [];
      playerRunSegmentBends = [];
      playerRunHoverPoint = null;
      _playerRunPlayerId = null;
      _playerRunSegmentIndex = null;
    }
    notifyListeners();
  }

  /// Activates the ball-path tool with a fresh draft that starts exactly
  /// where the most recently drawn (or selected) ball path currently ends,
  /// so the new waypoints read as a continuation of the same passage of
  /// play instead of visually disconnecting from it. The caller is
  /// expected to have already confirmed this with the user - see
  /// [hasBallPath] for when there's an existing path to offer continuing.
  void continueLastBallPath() {
    final index = resolvedBallPathIndex;
    setTool(DrawingTool.ballPath);
    if (index != null && drawings[index].points.isNotEmpty) {
      final lastPoint = drawings[index].points.last;
      pathPoints = [lastPoint];
      pathHoverPoint = lastPoint;
      notifyListeners();
    }
  }

  /// Click-to-place arrow flow: first tap marks the start ("X"), second tap
  /// commits the arrowhead and adds the finished arrow to [drawings]. Stays
  /// in arrow mode afterward so multiple arrows can be drawn back to back.
  /// Returns the new arrow's index in [drawings] when one was just
  /// completed by this tap, so the caller can offer to attach a message.
  int? handleArrowTap(Offset fraction) {
    if (arrowStartPoint != null) {
      // A pending arrow always finishes on the next tap, regardless of
      // what's underneath it.
      _snapshotDrawingsForUndo();
      drawings.add(
        DrawingShape(
          tool: DrawingTool.arrow,
          color: drawingColor,
          thickness: drawingThickness,
          points: [arrowStartPoint!, fraction],
          waypointMessages: const [null, null],
          durakIndex: selectedDurakIndex,
          ballPathShapeIndex: selectedDurakIndex == null
              ? null
              : resolvedBallPathIndex,
        ),
      );
      arrowStartPoint = null;
      arrowHoverPoint = null;
      notifyListeners();
      return drawings.length - 1;
    }
    // Not mid-arrow: tapping an existing shape selects it (so it can be
    // deleted with Sil, or its midpoint dragged to bend it); tapping empty
    // space starts a new arrow.
    final hitIndex = _hitTestDrawing(fraction);
    if (hitIndex != null) {
      _selectDrawing(hitIndex);
    } else {
      selectedDrawingIndices = {};
      arrowStartPoint = fraction;
      arrowHoverPoint = fraction;
    }
    notifyListeners();
    return null;
  }

  /// Cancels a pending (not-yet-finished) arrow, e.g. when the user presses
  /// Escape after placing only the start point.
  void cancelArrowDraft() {
    if (arrowStartPoint == null) return;
    arrowStartPoint = null;
    arrowHoverPoint = null;
    notifyListeners();
  }

  /// Dragging an existing arrow's midpoint handle (while the arrow tool is
  /// active) bends it into a curve instead of starting a new one - a tap
  /// still places a new start/end point.
  void handleArrowBendStart(Offset fraction) {
    final index = _hitTestBendHandle(fraction);
    if (index == null) return;
    _snapshotDrawingsForUndo();
    _bendDragIndex = index;
    selectedDrawingIndices = {index};
    notifyListeners();
  }

  void handleArrowBendUpdate(Offset fraction) {
    if (_bendDragIndex == null) return;
    drawings[_bendDragIndex!].controlPoint = fraction;
    notifyListeners();
  }

  // --- Ball path (multi-point) --------------------------------------------

  /// In-progress ball-path waypoints (fraction coords), built one click at a
  /// time; empty when no path is being drawn.
  List<Offset> pathPoints = [];
  List<Offset?> pathSegmentBends = [];
  Offset? pathHoverPoint;

  int? _bendPathShapeIndex;
  int? _bendPathSegmentIndex;

  /// Click-to-place ball-path flow: every tap adds another waypoint, drawn
  /// as "x-----x-----x----->" (an X at every waypoint but the last, an
  /// arrowhead at the last). Tapping an existing waypoint (while not
  /// mid-path) seeks the ball there instead, ready to play from that spot;
  /// tapping elsewhere on an existing shape just selects it.
  void handlePathTap(Offset fraction) {
    if (pathPoints.isEmpty) {
      final waypointHit = _hitTestWaypoint(fraction);
      if (waypointHit != null) {
        selectedDrawingIndices = {waypointHit.$1};
        seekBallToWaypoint(waypointHit.$1, waypointHit.$2);
        return;
      }
      final hitIndex = _hitTestDrawing(fraction);
      if (hitIndex != null) {
        _selectDrawing(hitIndex);
        notifyListeners();
        return;
      }
      selectedDrawingIndices = {};
    }
    pathPoints.add(fraction);
    if (pathPoints.length > 1) {
      pathSegmentBends.add(null);
    }
    pathHoverPoint = fraction;
    notifyListeners();
  }

  (int, int)? _hitTestWaypoint(Offset point) {
    const hitRadius = 0.025;
    for (var i = drawings.length - 1; i >= 0; i--) {
      final shape = drawings[i];
      if (shape.tool != DrawingTool.ballPath) continue;
      for (var p = 0; p < shape.points.length; p++) {
        if ((point - shape.points[p]).distance <= hitRadius) return (i, p);
      }
    }
    return null;
  }

  /// Moves the ball to a specific waypoint of a path and pauses there, so
  /// the user can press Play to continue from that exact spot.
  void seekBallToWaypoint(int shapeIndex, int pointIndex) {
    if (shapeIndex >= drawings.length) return;
    final shape = drawings[shapeIndex];
    final segmentCount = shape.points.length - 1;
    if (segmentCount <= 0) return;
    _stopBallPathTicker();
    if (_animatingPathIndex != shapeIndex) revealedWaypoints.clear();
    _animatingPathIndex = shapeIndex;
    ballPathProgress = (pointIndex / segmentCount).clamp(0.0, 1.0);
    _lastAnnouncedSegment = pointIndex - 1;
    for (var i = 0; i <= pointIndex; i++) {
      revealedWaypoints.add(i);
    }
    isAnimatingBallPath = true;
    isBallPathPaused = true;
    _applyBallPathProgress();
    notifyListeners();
  }

  void updatePathHover(Offset fraction) {
    if (pathPoints.isEmpty) return;
    pathHoverPoint = fraction;
    notifyListeners();
  }

  /// Escape: removes only the most recently placed waypoint, not the whole
  /// path-in-progress.
  void cancelLastPathPoint() {
    if (pathPoints.isEmpty) return;
    if (pathPoints.length == 1) {
      pathPoints = [];
      pathSegmentBends = [];
      pathHoverPoint = null;
    } else {
      pathPoints.removeLast();
      pathSegmentBends.removeLast();
      pathHoverPoint = pathPoints.last;
    }
    notifyListeners();
  }

  /// Finishes the in-progress ball path (needs at least 2 waypoints) and
  /// adds it to [drawings].
  void commitBallPath() {
    if (pathPoints.length < 2) {
      pathPoints = [];
      pathSegmentBends = [];
      pathHoverPoint = null;
      notifyListeners();
      return;
    }
    _snapshotDrawingsForUndo();
    drawings.add(
      DrawingShape(
        tool: DrawingTool.ballPath,
        color: drawingColor,
        thickness: drawingThickness,
        points: List.of(pathPoints),
        segmentBends: List.of(pathSegmentBends),
        waypointMessages: List<String?>.filled(
          pathPoints.length,
          null,
          growable: true,
        ),
      ),
    );
    pathPoints = [];
    pathSegmentBends = [];
    pathHoverPoint = null;
    notifyListeners();
  }

  /// Sets (or clears, with null) the message shown when the animated ball
  /// reaches waypoint [pointIndex] of the path at [shapeIndex].
  void setWaypointMessage(int shapeIndex, int pointIndex, String? message) {
    if (shapeIndex >= drawings.length) return;
    final shape = drawings[shapeIndex];
    while (shape.waypointMessages.length <= pointIndex) {
      shape.waypointMessages.add(null);
    }
    shape.waypointMessages[pointIndex] = message;
    notifyListeners();
  }

  /// Dragging an existing ball path's segment midpoint bends that segment
  /// into a curve; a tap still places a new waypoint.
  void handlePathBendStart(Offset fraction) {
    final hit = _hitTestPathBendHandle(fraction);
    if (hit == null) return;
    _snapshotDrawingsForUndo();
    _bendPathShapeIndex = hit.$1;
    _bendPathSegmentIndex = hit.$2;
    selectedDrawingIndices = {hit.$1};
    notifyListeners();
  }

  void handlePathBendUpdate(Offset fraction) {
    if (_bendPathShapeIndex == null || _bendPathSegmentIndex == null) return;
    drawings[_bendPathShapeIndex!].segmentBends[_bendPathSegmentIndex!] =
        fraction;
    notifyListeners();
  }

  void handlePathBendEnd() {
    _bendPathShapeIndex = null;
    _bendPathSegmentIndex = null;
  }

  (int, int)? _hitTestPathBendHandle(Offset point) {
    const handleRadius = 0.03;
    for (var i = drawings.length - 1; i >= 0; i--) {
      final shape = drawings[i];
      if (shape.tool != DrawingTool.ballPath) continue;
      for (var s = 0; s < shape.points.length - 1; s++) {
        final handle =
            shape.segmentBends[s] ??
            Offset.lerp(shape.points[s], shape.points[s + 1], 0.5)!;
        if ((point - handle).distance <= handleRadius) return (i, s);
      }
    }
    return null;
  }

  // --- Area scan (polygon zone) -------------------------------------------

  /// In-progress zone vertices (fraction coords); empty when no zone is
  /// being drawn. Needs at least 3 points before it can be committed.
  List<Offset> zonePoints = [];
  Offset? zoneHoverPoint;

  int? _bendZoneShapeIndex;
  int? _bendZoneVertexIndex;

  /// Click-to-place zone flow: every tap adds another vertex. Tapping an
  /// existing shape (while not mid-zone) selects it instead of starting a
  /// new one.
  void handleZoneTap(Offset fraction) {
    if (zonePoints.isEmpty) {
      final hitIndex = _hitTestDrawing(fraction);
      if (hitIndex != null) {
        _selectDrawing(hitIndex);
        notifyListeners();
        return;
      }
      selectedDrawingIndices = {};
    }
    zonePoints.add(fraction);
    zoneHoverPoint = fraction;
    notifyListeners();
  }

  void updateZoneHover(Offset fraction) {
    if (zonePoints.isEmpty) return;
    zoneHoverPoint = fraction;
    notifyListeners();
  }

  /// Cancels the in-progress zone draft entirely (used when Escape is
  /// pressed before at least 3 points have been placed).
  void cancelZoneDraft() {
    if (zonePoints.isEmpty) return;
    zonePoints = [];
    zoneHoverPoint = null;
    notifyListeners();
  }

  /// Finishes the in-progress zone (needs at least 3 vertices to form a
  /// polygon) and adds it to [drawings].
  void commitZone() {
    if (zonePoints.length < 3) {
      zonePoints = [];
      zoneHoverPoint = null;
      notifyListeners();
      return;
    }
    _snapshotDrawingsForUndo();
    drawings.add(
      DrawingShape(
        tool: DrawingTool.zone,
        color: drawingColor,
        thickness: drawingThickness,
        points: List.of(zonePoints),
      ),
    );
    zonePoints = [];
    zoneHoverPoint = null;
    notifyListeners();
  }

  /// Dragging an existing zone's vertex reshapes the polygon; a tap
  /// elsewhere still places a new vertex for a fresh zone.
  void handleZoneVertexDragStart(Offset fraction) {
    final hit = _hitTestZoneVertex(fraction);
    if (hit == null) return;
    _snapshotDrawingsForUndo();
    _bendZoneShapeIndex = hit.$1;
    _bendZoneVertexIndex = hit.$2;
    selectedDrawingIndices = {hit.$1};
    notifyListeners();
  }

  void handleZoneVertexDragUpdate(Offset fraction) {
    if (_bendZoneShapeIndex == null || _bendZoneVertexIndex == null) return;
    drawings[_bendZoneShapeIndex!].points[_bendZoneVertexIndex!] = fraction;
    notifyListeners();
  }

  void handleZoneVertexDragEnd() {
    _bendZoneShapeIndex = null;
    _bendZoneVertexIndex = null;
  }

  (int, int)? _hitTestZoneVertex(Offset point) {
    const hitRadius = 0.03;
    for (var i = drawings.length - 1; i >= 0; i--) {
      final shape = drawings[i];
      if (shape.tool != DrawingTool.zone) continue;
      for (var p = 0; p < shape.points.length; p++) {
        if ((point - shape.points[p]).distance <= hitRadius) return (i, p);
      }
    }
    return null;
  }

  // --- Waypoint track (Durak Çizgisi) + per-segment player runs ----------

  /// Which segment (0-based; the stretch between waypoint N and N+1) of the
  /// resolved ball path is targeted for a player-run assignment. Selected
  /// from the on-screen waypoint track bar, independent of the drawing tool.
  int? selectedSegmentIndex;

  void selectSegment(int index) {
    selectedSegmentIndex = index;
    notifyListeners();
  }

  void clearSegmentSelection() {
    if (selectedSegmentIndex == null) return;
    selectedSegmentIndex = null;
    selectedDurakIndex = null;
    notifyListeners();
  }

  /// Which durak (waypoint stop, 0-based) new [DrawingTool.arrow] shapes get
  /// tagged with as they're drawn - selected from the waypoint track bar's
  /// dots, independent of [selectedSegmentIndex] (which targets a
  /// player-run instead). Tagged arrows only render while their durak is
  /// selected or the ball is currently sitting there (see DrawingLayer),
  /// so different arrow diagrams can be staged per stop.
  int? selectedDurakIndex;

  void selectDurak(int index) {
    selectedDurakIndex = selectedDurakIndex == index ? null : index;
    notifyListeners();
  }

  /// The ball-path shape a segment/player-run action should target: the
  /// selected drawing if it's a ball path, otherwise the most recent one.
  int? get resolvedBallPathIndex => _resolveBallPathIndex();

  /// Number of segments (waypoint count - 1) in the resolved ball path, for
  /// the waypoint track bar to know how many stops/segments to render.
  int? get resolvedBallPathSegmentCount {
    final index = resolvedBallPathIndex;
    if (index == null) return null;
    final count = drawings[index].points.length - 1;
    return count > 0 ? count : null;
  }

  /// In-progress player-run waypoints (fraction coords); empty when no run
  /// is being drawn.
  List<Offset> playerRunPoints = [];
  List<Offset?> playerRunSegmentBends = [];
  Offset? playerRunHoverPoint;
  String? _playerRunPlayerId;
  int? _playerRunSegmentIndex;

  int? _bendPlayerRunShapeIndex;
  int? _bendPlayerRunRunIndex;
  int? _bendPlayerRunSegmentIndex;

  /// The player this in-progress run is being drawn for, so widgets can
  /// color the draft with that player's team color.
  String? get playerRunTargetId => _playerRunPlayerId;

  /// Enters the player-run drawing tool for the currently selected segment
  /// and single selected player. If that player already has a run ending
  /// the previous segment, the new run's start point snaps to that run's
  /// last point automatically. Returns false (and changes nothing) if a
  /// segment/single player/ball path aren't all selected.
  bool beginPlayerRun() {
    final shapeIndex = resolvedBallPathIndex;
    final segment = selectedSegmentIndex;
    if (shapeIndex == null ||
        segment == null ||
        selectedPlayerIds.length != 1) {
      return false;
    }
    final playerId = selectedPlayerIds.first;
    final shape = drawings[shapeIndex];
    PlayerRun? previous;
    for (final run in shape.playerRuns) {
      if (run.playerId == playerId && run.segmentIndex == segment - 1) {
        previous = run;
        break;
      }
    }
    activeTool = DrawingTool.playerRun;
    _playerRunPlayerId = playerId;
    _playerRunSegmentIndex = segment;
    if (previous != null && previous.points.isNotEmpty) {
      playerRunPoints = [previous.points.last];
      playerRunHoverPoint = previous.points.last;
    } else {
      playerRunPoints = [];
      playerRunHoverPoint = null;
    }
    playerRunSegmentBends = [];
    notifyListeners();
    return true;
  }

  /// Click-to-place player-run flow: every tap adds another waypoint.
  void handlePlayerRunTap(Offset fraction) {
    playerRunPoints.add(fraction);
    if (playerRunPoints.length > 1) {
      playerRunSegmentBends.add(null);
    }
    playerRunHoverPoint = fraction;
    notifyListeners();
  }

  void updatePlayerRunHover(Offset fraction) {
    if (playerRunPoints.isEmpty) return;
    playerRunHoverPoint = fraction;
    notifyListeners();
  }

  /// Discards the in-progress run draft without saving it.
  void cancelPlayerRunDraft() {
    playerRunPoints = [];
    playerRunSegmentBends = [];
    playerRunHoverPoint = null;
    _playerRunPlayerId = null;
    _playerRunSegmentIndex = null;
    notifyListeners();
  }

  /// Finishes the in-progress run (needs at least 2 points) and attaches it
  /// to the resolved ball path, replacing any existing run for the same
  /// (segment, player) pair.
  void commitPlayerRun() {
    final shapeIndex = resolvedBallPathIndex;
    final playerId = _playerRunPlayerId;
    final segment = _playerRunSegmentIndex;
    if (shapeIndex == null ||
        playerId == null ||
        segment == null ||
        playerRunPoints.length < 2) {
      cancelPlayerRunDraft();
      return;
    }
    _snapshotDrawingsForUndo();
    final shape = drawings[shapeIndex];
    shape.playerRuns.removeWhere(
      (r) => r.playerId == playerId && r.segmentIndex == segment,
    );
    shape.playerRuns.add(
      PlayerRun(
        playerId: playerId,
        segmentIndex: segment,
        points: List.of(playerRunPoints),
        bends: List.of(playerRunSegmentBends),
      ),
    );
    playerRunPoints = [];
    playerRunSegmentBends = [];
    playerRunHoverPoint = null;
    _playerRunPlayerId = null;
    _playerRunSegmentIndex = null;
    notifyListeners();
  }

  /// Removes the committed run for the currently selected segment/player,
  /// if one exists (used by the Sil button while nothing is being drawn).
  void deleteCurrentPlayerRun() {
    final shapeIndex = resolvedBallPathIndex;
    final segment = selectedSegmentIndex;
    if (shapeIndex == null ||
        segment == null ||
        selectedPlayerIds.length != 1) {
      return;
    }
    final playerId = selectedPlayerIds.first;
    final shape = drawings[shapeIndex];
    final hadRun = shape.playerRuns.any(
      (r) => r.playerId == playerId && r.segmentIndex == segment,
    );
    if (!hadRun) return;
    _snapshotDrawingsForUndo();
    shape.playerRuns.removeWhere(
      (r) => r.playerId == playerId && r.segmentIndex == segment,
    );
    notifyListeners();
  }

  /// Dragging an existing player run's midpoint handle bends that segment;
  /// a tap still places a new waypoint.
  void handlePlayerRunBendStart(Offset fraction) {
    final hit = _hitTestPlayerRunBendHandle(fraction);
    if (hit == null) return;
    _snapshotDrawingsForUndo();
    _bendPlayerRunShapeIndex = hit.$1;
    _bendPlayerRunRunIndex = hit.$2;
    _bendPlayerRunSegmentIndex = hit.$3;
    notifyListeners();
  }

  void handlePlayerRunBendUpdate(Offset fraction) {
    if (_bendPlayerRunShapeIndex == null) return;
    drawings[_bendPlayerRunShapeIndex!]
            .playerRuns[_bendPlayerRunRunIndex!]
            .bends[_bendPlayerRunSegmentIndex!] =
        fraction;
    notifyListeners();
  }

  void handlePlayerRunBendEnd() {
    _bendPlayerRunShapeIndex = null;
    _bendPlayerRunRunIndex = null;
    _bendPlayerRunSegmentIndex = null;
  }

  (int, int, int)? _hitTestPlayerRunBendHandle(Offset point) {
    const handleRadius = 0.03;
    for (var i = drawings.length - 1; i >= 0; i--) {
      final shape = drawings[i];
      if (shape.tool != DrawingTool.ballPath) continue;
      for (var r = 0; r < shape.playerRuns.length; r++) {
        final run = shape.playerRuns[r];
        for (var s = 0; s < run.points.length - 1; s++) {
          final handle =
              run.bends[s] ??
              Offset.lerp(run.points[s], run.points[s + 1], 0.5)!;
          if ((point - handle).distance <= handleRadius) return (i, r, s);
        }
      }
    }
    return null;
  }

  // --- Ball path playback ---------------------------------------------

  bool isAnimatingBallPath = false;
  bool isBallPathPaused = false;
  double ballPathSpeed = 1.0;
  double ballPathProgress = 0.0;
  int? _animatingPathIndex;

  /// Drives playback on the engine's vsync schedule (via [Ticker]) instead
  /// of a fixed-interval [Timer], so each step uses the *actual* elapsed
  /// frame time - this is what keeps the motion smooth even when a frame
  /// is delayed, instead of assuming a constant 16ms per tick and drifting
  /// out of sync with what's actually rendered.
  Ticker? _ballPathTicker;
  Duration _ballPathTickerElapsed = Duration.zero;
  int _lastAnnouncedSegment = -1;

  void _stopBallPathTicker() {
    _ballPathTicker?.stop();
    _ballPathTicker?.dispose();
    _ballPathTicker = null;
  }

  /// The progress value (a clean waypoint boundary, e.g. 1/segmentCount)
  /// the current Play press should stop at - so the ball advances one
  /// Durak-to-Durak hop at a time instead of running the whole path in one
  /// go. Recomputed every time Play is pressed/resumed.
  double? _playTargetProgress;

  /// While true, the drawn player-run lines are faded to transparent (see
  /// DrawingLayer) - it only affects the line's visibility, never whether
  /// the player themself moves during ball-path playback. Toggled from the
  /// Taktikler toolbar.
  bool hidePlayerRuns = false;

  void toggleHidePlayerRuns() {
    hidePlayerRuns = !hidePlayerRuns;
    notifyListeners();
  }

  /// While true, every ball-path line/marker is painted at reduced opacity
  /// (see DrawingLayer) so it reads as a faint guide instead of a bold
  /// line over the pitch. Toggled from the Taktikler toolbar, same
  /// mechanics as [hidePlayerRuns].
  bool dimBallPath = false;

  void toggleDimBallPath() {
    dimBallPath = !dimBallPath;
    notifyListeners();
  }

  /// The path currently being animated, for widgets that need to render
  /// its waypoint labels.
  int? get animatingPathIndex => _animatingPathIndex;

  /// Waypoint indices (of [animatingPathIndex]) the ball has reached so far
  /// this playback; each one's message renders as a label fixed at that
  /// waypoint's own position on the pitch (not a bottom SnackBar), and
  /// stays visible once revealed.
  final Set<int> revealedWaypoints = {};

  bool get hasBallPath => drawings.any((d) => d.tool == DrawingTool.ballPath);

  /// Which Durak (waypoint, 0-based) the ball currently occupies in the
  /// animating path - so the waypoint track bar can highlight it live
  /// during playback, distinct from [selectedSegmentIndex] (which marks
  /// the segment being targeted for a player-run assignment).
  int? get currentBallDurakIndex {
    final index = _animatingPathIndex;
    if (index == null || index >= drawings.length) return null;
    final segmentCount = drawings[index].points.length - 1;
    if (segmentCount <= 0) return null;
    return (ballPathProgress * segmentCount).round().clamp(0, segmentCount);
  }

  int? _resolveBallPathIndex() {
    for (final selected in selectedDrawingIndices) {
      if (selected < drawings.length &&
          drawings[selected].tool == DrawingTool.ballPath) {
        return selected;
      }
    }
    for (var i = drawings.length - 1; i >= 0; i--) {
      if (drawings[i].tool == DrawingTool.ballPath) return i;
    }
    return null;
  }

  /// Starts (or resumes) animating the ball along the selected ball path,
  /// or the most recently drawn one if none is selected. Advances only to
  /// the next Durak and then auto-pauses there - pressing Play again
  /// continues to the following one, and so on.
  bool playBallPath() {
    final index = _resolveBallPathIndex();
    if (index == null) return false;
    final isFreshStart =
        _animatingPathIndex != index || ballPathProgress >= 1.0;
    _animatingPathIndex = index;
    isAnimatingBallPath = true;
    isBallPathPaused = false;
    if (ballPathProgress >= 1.0) ballPathProgress = 0.0;
    if (isFreshStart) {
      _lastAnnouncedSegment = -1;
      revealedWaypoints.clear();
    }
    _recomputePlayTarget();
    _startBallPathTicker();
    notifyListeners();
    return true;
  }

  void pauseBallPath() {
    if (!isAnimatingBallPath || isBallPathPaused) return;
    isBallPathPaused = true;
    _stopBallPathTicker();
    notifyListeners();
  }

  /// Scrubs the ball (and any players assigned a run) directly to
  /// [progress] (0..1 across the whole path), forward or backward - used
  /// when the user drags the waypoint track bar like a video scrubber.
  /// Reuses the same [_applyBallPathProgress] the Play button drives, so
  /// dragging moves everything exactly as playback would.
  void scrubBallPathTo(double progress) {
    final index = _resolveBallPathIndex();
    if (index == null) return;
    _stopBallPathTicker();
    _animatingPathIndex = index;
    isAnimatingBallPath = true;
    isBallPathPaused = true;
    ballPathProgress = progress.clamp(0.0, 1.0);
    _applyBallPathProgress();
    notifyListeners();
  }

  /// Once a ball path exists, the ball is "on rails": dragging it no longer
  /// drops it anywhere on the pitch - it snaps to whichever point on the
  /// path is closest to [target] (pitch-fraction coords) and moves there
  /// exactly like scrubbing the waypoint track bar does, carrying along any
  /// player assigned a run on that segment.
  void snapBallToPathNear(Offset target) {
    final index = _resolveBallPathIndex();
    if (index == null) return;
    final shape = drawings[index];
    if (shape.points.length < 2) return;
    const samples = 300;
    var bestProgress = 0.0;
    var bestDistanceSq = double.infinity;
    for (var i = 0; i <= samples; i++) {
      final progress = i / samples;
      final point = _positionAlong(shape.points, shape.segmentBends, progress);
      final dx = point.dx - target.dx;
      final dy = point.dy - target.dy;
      final distanceSq = dx * dx + dy * dy;
      if (distanceSq < bestDistanceSq) {
        bestDistanceSq = distanceSq;
        bestProgress = progress;
      }
    }
    scrubBallPathTo(bestProgress);
  }

  void restartBallPath() {
    if (_animatingPathIndex == null) return;
    ballPathProgress = 0.0;
    _lastAnnouncedSegment = -1;
    revealedWaypoints.clear();
    _applyBallPathProgress();
    if (isAnimatingBallPath && !isBallPathPaused) {
      _recomputePlayTarget();
      _startBallPathTicker();
    }
    notifyListeners();
  }

  /// Steps the ball back to the previous Durak (one whole segment), to
  /// match the step-wise, Durak-to-Durak nature of playback.
  void rewindBallPath() {
    final index = _animatingPathIndex;
    if (index == null || index >= drawings.length) return;
    final segmentCount = drawings[index].points.length - 1;
    if (segmentCount <= 0) return;
    final currentIndex = (ballPathProgress * segmentCount).round().clamp(
      0,
      segmentCount,
    );
    final targetIndex = (currentIndex - 1).clamp(0, segmentCount);
    ballPathProgress = targetIndex / segmentCount;
    _applyBallPathProgress();
    notifyListeners();
  }

  void setBallPathSpeed(double speed) {
    ballPathSpeed = speed.clamp(0.25, 4.0);
    notifyListeners();
  }

  /// Sets [_playTargetProgress] to the next whole-Durak boundary above the
  /// current progress, so the upcoming Play advances exactly one segment.
  void _recomputePlayTarget() {
    final index = _animatingPathIndex;
    if (index == null || index >= drawings.length) {
      _playTargetProgress = null;
      return;
    }
    final segmentCount = drawings[index].points.length - 1;
    if (segmentCount <= 0) {
      _playTargetProgress = null;
      return;
    }
    final currentIndex = (ballPathProgress * segmentCount).round().clamp(
      0,
      segmentCount,
    );
    final targetIndex = (currentIndex + 1).clamp(1, segmentCount);
    _playTargetProgress = targetIndex / segmentCount;
  }

  void _startBallPathTicker() {
    _stopBallPathTicker();
    _ballPathTickerElapsed = Duration.zero;
    _ballPathTicker = Ticker(_onBallPathTick)..start();
  }

  /// [elapsed] is the total time since this ticker started, not since the
  /// last tick - so the actual per-frame step is the delta against
  /// [_ballPathTickerElapsed]. Using the real elapsed time (rather than
  /// assuming a fixed ~16ms per callback) keeps the ball's speed constant
  /// even if a frame is delayed, instead of the motion stuttering or
  /// drifting out of sync with what's on screen.
  void _onBallPathTick(Duration elapsed) {
    final dtSeconds =
        (elapsed - _ballPathTickerElapsed).inMicroseconds / 1000000;
    _ballPathTickerElapsed = elapsed;
    ballPathProgress += dtSeconds * 0.15 * ballPathSpeed;
    final target = _playTargetProgress;
    if (target != null && ballPathProgress >= target) {
      ballPathProgress = target;
      _applyBallPathProgress();
      pauseBallPath();
      return;
    }
    if (ballPathProgress >= 1.0) {
      ballPathProgress = 1.0;
      _applyBallPathProgress();
      pauseBallPath();
      return;
    }
    _applyBallPathProgress();
    animationTick.notifyListeners();
  }

  void _applyBallPathProgress() {
    final index = _animatingPathIndex;
    if (index == null || index >= drawings.length) return;
    final shape = drawings[index];
    final points = shape.points;
    if (points.length < 2) return;
    final segmentCount = points.length - 1;
    final scaled = (ballPathProgress * segmentCount).clamp(
      0.0,
      segmentCount.toDouble(),
    );
    var segment = scaled.floor();
    if (segment >= segmentCount) segment = segmentCount - 1;
    if (segment != _lastAnnouncedSegment) {
      _lastAnnouncedSegment = segment;
      revealedWaypoints.add(segment);
    }
    if (ballPathProgress >= 1.0) {
      revealedWaypoints.add(segmentCount);
    }
    final t = scaled - segment;
    final bend = segment < shape.segmentBends.length
        ? shape.segmentBends[segment]
        : null;
    final position = _positionAlong(
      [points[segment], points[segment + 1]],
      [bend],
      t,
    );
    ball.x = position.dx;
    ball.y = position.dy;

    // Any player assigned a run for this segment moves in lockstep with the
    // ball, using the same segment-local progress `t` so they arrive at
    // their run's endpoint exactly as the ball reaches the next waypoint.
    // [hidePlayerRuns] only fades the drawn line (see DrawingLayer) - it
    // never stops the player itself from moving.
    for (final run in shape.playerRuns) {
      if (run.segmentIndex != segment || run.points.length < 2) continue;
      final player = _findPlayerById(run.playerId);
      if (player == null) continue;
      final runPosition = _positionAlong(run.points, run.bends, t);
      player.x = runPosition.dx;
      player.y = runPosition.dy;
    }
  }

  Player? _findPlayerById(String id) {
    for (final player in players) {
      if (player.id == id) return player;
    }
    return null;
  }

  /// Interpolates a point along a poly-line at fractional [progress]
  /// (0..1 across the whole line), following a quadratic-bezier bend for
  /// any segment that has one. Shared by the ball's own path and every
  /// per-segment player run, since both are just "a poly-line plus optional
  /// per-segment bends".
  Offset _positionAlong(
    List<Offset> points,
    List<Offset?> bends,
    double progress,
  ) {
    if (points.length < 2) return points.isEmpty ? Offset.zero : points.first;
    final segmentCount = points.length - 1;
    final scaled = (progress * segmentCount).clamp(
      0.0,
      segmentCount.toDouble(),
    );
    var segment = scaled.floor();
    if (segment >= segmentCount) segment = segmentCount - 1;
    final t = scaled - segment;
    final p0 = points[segment];
    final p1 = points[segment + 1];
    final bend = segment < bends.length ? bends[segment] : null;
    if (bend != null) {
      final u = 1 - t;
      return Offset(
        u * u * p0.dx + 2 * u * t * bend.dx + t * t * p1.dx,
        u * u * p0.dy + 2 * u * t * bend.dy + t * t * p1.dy,
      );
    }
    return Offset.lerp(p0, p1, t)!;
  }

  void handleArrowBendEnd() {
    _bendDragIndex = null;
  }

  void updateArrowHover(Offset fraction) {
    if (arrowStartPoint == null) return;
    arrowHoverPoint = fraction;
    notifyListeners();
  }

  void setDrawingColor(Color color) {
    drawingColor = color;
    notifyListeners();
  }

  void setDrawingThickness(double thickness) {
    drawingThickness = thickness;
    notifyListeners();
  }

  void handleCanvasPanStart(Offset fraction) {
    if (activeTool == DrawingTool.select) {
      final bendIndex = _hitTestBendHandle(fraction);
      if (bendIndex != null) {
        _snapshotDrawingsForUndo();
        selectedDrawingIndices = {bendIndex};
        _bendDragIndex = bendIndex;
        notifyListeners();
        return;
      }
      final index = _hitTestDrawing(fraction);
      if (index != null) {
        _snapshotDrawingsForUndo();
        // Dragging a shape that's already part of a multi-selection moves
        // the whole group; dragging any other shape replaces the selection
        // with just that one (unless Shift toggles it into the group).
        if (!selectedDrawingIndices.contains(index)) {
          _selectDrawing(index);
        }
        _moveDragLast = fraction;
      } else {
        selectedDrawingIndices = {};
        _moveDragLast = null;
      }
      notifyListeners();
      return;
    }
    if (activeTool == DrawingTool.none) return;
    draftShape = DrawingShape(
      tool: activeTool,
      color: drawingColor,
      thickness: drawingThickness,
      points: [fraction, fraction],
    );
    notifyListeners();
  }

  void handleCanvasPanUpdate(Offset fraction) {
    if (activeTool == DrawingTool.select) {
      if (_bendDragIndex != null) {
        drawings[_bendDragIndex!].controlPoint = fraction;
        notifyListeners();
        return;
      }
      if (selectedDrawingIndices.isEmpty || _moveDragLast == null) return;
      final delta = fraction - _moveDragLast!;
      for (final index in selectedDrawingIndices) {
        final shape = drawings[index];
        for (var i = 0; i < shape.points.length; i++) {
          shape.points[i] = shape.points[i] + delta;
        }
      }
      _moveDragLast = fraction;
      notifyListeners();
      return;
    }
    final shape = draftShape;
    if (shape == null) return;
    if (shape.tool == DrawingTool.freehand ||
        shape.tool == DrawingTool.heatmap) {
      shape.points.add(fraction);
    } else {
      shape.points[1] = fraction;
    }
    notifyListeners();
  }

  void handleCanvasPanEnd() {
    if (activeTool == DrawingTool.select) {
      _moveDragLast = null;
      _bendDragIndex = null;
      return;
    }
    final shape = draftShape;
    draftShape = null;
    if (shape == null) return;
    _snapshotDrawingsForUndo();
    drawings.add(shape);
    notifyListeners();
  }

  void deleteSelectedDrawing() {
    if (selectedDrawingIndices.isEmpty) return;
    _snapshotDrawingsForUndo();
    // Remove highest indices first so earlier ones stay valid mid-loop.
    for (final index
        in selectedDrawingIndices.toList()..sort((a, b) => b.compareTo(a))) {
      drawings.removeAt(index);
    }
    selectedDrawingIndices = {};
    notifyListeners();
  }

  /// Right-click while a Taktikler tool (arrow/ball path/zone/player run) is
  /// active: cancels whatever draft is in progress outright (discarding it,
  /// unlike Escape which finishes ball path/zone/player run); with nothing
  /// in progress, deletes whichever shape is under the cursor instead.
  void handleDrawingRightClick(Offset fraction) {
    if (activeTool == DrawingTool.arrow && arrowStartPoint != null) {
      cancelArrowDraft();
      return;
    }
    if (activeTool == DrawingTool.ballPath && pathPoints.isNotEmpty) {
      pathPoints = [];
      pathSegmentBends = [];
      pathHoverPoint = null;
      notifyListeners();
      return;
    }
    if (activeTool == DrawingTool.zone && zonePoints.isNotEmpty) {
      cancelZoneDraft();
      return;
    }
    if (activeTool == DrawingTool.playerRun) {
      if (playerRunPoints.isNotEmpty) {
        cancelPlayerRunDraft();
      } else {
        deleteCurrentPlayerRun();
      }
      return;
    }
    final hitIndex = _hitTestDrawing(fraction);
    if (hitIndex == null) return;
    _snapshotDrawingsForUndo();
    drawings.removeAt(hitIndex);
    selectedDrawingIndices = selectedDrawingIndices
        .where((i) => i != hitIndex)
        .map((i) => i > hitIndex ? i - 1 : i)
        .toSet();
    notifyListeners();
  }

  void clearDrawings() {
    if (drawings.isEmpty) return;
    _snapshotDrawingsForUndo();
    drawings.clear();
    selectedDrawingIndices = {};
    notifyListeners();
  }

  // --- Drawing presets (reusable templates, independent of any Tactic) ----

  /// Named drawing sets (e.g. a corner-kick routine) saved from the current
  /// board so they can be dropped onto any plan instead of being redrawn by
  /// hand each time. In-memory only, like the rest of the app's state.
  final List<DrawingPreset> drawingPresets = [];

  /// Snapshots the currently drawn shapes (selected ones if any, otherwise
  /// everything) into a new named preset.
  void saveDrawingsAsPreset(String name) {
    if (drawings.isEmpty) return;
    final source = selectedDrawingIndices.isNotEmpty
        ? selectedDrawingIndices.map((i) => drawings[i]).toList()
        : drawings;
    drawingPresets.add(
      DrawingPreset(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        shapes: source.map((s) => s.copy()).toList(),
      ),
    );
    notifyListeners();
  }

  /// Adds a copy of every shape in the preset [id] to the current board,
  /// at the same fractional positions they were saved with, and selects
  /// them so they can be nudged into place right away.
  void applyDrawingPreset(String id) {
    final preset = drawingPresets.firstWhere((p) => p.id == id);
    _snapshotDrawingsForUndo();
    final startIndex = drawings.length;
    drawings.addAll(preset.shapes.map((s) => s.copy()));
    selectedDrawingIndices = {
      for (var i = 0; i < preset.shapes.length; i++) startIndex + i,
    };
    notifyListeners();
  }

  void deleteDrawingPreset(String id) {
    drawingPresets.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  void renameDrawingPreset(String id, String name) {
    if (name.trim().isEmpty) return;
    drawingPresets.firstWhere((p) => p.id == id).name = name.trim();
    notifyListeners();
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(drawings.map((d) => d.copy()).toList());
    drawings = _undoStack.removeLast();
    selectedDrawingIndices = {};
    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(drawings.map((d) => d.copy()).toList());
    drawings = _redoStack.removeLast();
    selectedDrawingIndices = {};
    notifyListeners();
  }

  void _snapshotDrawingsForUndo() {
    _undoStack.add(drawings.map((d) => d.copy()).toList());
    if (_undoStack.length > 50) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  /// Finds a line/arrow whose midpoint (or existing bend handle, if it's
  /// already curved) is near [point], so grabbing it bends the line instead
  /// of moving the whole shape.
  int? _hitTestBendHandle(Offset point) {
    const handleRadius = 0.03;
    for (var i = drawings.length - 1; i >= 0; i--) {
      final shape = drawings[i];
      if (shape.tool != DrawingTool.line && shape.tool != DrawingTool.arrow) {
        continue;
      }
      final handle =
          shape.controlPoint ??
          Offset.lerp(shape.points.first, shape.points.last, 0.5)!;
      if ((point - handle).distance <= handleRadius) return i;
    }
    return null;
  }

  /// Tools whose drawing is a thin stroke rather than a filled area - hit
  /// testing these against their bounding box (like the area tools below)
  /// would treat every tap inside the box as a hit, which for a multi-point
  /// ball path can cover most of the pitch. These are tested against actual
  /// distance to the path instead, so only taps near the visible line count.
  static const _strokeTools = {
    DrawingTool.arrow,
    DrawingTool.line,
    DrawingTool.freehand,
    DrawingTool.ballPath,
    DrawingTool.playerRun,
  };

  int? _hitTestDrawing(Offset point) {
    const strokeHitRadius = 0.02;
    for (var i = drawings.length - 1; i >= 0; i--) {
      final shape = drawings[i];
      if (_strokeTools.contains(shape.tool)) {
        if (_distanceToPolyline(point, shape.points) <= strokeHitRadius) {
          return i;
        }
      } else if (_boundsOf(shape).inflate(0.02).contains(point)) {
        return i;
      }
    }
    return null;
  }

  double _distanceToPolyline(Offset point, List<Offset> points) {
    if (points.isEmpty) return double.infinity;
    if (points.length == 1) return (point - points.first).distance;
    var minDistance = double.infinity;
    for (var i = 0; i < points.length - 1; i++) {
      final distance = _distanceToSegment(point, points[i], points[i + 1]);
      if (distance < minDistance) minDistance = distance;
    }
    return minDistance;
  }

  double _distanceToSegment(Offset point, Offset a, Offset b) {
    final ab = b - a;
    final lengthSquared = ab.dx * ab.dx + ab.dy * ab.dy;
    if (lengthSquared == 0) return (point - a).distance;
    final t =
        (((point - a).dx * ab.dx) + ((point - a).dy * ab.dy)) / lengthSquared;
    final projection = a + ab * t.clamp(0.0, 1.0);
    return (point - projection).distance;
  }

  Rect _boundsOf(DrawingShape shape) {
    var minX = shape.points.first.dx, maxX = shape.points.first.dx;
    var minY = shape.points.first.dy, maxY = shape.points.first.dy;
    for (final point in shape.points) {
      minX = math.min(minX, point.dx);
      maxX = math.max(maxX, point.dx);
      minY = math.min(minY, point.dy);
      maxY = math.max(maxY, point.dy);
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  // --- Tactics (saved states) --------------------------------------------

  final List<Tactic> tactics = [];
  String? currentTacticId;

  void saveCurrentTactic() {
    _snapshotIntoCurrentTactic();
    notifyListeners();
  }

  void _snapshotIntoCurrentTactic() {
    final index = tactics.indexWhere((t) => t.id == currentTacticId);
    if (index == -1) return;
    tactics[index] = Tactic(
      id: tactics[index].id,
      name: tactics[index].name,
      players: players.map((p) => p.copy()).toList(),
      ball: ball.copy(),
      drawings: drawings.map((d) => d.copy()).toList(),
      homeFormation: homeFormation,
      awayFormation: awayFormation,
      sidesSwapped: sidesSwapped,
    );
  }

  void _loadTactic(Tactic tactic) {
    _stopBallPathTicker();
    isAnimatingBallPath = false;
    isBallPathPaused = false;
    ballPathProgress = 0.0;
    _animatingPathIndex = null;
    _lastAnnouncedSegment = -1;
    revealedWaypoints.clear();
    players = tactic.players.map((p) => p.copy()).toList();
    ball = tactic.ball.copy();
    drawings = tactic.drawings.map((d) => d.copy()).toList();
    homeFormation = tactic.homeFormation ?? homeFormation;
    awayFormation = tactic.awayFormation ?? awayFormation;
    sidesSwapped = tactic.sidesSwapped;
    selectedPlayerIds = {};
    selectedDrawingIndices = {};
    draftShape = null;
    arrowStartPoint = null;
    arrowHoverPoint = null;
    pathPoints = [];
    pathSegmentBends = [];
    pathHoverPoint = null;
    zonePoints = [];
    zoneHoverPoint = null;
    selectedSegmentIndex = null;
    selectedDurakIndex = null;
    playerRunPoints = [];
    playerRunSegmentBends = [];
    playerRunHoverPoint = null;
    _playerRunPlayerId = null;
    _playerRunSegmentIndex = null;
    _undoStack.clear();
    _redoStack.clear();
  }

  void createTactic(String name) {
    _snapshotIntoCurrentTactic();
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final tactic = Tactic(
      id: id,
      name: name,
      players: _buildRoster(),
      ball: Ball(),
      drawings: const [],
      homeFormation: FormationType.f433,
      awayFormation: FormationType.f433,
    );
    tactics.add(tactic);
    currentTacticId = id;
    _loadTactic(tactic);
    notifyListeners();
  }

  void duplicateTactic(String id) {
    _snapshotIntoCurrentTactic();
    final source = tactics.firstWhere((t) => t.id == id);
    final newId = DateTime.now().microsecondsSinceEpoch.toString();
    final copy = source.copyWith(id: newId, name: '${source.name} copy');
    tactics.add(copy);
    currentTacticId = newId;
    _loadTactic(copy);
    notifyListeners();
  }

  /// Saves the current live board (pitch, drawings, formations - everything
  /// [_snapshotIntoCurrentTactic] captures) as a new, separately named entry
  /// in [tactics] and switches to it - a "Save As" for the Kayıtlar panel,
  /// so a coach can bookmark a specific moment/plan without losing the one
  /// they started from.
  void saveCurrentAsNew(String name) {
    if (name.trim().isEmpty) return;
    _snapshotIntoCurrentTactic();
    final source = tactics.firstWhere((t) => t.id == currentTacticId);
    final newId = DateTime.now().microsecondsSinceEpoch.toString();
    final copy = source.copyWith(id: newId, name: name.trim());
    tactics.add(copy);
    currentTacticId = newId;
    _loadTactic(copy);
    notifyListeners();
  }

  /// Running counter mixed into generated ids for bulk imports
  /// ([importTacticFromJson]) - on web, DateTime only has millisecond
  /// resolution, so a tight loop importing many files in one go could
  /// otherwise mint colliding ids within the same millisecond.
  int _importSequence = 0;

  /// Parses a snapshot previously produced by [exportSnapshotJson] and adds
  /// it as a new, separately named entry in [tactics] - unlike
  /// [importSnapshotFromJson], this never touches the currently live board
  /// or switches away from it, so many files can be bulk-imported into the
  /// Kayıtlar list in a loop. Returns the new tactic's name. Throws
  /// [FormatException]/[TypeError] on malformed JSON - callers should catch
  /// and skip the offending file.
  String importTacticFromJson(String source, {required String fallbackName}) {
    final data = jsonDecode(source) as Map<String, dynamic>;
    final pitch = data['pitch'] as Map<String, dynamic>? ?? const {};
    final teams = data['teams'] as Map<String, dynamic>? ?? const {};
    final home = teams['home'] as Map<String, dynamic>? ?? const {};
    final away = teams['away'] as Map<String, dynamic>? ?? const {};

    final importedName = (data['planName'] as String?)?.trim();
    final name = (importedName != null && importedName.isNotEmpty)
        ? importedName
        : fallbackName;
    final id = '${DateTime.now().microsecondsSinceEpoch}-${_importSequence++}';

    final tactic = Tactic(
      id: id,
      name: name,
      players: (data['players'] as List? ?? const [])
          .map((p) => Player.fromJson(p as Map<String, dynamic>))
          .toList(),
      ball: data['ball'] != null
          ? Ball.fromJson(data['ball'] as Map<String, dynamic>)
          : Ball(),
      drawings: (data['drawings'] as List? ?? const [])
          .map((d) => DrawingShape.fromJson(d as Map<String, dynamic>))
          .toList(),
      homeFormation: home['formation'] != null
          ? FormationType.values.byName(home['formation'] as String)
          : null,
      awayFormation: away['formation'] != null
          ? FormationType.values.byName(away['formation'] as String)
          : null,
      sidesSwapped: pitch['sidesSwapped'] as bool? ?? false,
    );
    tactics.add(tactic);
    notifyListeners();
    return tactic.name;
  }

  void deleteTactic(String id) {
    if (tactics.length <= 1) return;
    final wasCurrent = currentTacticId == id;
    tactics.removeWhere((t) => t.id == id);
    if (wasCurrent) {
      final next = tactics.first;
      currentTacticId = next.id;
      _loadTactic(next);
    }
    notifyListeners();
  }

  void renameTactic(String id, String name) {
    if (name.trim().isEmpty) return;
    tactics.firstWhere((t) => t.id == id).name = name.trim();
    notifyListeners();
  }

  void switchTactic(String id) {
    if (id == currentTacticId) return;
    _snapshotIntoCurrentTactic();
    final target = tactics.firstWhere((t) => t.id == id);
    currentTacticId = id;
    _loadTactic(target);
    notifyListeners();
  }

  // --- JSON export / import ----------------------------------------------

  /// Serializes the whole live board - pitch settings, players, formations,
  /// team colors, ball, every drawing (lines/arrows/ball paths/zones, with
  /// their messages), and drawing/fullscreen settings - into one JSON
  /// string that [importSnapshotFromJson] can fully restore later. The
  /// drawings array's own order is its layer order, so no separate
  /// "layer index" field is needed. Panning/zooming the pitch is disabled
  /// in this app (the pitch is fixed), so "camera" is a fixed placeholder
  /// kept only so older exports stay forward-compatible if that ever changes.
  String exportSnapshotJson() {
    final planName = tactics
        .firstWhere(
          (t) => t.id == currentTacticId,
          orElse: () => Tactic(
            id: '',
            name: 'Maç Planım',
            players: const [],
            ball: Ball(),
            drawings: const [],
          ),
        )
        .name;
    final data = {
      'version': 2,
      'planName': planName,
      'pitch': {
        'pitchImage': pitchImage,
        'squadSize': squadSize,
        'showBothTeams': showBothTeams,
        'sidesSwapped': sidesSwapped,
      },
      'teams': {
        'home': {
          'color': homeColor.toARGB32(),
          'formation': homeFormation.name,
        },
        'away': {
          'color': awayColor.toARGB32(),
          'formation': awayFormation.name,
        },
      },
      'players': players.map((p) => p.toJson()).toList(),
      'ball': ball.toJson(),
      'drawings': drawings.map((d) => d.toJson()).toList(),
      'settings': {
        'drawingColor': drawingColor.toARGB32(),
        'drawingThickness': drawingThickness,
        'fullscreenShortcutKeyId': fullscreenShortcutKey.keyId,
        'ballPathSpeed': ballPathSpeed,
        'hidePlayerRuns': hidePlayerRuns,
        'dimBallPath': dimBallPath,
        'jerseyImage': jerseyImage,
        'ballImage': ballImage,
        'adBannerImageUrl': adBannerImageUrl,
        'channelIconImageUrl': channelIconImageUrl,
      },
      'camera': {'zoom': 1.0, 'offsetX': 0.0, 'offsetY': 0.0},
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Restores a board previously produced by [exportSnapshotJson]. When
  /// [overwrite] is true the currently active plan's data is replaced in
  /// place (same id); otherwise the imported board becomes a brand new
  /// plan and is switched to. Throws [FormatException]/[TypeError] on
  /// malformed JSON - callers should catch and show the user an error.
  void importSnapshotFromJson(String source, {required bool overwrite}) {
    final data = jsonDecode(source) as Map<String, dynamic>;
    final pitch = data['pitch'] as Map<String, dynamic>? ?? const {};
    final teams = data['teams'] as Map<String, dynamic>? ?? const {};
    final home = teams['home'] as Map<String, dynamic>? ?? const {};
    final away = teams['away'] as Map<String, dynamic>? ?? const {};
    final settings = data['settings'] as Map<String, dynamic>? ?? const {};

    _stopBallPathTicker();
    isAnimatingBallPath = false;
    isBallPathPaused = false;
    ballPathProgress = 0.0;
    _animatingPathIndex = null;
    _lastAnnouncedSegment = -1;
    revealedWaypoints.clear();

    players = (data['players'] as List? ?? const [])
        .map((p) => Player.fromJson(p as Map<String, dynamic>))
        .toList();
    ball = data['ball'] != null
        ? Ball.fromJson(data['ball'] as Map<String, dynamic>)
        : Ball();
    drawings = (data['drawings'] as List? ?? const [])
        .map((d) => DrawingShape.fromJson(d as Map<String, dynamic>))
        .toList();
    homeFormation = home['formation'] != null
        ? FormationType.values.byName(home['formation'] as String)
        : homeFormation;
    awayFormation = away['formation'] != null
        ? FormationType.values.byName(away['formation'] as String)
        : awayFormation;
    sidesSwapped = pitch['sidesSwapped'] as bool? ?? false;
    if (pitch['pitchImage'] != null) pitchImage = pitch['pitchImage'] as String;
    if (pitch['squadSize'] != null) squadSize = pitch['squadSize'] as int;
    if (pitch['showBothTeams'] != null) {
      showBothTeams = pitch['showBothTeams'] as bool;
    }
    if (home['color'] != null) homeColor = Color(home['color'] as int);
    if (away['color'] != null) awayColor = Color(away['color'] as int);
    if (settings['drawingColor'] != null) {
      drawingColor = Color(settings['drawingColor'] as int);
    }
    if (settings['drawingThickness'] != null) {
      drawingThickness = (settings['drawingThickness'] as num).toDouble();
    }
    if (settings['fullscreenShortcutKeyId'] != null) {
      fullscreenShortcutKey = LogicalKeyboardKey(
        settings['fullscreenShortcutKeyId'] as int,
      );
    }
    if (settings['ballPathSpeed'] != null) {
      ballPathSpeed = (settings['ballPathSpeed'] as num).toDouble().clamp(
        0.25,
        4.0,
      );
    }
    if (settings['hidePlayerRuns'] != null) {
      hidePlayerRuns = settings['hidePlayerRuns'] as bool;
    }
    if (settings['dimBallPath'] != null) {
      dimBallPath = settings['dimBallPath'] as bool;
    }
    if (settings['jerseyImage'] != null) {
      jerseyImage = settings['jerseyImage'] as String;
    }
    if (settings['ballImage'] != null) {
      ballImage = settings['ballImage'] as String;
    }
    adBannerImageUrl = settings['adBannerImageUrl'] as String?;
    channelIconImageUrl = settings['channelIconImageUrl'] as String?;

    selectedPlayerIds = {};
    selectedDrawingIndices = {};
    draftShape = null;
    arrowStartPoint = null;
    arrowHoverPoint = null;
    pathPoints = [];
    pathSegmentBends = [];
    pathHoverPoint = null;
    zonePoints = [];
    zoneHoverPoint = null;
    selectedSegmentIndex = null;
    selectedDurakIndex = null;
    playerRunPoints = [];
    playerRunSegmentBends = [];
    playerRunHoverPoint = null;
    _playerRunPlayerId = null;
    _playerRunSegmentIndex = null;
    _undoStack.clear();
    _redoStack.clear();

    final importedName = (data['planName'] as String?)?.trim();

    if (overwrite && currentTacticId != null) {
      final index = tactics.indexWhere((t) => t.id == currentTacticId);
      if (index != -1) {
        tactics[index] = Tactic(
          id: tactics[index].id,
          name: importedName?.isNotEmpty == true
              ? importedName!
              : tactics[index].name,
          players: players.map((p) => p.copy()).toList(),
          ball: ball.copy(),
          drawings: drawings.map((d) => d.copy()).toList(),
          homeFormation: homeFormation,
          awayFormation: awayFormation,
          sidesSwapped: sidesSwapped,
        );
      }
    } else {
      final id = DateTime.now().microsecondsSinceEpoch.toString();
      tactics.add(
        Tactic(
          id: id,
          name: importedName?.isNotEmpty == true
              ? importedName!
              : 'İçe Aktarılan Plan',
          players: players.map((p) => p.copy()).toList(),
          ball: ball.copy(),
          drawings: drawings.map((d) => d.copy()).toList(),
          homeFormation: homeFormation,
          awayFormation: awayFormation,
          sidesSwapped: sidesSwapped,
        ),
      );
      currentTacticId = id;
    }

    notifyListeners();
  }

  // --- Whole-app persistence ----------------------------------------------

  /// Serializes every saved [Tactic], every [DrawingPreset] and the global
  /// (not per-tactic) settings, so the whole app - not just the live board -
  /// can be restored after a restart. Unlike [exportSnapshotJson] (a single
  /// board meant for manual copy/paste sharing), this is meant to be written
  /// to local storage as-is and read back with [loadAppStateJson].
  Map<String, dynamic> toAppStateJson() {
    _snapshotIntoCurrentTactic();
    return {
      'version': 1,
      'currentTacticId': currentTacticId,
      'tactics': tactics.map((t) => t.toJson()).toList(),
      'drawingPresets': drawingPresets.map((p) => p.toJson()).toList(),
      'settings': {
        'pitchImage': pitchImage,
        'jerseyImage': jerseyImage,
        'ballImage': ballImage,
        'adBannerImageUrl': adBannerImageUrl,
        'channelIconImageUrl': channelIconImageUrl,
        'homeColor': homeColor.toARGB32(),
        'awayColor': awayColor.toARGB32(),
        'drawingColor': drawingColor.toARGB32(),
        'drawingThickness': drawingThickness,
        'fullscreenShortcutKeyId': fullscreenShortcutKey.keyId,
        'ballPathSpeed': ballPathSpeed,
        'hidePlayerRuns': hidePlayerRuns,
        'dimBallPath': dimBallPath,
      },
    };
  }

  /// Restores state previously produced by [toAppStateJson]. Called once at
  /// startup before anything else touches the controller; if [data] is
  /// malformed, callers should catch the error and keep the fresh default
  /// state from the constructor instead of calling this at all.
  void loadAppStateJson(Map<String, dynamic> data) {
    final loadedTactics = (data['tactics'] as List? ?? const [])
        .map((t) => Tactic.fromJson(t as Map<String, dynamic>))
        .toList();
    if (loadedTactics.isEmpty) return;

    tactics
      ..clear()
      ..addAll(loadedTactics);
    drawingPresets
      ..clear()
      ..addAll(
        (data['drawingPresets'] as List? ?? const []).map(
          (p) => DrawingPreset.fromJson(p as Map<String, dynamic>),
        ),
      );

    final settings = data['settings'] as Map<String, dynamic>? ?? const {};
    if (settings['pitchImage'] != null) {
      pitchImage = settings['pitchImage'] as String;
    }
    if (settings['jerseyImage'] != null) {
      jerseyImage = settings['jerseyImage'] as String;
    }
    if (settings['ballImage'] != null) {
      ballImage = settings['ballImage'] as String;
    }
    adBannerImageUrl = settings['adBannerImageUrl'] as String?;
    channelIconImageUrl = settings['channelIconImageUrl'] as String?;
    // squadSize/showBothTeams are deliberately never restored here - every
    // launch should start at the 11 · Tek takım default view regardless of
    // what was last selected, instead of remembering it across restarts.
    if (settings['homeColor'] != null) {
      homeColor = Color(settings['homeColor'] as int);
    }
    if (settings['awayColor'] != null) {
      awayColor = Color(settings['awayColor'] as int);
    }
    if (settings['drawingColor'] != null) {
      drawingColor = Color(settings['drawingColor'] as int);
    }
    if (settings['drawingThickness'] != null) {
      drawingThickness = (settings['drawingThickness'] as num).toDouble();
    }
    if (settings['fullscreenShortcutKeyId'] != null) {
      fullscreenShortcutKey = LogicalKeyboardKey(
        settings['fullscreenShortcutKeyId'] as int,
      );
    }
    if (settings['ballPathSpeed'] != null) {
      ballPathSpeed = (settings['ballPathSpeed'] as num).toDouble().clamp(
        0.25,
        4.0,
      );
    }
    if (settings['hidePlayerRuns'] != null) {
      hidePlayerRuns = settings['hidePlayerRuns'] as bool;
    }
    if (settings['dimBallPath'] != null) {
      dimBallPath = settings['dimBallPath'] as bool;
    }

    final targetId = data['currentTacticId'] as String?;
    currentTacticId = tactics.any((t) => t.id == targetId)
        ? targetId
        : tactics.first.id;
    _loadTactic(tactics.firstWhere((t) => t.id == currentTacticId));
    notifyListeners();
  }

  /// Ships one ready-made "Top Yolu" (ball path) example so a new user
  /// opening the Şablonlar dialog immediately sees what a full build-up-to-
  /// goal move looks like: a wide buildup down the right wing finished by
  /// the striker's near-post run, timed to arrive with the cross.
  static List<DrawingPreset> _buildExampleDrawingPresets() {
    return [
      DrawingPreset(
        id: 'example-wing-goal',
        name: 'Örnek: Kanattan Gol',
        shapes: [
          DrawingShape(
            tool: DrawingTool.ballPath,
            color: AppColors.drawYellow,
            thickness: 4,
            points: const [
              Offset(0.50, 0.50),
              Offset(0.72, 0.82),
              Offset(0.90, 0.75),
              Offset(0.93, 0.50),
            ],
            segmentBends: const [null, null, null],
            waypointMessages: const [
              'Orta sahadan başlangıç',
              'Sağ kanada açılım',
              'Çizgiye kadar sürüş',
              'Ceza sahasına orta',
            ],
            playerRuns: [
              PlayerRun(
                playerId: 'home-9',
                segmentIndex: 2,
                points: const [Offset(0.58, 0.55), Offset(0.90, 0.48)],
                bends: const [null],
              ),
            ],
          ),
        ],
      ),
    ];
  }

  static List<Player> _buildRoster() {
    final list = <Player>[];
    final homeSlots = FormationType.f433.slots;
    for (var i = 0; i < homeSlots.length; i++) {
      final slot = homeSlots[i];
      list.add(
        Player(
          id: 'home-$i',
          name: _homeNames[i],
          number: i + 1,
          team: 'home',
          position: slot.label,
          x: slot.x,
          y: slot.y,
          isCaptain: i == 6,
        ),
      );
    }
    for (var i = homeSlots.length; i < _homeNames.length; i++) {
      list.add(
        Player(
          id: 'home-sub-$i',
          name: _homeNames[i],
          number: i + 1,
          team: 'home',
          position: 'SUB',
          x: 0.5,
          y: 0.5,
          onPitch: false,
        ),
      );
    }

    final awaySlots = FormationType.f433.slots;
    for (var i = 0; i < awaySlots.length; i++) {
      final slot = awaySlots[i];
      list.add(
        Player(
          id: 'away-$i',
          name: _awayNames[i],
          number: i + 1,
          team: 'away',
          position: slot.label,
          x: 1 - slot.x,
          y: slot.y,
          isCaptain: i == 6,
        ),
      );
    }
    for (var i = awaySlots.length; i < _awayNames.length; i++) {
      list.add(
        Player(
          id: 'away-sub-$i',
          name: _awayNames[i],
          number: i + 1,
          team: 'away',
          position: 'SUB',
          x: 0.5,
          y: 0.5,
          onPitch: false,
        ),
      );
    }
    return list;
  }
}
