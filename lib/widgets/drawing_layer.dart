import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/drawing.dart';
import '../models/player.dart';
import '../state/tactics_controller.dart';
import '../theme/app_colors.dart';

class DrawingLayer extends StatelessWidget {
  const DrawingLayer({
    super.key,
    required this.controller,
    required this.area,
    required this.playerColors,
    this.onArrowFinished,
    this.onPlayerTappedWhileDrawing,
  });

  final TacticsController controller;
  final Size area;

  /// Player id -> team color, used to color each player's assigned run.
  final Map<String, Color> playerColors;

  /// Called with the new shape's index in [TacticsController.drawings] when
  /// a tap just completed an arrow, so the caller can offer to attach a
  /// message at the arrowhead.
  final ValueChanged<int>? onArrowFinished;

  /// Called with a player's id when a tap during any drawing tool lands on
  /// that player instead of empty pitch space - the caller selects them and
  /// finishes whatever draft is in progress.
  final ValueChanged<String>? onPlayerTappedWhileDrawing;

  Offset _toFraction(Offset local) {
    final dx = area.width == 0 ? 0.0 : (local.dx / area.width).clamp(0.0, 1.0);
    final dy = area.height == 0
        ? 0.0
        : (local.dy / area.height).clamp(0.0, 1.0);
    return Offset(dx, dy);
  }

  /// Fraction-space hit test against players currently on the pitch, so a
  /// tap on a player during drawing can be treated as "select them" instead
  /// of "place a point here".
  Player? _playerAt(Offset fraction) {
    const hitRadius = 0.035;
    for (final player in controller.pitchPlayers) {
      final dx = player.x - fraction.dx;
      final dy = player.y - fraction.dy;
      if (dx * dx + dy * dy <= hitRadius * hitRadius) return player;
    }
    return null;
  }

  DrawingShape? _arrowPreview() {
    final start = controller.arrowStartPoint;
    if (start == null) return null;
    return DrawingShape(
      tool: DrawingTool.arrow,
      color: controller.drawingColor,
      thickness: controller.drawingThickness,
      points: [start, controller.arrowHoverPoint ?? start],
    );
  }

  DrawingShape? _pathPreview() {
    final points = controller.pathPoints;
    if (points.isEmpty) return null;
    final hover = controller.pathHoverPoint ?? points.last;
    return DrawingShape(
      tool: DrawingTool.ballPath,
      color: controller.drawingColor,
      thickness: controller.drawingThickness,
      points: [...points, hover],
      segmentBends: [...controller.pathSegmentBends, null],
    );
  }

  DrawingShape? _zonePreview() {
    final points = controller.zonePoints;
    if (points.isEmpty) return null;
    final hover = controller.zoneHoverPoint ?? points.last;
    return DrawingShape(
      tool: DrawingTool.zone,
      color: controller.drawingColor,
      thickness: controller.drawingThickness,
      points: [...points, hover],
    );
  }

