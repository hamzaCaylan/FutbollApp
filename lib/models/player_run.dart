import 'package:flutter/material.dart';

/// A player's custom running path across one segment (the stretch between
/// two consecutive ball-path waypoints/"Durak"s) of a [DrawingTool.ballPath]
/// shape. Keyed by (segmentIndex, playerId) - drawing a new run for a pair
/// that already has one replaces it.
class PlayerRun {
  PlayerRun({
    required this.playerId,
    required this.segmentIndex,
    required List<Offset> points,
    List<Offset?>? bends,
  }) : points = List.of(points),
       bends = bends != null ? List.of(bends) : [];

  final String playerId;
  final int segmentIndex;
  final List<Offset> points;
  List<Offset?> bends;

  PlayerRun copy() => PlayerRun(
    playerId: playerId,
    segmentIndex: segmentIndex,
    points: points,
    bends: bends,
  );

  Map<String, dynamic> toJson() => {
    'playerId': playerId,
    'segmentIndex': segmentIndex,
    'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
    'bends': bends
        .map((b) => b == null ? null : {'x': b.dx, 'y': b.dy})
        .toList(),
  };

  factory PlayerRun.fromJson(Map<String, dynamic> json) => PlayerRun(
    playerId: json['playerId'] as String,
    segmentIndex: json['segmentIndex'] as int,
    points: (json['points'] as List)
        .map(
          (p) => Offset(
            ((p as Map<String, dynamic>)['x'] as num).toDouble(),
            (p['y'] as num).toDouble(),
          ),
        )
        .toList(),
    bends: (json['bends'] as List? ?? const [])
        .map(
          (b) => b == null
              ? null
              : Offset(
                  ((b as Map<String, dynamic>)['x'] as num).toDouble(),
                  (b['y'] as num).toDouble(),
                ),
        )
        .toList(),
  );
}
