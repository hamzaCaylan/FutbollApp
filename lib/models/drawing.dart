import 'package:flutter/material.dart';

import 'player_run.dart';

enum DrawingTool {
  none,
  select,
  arrow,
  line,
  freehand,
  rectangle,
  circle,
  highlight,
  ballPath,
  zone,
  playerRun,
  heatmap,
}

extension DrawingToolX on DrawingTool {
  String get label {
    switch (this) {
      case DrawingTool.none:
        return 'Move';
      case DrawingTool.select:
        return 'Select';
      case DrawingTool.arrow:
        return 'Arrow';
      case DrawingTool.line:
        return 'Line';
      case DrawingTool.freehand:
        return 'Free draw';
      case DrawingTool.rectangle:
        return 'Rectangle';
      case DrawingTool.circle:
        return 'Circle';
      case DrawingTool.highlight:
        return 'Highlight';
      case DrawingTool.ballPath:
        return 'Ball path';
      case DrawingTool.zone:
        return 'Area scan';
      case DrawingTool.playerRun:
        return 'Player run';
      case DrawingTool.heatmap:
        return 'Heat map';
    }
  }

  IconData get icon {
    switch (this) {
      case DrawingTool.none:
        return Icons.pan_tool_alt_outlined;
      case DrawingTool.select:
        return Icons.touch_app_outlined;
      case DrawingTool.arrow:
        return Icons.north_east;
      case DrawingTool.line:
        return Icons.horizontal_rule;
      case DrawingTool.freehand:
        return Icons.edit;
      case DrawingTool.rectangle:
        return Icons.crop_square;
      case DrawingTool.circle:
        return Icons.circle_outlined;
      case DrawingTool.highlight:
        return Icons.highlight_alt;
      case DrawingTool.ballPath:
        return Icons.route;
      case DrawingTool.zone:
        return Icons.crop_free;
      case DrawingTool.playerRun:
        return Icons.directions_run;
      case DrawingTool.heatmap:
        return Icons.whatshot;
    }
  }
}

/// A single drawn shape. [points] holds every sampled point for
/// [DrawingTool.freehand]; for the other tools it holds exactly the drag
/// start and the current/end point.
class DrawingShape {
  DrawingShape({
    required this.tool,
    required this.color,
    required this.thickness,
    required List<Offset> points,
    this.controlPoint,
    List<Offset?>? segmentBends,
    List<String?>? waypointMessages,
    List<PlayerRun>? playerRuns,
    this.durakIndex,
    this.ballPathShapeIndex,
  }) : points = List.of(points),
       segmentBends = segmentBends != null ? List.of(segmentBends) : [],
       waypointMessages = waypointMessages != null
           ? List.of(waypointMessages)
           : [],
       playerRuns = playerRuns != null
           ? playerRuns.map((r) => r.copy()).toList()
           : [];

  final DrawingTool tool;
  final Color color;
  final double thickness;
  final List<Offset> points;

  /// When set, a [line]/[arrow] is drawn as a curve through this point
  /// instead of a straight segment. Dragging the shape's midpoint handle
  /// (in select mode) sets or moves this.
  Offset? controlPoint;

  /// One entry per segment of a [ballPath] (length == points.length - 1);
  /// null means that segment is still straight. Dragging a segment's
  /// midpoint handle sets or moves the matching entry.
  List<Offset?> segmentBends;

  /// One entry per waypoint of a [ballPath] (length == points.length);
  /// shown when the animated ball reaches that waypoint during playback.
  List<String?> waypointMessages;

  /// Per-segment player running paths attached to a [ballPath] - each one
  /// keyed by (segmentIndex, playerId). Only meaningful when [tool] is
  /// [DrawingTool.ballPath]; played back in sync with the ball as it moves
  /// through the matching segment.
  List<PlayerRun> playerRuns;

  /// When set (only meaningful for [DrawingTool.arrow]), this shape was
  /// drawn while a specific ball-path durak (stop) was selected - it's
  /// only shown while the ball sits at (or that durak is selected on) the
  /// ball path at [ballPathShapeIndex], so different arrow diagrams can be
  /// staged per stop instead of all showing at once.
  final int? durakIndex;

  /// Index into [TacticsController.drawings] of the ball path [durakIndex]
  /// refers to.
  final int? ballPathShapeIndex;

  DrawingShape copy() => DrawingShape(
    tool: tool,
    color: color,
    thickness: thickness,
    points: points,
    controlPoint: controlPoint,
    segmentBends: segmentBends,
    waypointMessages: waypointMessages,
    playerRuns: playerRuns,
    durakIndex: durakIndex,
    ballPathShapeIndex: ballPathShapeIndex,
  );

  Map<String, dynamic> toJson() => {
    'tool': tool.name,
    'color': color.toARGB32(),
    'thickness': thickness,
    'points': points.map(_offsetToJson).toList(),
    'controlPoint': controlPoint == null ? null : _offsetToJson(controlPoint!),
    'segmentBends': segmentBends
        .map((bend) => bend == null ? null : _offsetToJson(bend))
        .toList(),
    'waypointMessages': waypointMessages,
    'playerRuns': playerRuns.map((r) => r.toJson()).toList(),
    'durakIndex': durakIndex,
    'ballPathShapeIndex': ballPathShapeIndex,
  };

  factory DrawingShape.fromJson(Map<String, dynamic> json) => DrawingShape(
    tool: DrawingTool.values.byName(json['tool'] as String),
    color: Color(json['color'] as int),
    thickness: (json['thickness'] as num).toDouble(),
    points: (json['points'] as List)
        .map((p) => _offsetFromJson(p as Map<String, dynamic>))
        .toList(),
    controlPoint: json['controlPoint'] == null
        ? null
        : _offsetFromJson(json['controlPoint'] as Map<String, dynamic>),
    segmentBends: (json['segmentBends'] as List? ?? [])
        .map(
          (b) => b == null ? null : _offsetFromJson(b as Map<String, dynamic>),
        )
        .toList(),
    waypointMessages: (json['waypointMessages'] as List? ?? [])
        .map((m) => m as String?)
        .toList(),
    playerRuns: (json['playerRuns'] as List? ?? [])
        .map((r) => PlayerRun.fromJson(r as Map<String, dynamic>))
        .toList(),
    durakIndex: json['durakIndex'] as int?,
    ballPathShapeIndex: json['ballPathShapeIndex'] as int?,
  );
}

/// A named, reusable set of drawings (e.g. a corner-kick routine or a
/// pressing trigger) saved independently of any single Tactic, so it can be
/// dropped onto any plan instead of being redrawn by hand every time.
class DrawingPreset {
  DrawingPreset({required this.id, required this.name, required this.shapes});

  final String id;
  String name;
  final List<DrawingShape> shapes;

  DrawingPreset copy() => DrawingPreset(
    id: id,
    name: name,
    shapes: shapes.map((s) => s.copy()).toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'shapes': shapes.map((s) => s.toJson()).toList(),
  };

  factory DrawingPreset.fromJson(Map<String, dynamic> json) => DrawingPreset(
    id: json['id'] as String,
    name: json['name'] as String,
    shapes: (json['shapes'] as List? ?? const [])
        .map((s) => DrawingShape.fromJson(s as Map<String, dynamic>))
        .toList(),
  );
}

Map<String, dynamic> _offsetToJson(Offset offset) => {
  'x': offset.dx,
  'y': offset.dy,
};

Offset _offsetFromJson(Map<String, dynamic> json) =>
    Offset((json['x'] as num).toDouble(), (json['y'] as num).toDouble());