  DrawingShape? _playerRunPreview() {
    final points = controller.playerRunPoints;
    if (points.isEmpty) return null;
    final hover = controller.playerRunHoverPoint ?? points.last;
    final targetId = controller.playerRunTargetId;
    return DrawingShape(
      tool: DrawingTool.playerRun,
      color: targetId != null
          ? (playerColors[targetId] ?? controller.drawingColor)
          : controller.drawingColor,
      thickness: controller.drawingThickness,
      points: [...points, hover],
      segmentBends: [...controller.playerRunSegmentBends, null],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tool = controller.activeTool;
    final interactive = tool != DrawingTool.none;
    final isArrowClickMode = tool == DrawingTool.arrow;
    final isPathClickMode = tool == DrawingTool.ballPath;
    final isZoneClickMode = tool == DrawingTool.zone;
    final isPlayerRunClickMode = tool == DrawingTool.playerRun;

    final painter = CustomPaint(
      painter: DrawingPainter(
        drawings: controller.drawings,
        draft: isArrowClickMode
            ? _arrowPreview()
            : isPathClickMode
            ? _pathPreview()
            : isZoneClickMode
            ? _zonePreview()
            : isPlayerRunClickMode
            ? _playerRunPreview()
            : controller.draftShape,
        selectedIndices: controller.selectedDrawingIndices,
        playerColors: playerColors,
        hidePlayerRuns: controller.hidePlayerRuns,
        dimBallPath: controller.dimBallPath,
        activeBallPathIndex: controller.resolvedBallPathIndex,
        ballPathProgress: controller.ballPathProgress,
        selectedDurakIndex: controller.selectedDurakIndex,
        currentBallDurakIndex: controller.currentBallDurakIndex,
      ),
      size: area,
    );

    // Arrows and ball paths use a click-to-place flow instead of a drag, so
    // the user can place each point precisely. A drag that starts on an
    // existing shape's midpoint bends it instead - taps and drags are
    // distinct gestures, so both can live on the same detector.
    final Widget content;
    if (isArrowClickMode) {
      content = MouseRegion(
        onHover: (event) =>
            controller.updateArrowHover(_toFraction(event.localPosition)),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapUp: (details) {
            final fraction = _toFraction(details.localPosition);
            final hitPlayer = _playerAt(fraction);
            if (hitPlayer != null) {
              onPlayerTappedWhileDrawing?.call(hitPlayer.id);
            }
            final finishedIndex = controller.handleArrowTap(fraction);
            if (finishedIndex != null) onArrowFinished?.call(finishedIndex);
          },
          onSecondaryTapUp: (details) => controller.handleDrawingRightClick(
            _toFraction(details.localPosition),
          ),
          onPanStart: (details) => controller.handleArrowBendStart(
            _toFraction(details.localPosition),
          ),
          onPanUpdate: (details) => controller.handleArrowBendUpdate(
            _toFraction(details.localPosition),
          ),
          onPanEnd: (_) => controller.handleArrowBendEnd(),
          child: painter,
        ),
      );
    } else if (isPathClickMode) {
      content = MouseRegion(
        onHover: (event) =>
            controller.updatePathHover(_toFraction(event.localPosition)),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapUp: (details) {
            final fraction = _toFraction(details.localPosition);
            final hitPlayer = _playerAt(fraction);
            if (hitPlayer != null) {
              onPlayerTappedWhileDrawing?.call(hitPlayer.id);
              return;
            }
            controller.handlePathTap(fraction);
          },
          onSecondaryTapUp: (details) => controller.handleDrawingRightClick(
            _toFraction(details.localPosition),
          ),
          onPanStart: (details) => controller.handlePathBendStart(
            _toFraction(details.localPosition),
          ),
          onPanUpdate: (details) => controller.handlePathBendUpdate(
            _toFraction(details.localPosition),
          ),
          onPanEnd: (_) => controller.handlePathBendEnd(),
          child: painter,
        ),
      );
    } else if (isZoneClickMode) {
      content = MouseRegion(
        onHover: (event) =>
            controller.updateZoneHover(_toFraction(event.localPosition)),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapUp: (details) {
            final fraction = _toFraction(details.localPosition);
            final hitPlayer = _playerAt(fraction);
            if (hitPlayer != null) {
              onPlayerTappedWhileDrawing?.call(hitPlayer.id);
              return;
            }
            controller.handleZoneTap(fraction);
          },
          onSecondaryTapUp: (details) => controller.handleDrawingRightClick(
            _toFraction(details.localPosition),
          ),
          onPanStart: (details) => controller.handleZoneVertexDragStart(
            _toFraction(details.localPosition),
          ),
          onPanUpdate: (details) => controller.handleZoneVertexDragUpdate(
            _toFraction(details.localPosition),
          ),
          onPanEnd: (_) => controller.handleZoneVertexDragEnd(),
          child: painter,
        ),
      );
    } else if (isPlayerRunClickMode) {
      content = MouseRegion(
        onHover: (event) =>
            controller.updatePlayerRunHover(_toFraction(event.localPosition)),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapUp: (details) {
            final fraction = _toFraction(details.localPosition);
            final hitPlayer = _playerAt(fraction);
            if (hitPlayer != null) {
              onPlayerTappedWhileDrawing?.call(hitPlayer.id);
              return;
            }
            controller.handlePlayerRunTap(fraction);
          },
          onSecondaryTapUp: (details) => controller.handleDrawingRightClick(
            _toFraction(details.localPosition),
          ),
          onPanStart: (details) => controller.handlePlayerRunBendStart(
            _toFraction(details.localPosition),
          ),
          onPanUpdate: (details) => controller.handlePlayerRunBendUpdate(
            _toFraction(details.localPosition),
          ),
          onPanEnd: (_) => controller.handlePlayerRunBendEnd(),
          child: painter,
        ),
      );
    } else {
      content = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (details) =>
            controller.handleCanvasPanStart(_toFraction(details.localPosition)),
        onPanUpdate: (details) => controller.handleCanvasPanUpdate(
          _toFraction(details.localPosition),
        ),
        onPanEnd: (_) => controller.handleCanvasPanEnd(),
        child: painter,
      );
    }

    return Positioned.fill(
      child: IgnorePointer(ignoring: !interactive, child: content),
    );
  }
}

class DrawingPainter extends CustomPainter {
  DrawingPainter({
    required this.drawings,
    required this.draft,
    required this.selectedIndices,
    required this.playerColors,
    required this.hidePlayerRuns,
    required this.dimBallPath,
    required this.activeBallPathIndex,
    required this.ballPathProgress,
    required this.selectedDurakIndex,
    required this.currentBallDurakIndex,
  });

  final List<DrawingShape> drawings;
  final DrawingShape? draft;
  final Set<int> selectedIndices;
  final Map<String, Color> playerColors;

  /// When true, committed player-run lines aren't drawn at all (the
  /// Taktikler toolbar's "Oyuncu Hareketini Gizle" toggle).
  final bool hidePlayerRuns;

  /// When true, the ball path currently controlling ball playback
  /// (`activeBallPathIndex`) is progressively revealed as a dim trail
  /// behind the ball instead of drawn at full opacity (the Taktikler
  /// toolbar's ball-path opacity toggle).
  final bool dimBallPath;

  /// Index into [drawings] of the ball path the ball is actually following
  /// right now (`TacticsController.resolvedBallPathIndex`) - only this
  /// shape gets the progress-based trail reveal when [dimBallPath] is true.
  final int? activeBallPathIndex;

  /// How far along the active ball path the ball currently is (0..1),
  /// used to compute which segments of the trail are revealed.
  final double ballPathProgress;

  /// The durak (stop) currently selected on the waypoint track bar - arrows
  /// tagged with this durak stay visible while it's selected, regardless of
  /// where the ball actually is.
  final int? selectedDurakIndex;

  /// The durak the ball is actually sitting at during playback - arrows
  /// tagged with this durak are visible as the ball passes through it.
  final int? currentBallDurakIndex;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < drawings.length; i++) {
      final shape = drawings[i];
      if (shape.durakIndex != null &&
          shape.durakIndex != selectedDurakIndex &&
          shape.durakIndex != currentBallDurakIndex) {
        continue;
      }
      _paintShape(
        canvas,
        size,
        shape,
        selected: selectedIndices.contains(i),
        isActiveBallPath: i == activeBallPathIndex,
      );
    }
    if (draft != null) {
      _paintShape(
        canvas,
        size,
        draft!,
        selected: false,
        isActiveBallPath: false,
      );
    }
  }

  void _paintShape(
    Canvas canvas,
    Size size,
    DrawingShape shape, {
    required bool selected,
    required bool isActiveBallPath,
  }) {
    final points = shape.points
        .map((p) => Offset(p.dx * size.width, p.dy * size.height))
        .toList();
    if (shape.tool == DrawingTool.ballPath) {
      _paintBallPath(
        canvas,
        size,
        shape,
        points,
        selected: selected,
        dim: dimBallPath,
        useProgressReveal: dimBallPath && isActiveBallPath,
        ballProgress: ballPathProgress,
      );
      return;
    }
    if (shape.tool == DrawingTool.zone) {
      _paintZone(canvas, size, shape, points, selected: selected);
      return;
    }
    if (shape.tool == DrawingTool.playerRun) {
      _paintRunLine(
        canvas,
        size,
        shape.points,
        shape.segmentBends,
        shape.color,
        emphasized: true,
      );
      return;
    }
    if (points.length < 2) return;
    final control = shape.controlPoint == null
        ? null
        : Offset(
            shape.controlPoint!.dx * size.width,
            shape.controlPoint!.dy * size.height,
          );

    final paint = Paint()
      ..color = shape.color
      ..strokeWidth = shape.thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    switch (shape.tool) {
      case DrawingTool.none:
      case DrawingTool.select:
      case DrawingTool.ballPath:
      case DrawingTool.zone:
      case DrawingTool.playerRun:
        break;
      case DrawingTool.freehand:
        final path = Path()..moveTo(points.first.dx, points.first.dy);
        for (final point in points.skip(1)) {
          path.lineTo(point.dx, point.dy);
        }
        canvas.drawPath(path, paint);
        break;
      case DrawingTool.line:
        if (control != null) {
          canvas.drawPath(
            _curvedPath(points.first, control, points.last),
            paint,
          );
        } else {
          canvas.drawLine(points.first, points.last, paint);
        }
        break;
      case DrawingTool.arrow:
        if (control != null) {
          canvas.drawPath(
            _curvedPath(points.first, control, points.last),
            paint,
          );
          // The arrowhead follows the curve's tangent at the end (control -> end).
          _paintArrowHead(canvas, control, points.last, paint);
        } else {
          canvas.drawLine(points.first, points.last, paint);
          _paintArrowHead(canvas, points.first, points.last, paint);
        }
        _paintXMarker(canvas, points.first, paint);
        break;
      case DrawingTool.rectangle:
        canvas.drawRect(Rect.fromPoints(points.first, points.last), paint);
        break;
      case DrawingTool.circle:
        canvas.drawOval(Rect.fromPoints(points.first, points.last), paint);
        break;
      case DrawingTool.highlight:
        final fill = Paint()
          ..color = shape.color.withValues(alpha: 0.27)
          ..style = PaintingStyle.fill;
        canvas.drawRect(Rect.fromPoints(points.first, points.last), fill);
        break;
      case DrawingTool.heatmap:
        _paintHeatmap(canvas, points, shape.thickness);
        break;
    }

    if (selected) {
      final bounds = Rect.fromPoints(points.first, points.last).inflate(6);
      final selectionPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawRect(bounds, selectionPaint);

      if (shape.tool == DrawingTool.line || shape.tool == DrawingTool.arrow) {
        final handle = control ?? Offset.lerp(points.first, points.last, 0.5)!;
        canvas.drawCircle(handle, 5, Paint()..color = Colors.white);
        canvas.drawCircle(
          handle,
          5,
          Paint()
            ..color = Colors.black87
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }
  }

  /// Paints a "heat trail" along the drawn path: a soft, blurred yellow
  /// glow layered under a tighter orange band and a hot red core - so the
  /// line reads as an intensity gradient (hottest at the center, cooling
  /// outward) rather than a flat stroke. [thickness] scales all three
  /// layers together, so the ince/orta/kalın picker still controls size.
  void _paintHeatmap(Canvas canvas, List<Offset> points, double thickness) {
    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.heatmapEdge.withValues(alpha: 0.2)
        ..strokeWidth = thickness * 8.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.heatmapMid.withValues(alpha: 0.4)
        ..strokeWidth = thickness * 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.heatmapCore.withValues(alpha: 0.6)
        ..strokeWidth = thickness * 2.25
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  void _paintBallPath(
    Canvas canvas,
    Size size,
    DrawingShape shape,
    List<Offset> points, {
    required bool selected,
    required bool dim,
    required bool useProgressReveal,
    required double ballProgress,
  }) {
    if (points.isEmpty) return;
    final basePaint = Paint()
      ..color = dim ? shape.color.withValues(alpha: 0.3) : shape.color
      ..strokeWidth = shape.thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (points.length == 1) {
      _paintXMarker(canvas, points.first, basePaint);
      return;
    }

    final segmentCount = points.length - 1;
    // Which segment (0-based) the ball currently occupies along this path -
    // segments up to and including it are revealed as a dim trail, later
    // ones stay fully hidden; null (nothing revealed yet) while the ball
    // sits exactly at the very first durak and hasn't started moving.
    final int? revealUpTo = !useProgressReveal || ballProgress <= 0.0
        ? null
        : (ballProgress * segmentCount).floor().clamp(0, segmentCount - 1);

    Paint paintFor(int segmentIndex) {
      if (!useProgressReveal) return basePaint;
      final revealed = revealUpTo != null && segmentIndex <= revealUpTo;
      return Paint()
        ..color = shape.color.withValues(alpha: revealed ? 0.3 : 0.0)
        ..strokeWidth = shape.thickness
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
    }

    Offset controlFor(int segment) {
      final bend = segment < shape.segmentBends.length
          ? shape.segmentBends[segment]
          : null;
      return bend == null
          ? Offset.lerp(points[segment], points[segment + 1], 0.5)!
          : Offset(bend.dx * size.width, bend.dy * size.height);
    }

    for (var i = 0; i < points.length - 1; i++) {
      final segStart = points[i];
      final segEnd = points[i + 1];
      final paint = paintFor(i);
      final bend = i < shape.segmentBends.length ? shape.segmentBends[i] : null;
      final control = bend == null
          ? null
          : Offset(bend.dx * size.width, bend.dy * size.height);
      if (control != null) {
        canvas.drawPath(_curvedPath(segStart, control, segEnd), paint);
      } else {
        canvas.drawLine(segStart, segEnd, paint);
      }
      // Every waypoint except the very last gets an "X"; only the final
      // point gets the arrowhead - matching x-----x-----x----->.
      _paintXMarker(canvas, segStart, paint);
      if (i == points.length - 2) {
        _paintArrowHead(canvas, control ?? segStart, segEnd, paint);
      }
    }

    if (selected) {
      var minX = points.first.dx, maxX = points.first.dx;
      var minY = points.first.dy, maxY = points.first.dy;
      for (final p in points) {
        minX = math.min(minX, p.dx);
        maxX = math.max(maxX, p.dx);
        minY = math.min(minY, p.dy);
        maxY = math.max(maxY, p.dy);
      }
      canvas.drawRect(
        Rect.fromLTRB(minX, minY, maxX, maxY).inflate(6),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );
      for (var i = 0; i < points.length - 1; i++) {
        final handle = controlFor(i);
        canvas.drawCircle(handle, 5, Paint()..color = Colors.white);
        canvas.drawCircle(
          handle,
          5,
          Paint()
            ..color = Colors.black87
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }

    // Each assigned player's run for this path, colored by that player's
    // team so it's clear at a glance who runs where during each segment -
    // the "Oyuncu Hareketini Gizle" toggle fades the line to fully
    // transparent instead of skipping the paint, so it's the same line
    // just switching between transparent and its normal color per click.
    for (final run in shape.playerRuns) {
      final baseColor = playerColors[run.playerId] ?? Colors.white;
      final color = hidePlayerRuns
          ? baseColor.withValues(alpha: 0.0)
          : baseColor;
      _paintRunLine(
        canvas,
        size,
        run.points,
        run.bends,
        color,
        emphasized: false,
      );
    }
  }

  /// Draws a player's running path (a poly-line with optional per-segment
  /// bends, small dots at each waypoint, and an arrowhead at the end).
  /// Shared by the in-progress draft (drawn brighter/thicker) and every
  /// committed run attached to a ball path.
  void _paintRunLine(
    Canvas canvas,
    Size size,
    List<Offset> fractionPoints,
    List<Offset?> fractionBends,
    Color color, {
    required bool emphasized,
  }) {
    if (fractionPoints.length < 2) return;
    final points = fractionPoints
        .map((p) => Offset(p.dx * size.width, p.dy * size.height))
        .toList();
    final paint = Paint()
      ..color = color
      ..strokeWidth = emphasized ? 3.5 : 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < points.length - 1; i++) {
      final bendFraction = i < fractionBends.length ? fractionBends[i] : null;
      if (bendFraction != null) {
        final bend = Offset(
          bendFraction.dx * size.width,
          bendFraction.dy * size.height,
        );
        canvas.drawPath(_curvedPath(points[i], bend, points[i + 1]), paint);
      } else {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
    for (final point in points) {
      canvas.drawCircle(point, emphasized ? 4 : 3, Paint()..color = color);
    }
    _paintArrowHead(canvas, points[points.length - 2], points.last, paint);
  }

  void _paintZone(
    Canvas canvas,
    Size size,
    DrawingShape shape,
    List<Offset> points, {
    required bool selected,
  }) {
    if (points.isEmpty) return;
    final borderPaint = Paint()
      ..color = shape.color
      ..strokeWidth = shape.thickness
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (points.length >= 3) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      path.close();
      final fill = Paint()
        ..color = shape.color.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fill);
      canvas.drawPath(path, borderPaint);
    } else if (points.length == 2) {
      canvas.drawLine(points.first, points.last, borderPaint);
    }

    for (final point in points) {
      canvas.drawCircle(point, 5, Paint()..color = shape.color);
      canvas.drawCircle(
        point,
        5,
        Paint()
          ..color = Colors.black87
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    if (selected) {
      var minX = points.first.dx, maxX = points.first.dx;
      var minY = points.first.dy, maxY = points.first.dy;
      for (final point in points) {
        minX = math.min(minX, point.dx);
        maxX = math.max(maxX, point.dx);
        minY = math.min(minY, point.dy);
        maxY = math.max(maxY, point.dy);
      }
      canvas.drawRect(
        Rect.fromLTRB(minX, minY, maxX, maxY).inflate(6),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );
    }
  }

  Path _curvedPath(Offset start, Offset control, Offset end) {
    return Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
  }

  void _paintArrowHead(Canvas canvas, Offset start, Offset end, Paint paint) {
    const arrowLength = 14.0;
    const arrowAngle = 0.5;
    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    final path = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - arrowLength * math.cos(angle - arrowAngle),
        end.dy - arrowLength * math.sin(angle - arrowAngle),
      )
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - arrowLength * math.cos(angle + arrowAngle),
        end.dy - arrowLength * math.sin(angle + arrowAngle),
      );
    canvas.drawPath(path, paint..style = PaintingStyle.stroke);
  }

  void _paintXMarker(Canvas canvas, Offset center, Paint paint) {
    const half = 7.0;
    canvas.drawLine(
      Offset(center.dx - half, center.dy - half),
      Offset(center.dx + half, center.dy + half),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx - half, center.dy + half),
      Offset(center.dx + half, center.dy - half),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) => true;
}
