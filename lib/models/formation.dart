import 'package:flutter/material.dart';

class FormationSlot {
  const FormationSlot(this.label, this.x, this.y);

  final String label;
  final double x;
  final double y;

  Offset get offset => Offset(x, y);
}

enum FormationType {
  f442,
  f433,
  f4231,
  f352,
  f343,
  f532,
  f3142,
  f3412,
  f3421,
  f41212,
  f41212v2,
  f4132,
  f4141,
  f4213,
  f4222,
  f4231v2,
  f424,
  f4312,
  f4321,
  f433v2,
  f433v3,
  f433v4,
  f4411v2,
  f442v2,
  f451,
  f451v2,
  f5212,
  f523,
  f541,
}

/// Row-by-row spacing (fraction of pitch height) a line of [count] players
/// spans, tuned to match the hand-placed formations below: a back-/mid-four
/// or -five stretches touchline to touchline, a front-/back-three is
/// narrower unless it's the attacking line (wingers need the width), and
/// pairs (a double pivot, a strike partnership) stay fairly central.
double _rowSpread(int count, {required bool isAttackRow}) {
  if (count <= 1) return 0;
  if (count == 2) return 0.24;
  if (count == 3) return isAttackRow ? 0.70 : 0.40;
  return count == 5 ? 0.84 : 0.76;
}

/// Generates 11 slots (GK first) from [rows] - the outfield line sizes from
/// defense to attack, e.g. `[4, 3, 3]` for a 4-3-3. Used for every formation
/// that doesn't need the hand-tuned placement the original six got.
///
/// [variant] distinguishes the "(2)"/"(3)"/"(4)" catalog entries that share
/// a numeric shape with a base formation: each step pushes the whole line
/// slightly higher up the pitch (a more attacking posture) and narrows the
/// non-defense/attack rows a little, so they read as a different tactical
/// setup instead of being pixel-identical to the base arrangement.
List<FormationSlot> _rowsToSlots(List<int> rows, {int variant = 0}) {
  final n = rows.length;
  final lineBoost = variant * 0.015;
  final widthScale = 1.0 - variant * 0.08;
  final slots = <FormationSlot>[const FormationSlot('GK', 0.06, 0.50)];
  for (var i = 0; i < n; i++) {
    final count = rows[i];
    final isDefense = i == 0;
    final isAttack = i == n - 1;
    final x = (0.08 + (i + 1) * (0.44 - 0.08) / n + lineBoost * (i + 1) / n)
        .clamp(0.08, 0.49);
    final rolePrefix = isDefense
        ? 'CB'
        : isAttack
        ? 'ST'
        : (i == 1 && n >= 4)
        ? 'CDM'
        : (i == n - 2 && n >= 4)
        ? 'CAM'
        : 'CM';
    final spread =
        _rowSpread(count, isAttackRow: isAttack) *
        (isDefense || isAttack ? 1.0 : widthScale);
    for (var j = 0; j < count; j++) {
      final mid = (count - 1) / 2;
      final y = count == 1
          ? 0.50
          : (0.50 + (j - mid) * (spread / (count - 1))).clamp(0.06, 0.94);
      var label = rolePrefix;
      if (count >= 3 && j == 0) {
        label = isDefense ? 'LB' : (isAttack ? 'LW' : 'LM');
      } else if (count >= 3 && j == count - 1) {
        label = isDefense ? 'RB' : (isAttack ? 'RW' : 'RM');
      }
      slots.add(FormationSlot(label, x, y));
    }
  }
  return slots;
}

extension FormationTypeX on FormationType {
  String get label {
    switch (this) {
      case FormationType.f442:
        return '4-4-2';
      case FormationType.f433:
        return '4-3-3';
      case FormationType.f4231:
        return '4-2-3-1';
      case FormationType.f352:
        return '3-5-2';
      case FormationType.f343:
        return '3-4-3';
      case FormationType.f532:
        return '5-3-2';
      case FormationType.f3142:
        return '3-1-4-2';
      case FormationType.f3412:
        return '3-4-1-2';
      case FormationType.f3421:
        return '3-4-2-1';
      case FormationType.f41212:
        return '4-1-2-1-2';
      case FormationType.f41212v2:
        return '4-1-2-1-2 (2)';
      case FormationType.f4132:
        return '4-1-3-2';
      case FormationType.f4141:
        return '4-1-4-1';
      case FormationType.f4213:
        return '4-2-1-3';
      case FormationType.f4222:
        return '4-2-2-2';
      case FormationType.f4231v2:
        return '4-2-3-1 (2)';
      case FormationType.f424:
        return '4-2-4';
      case FormationType.f4312:
        return '4-3-1-2';
      case FormationType.f4321:
        return '4-3-2-1';
      case FormationType.f433v2:
        return '4-3-3 (2)';
      case FormationType.f433v3:
        return '4-3-3 (3)';
      case FormationType.f433v4:
        return '4-3-3 (4)';
      case FormationType.f4411v2:
        return '4-4-1-1 (2)';
      case FormationType.f442v2:
        return '4-4-2 (2)';
      case FormationType.f451:
        return '4-5-1';
      case FormationType.f451v2:
        return '4-5-1 (2)';
      case FormationType.f5212:
        return '5-2-1-2';
      case FormationType.f523:
        return '5-2-3';
      case FormationType.f541:
        return '5-4-1';
    }
  }

  /// Eleven slots (goalkeeper first) laid out in the left half of the
  /// pitch (x in [0, 0.5]) for a team attacking rightward.
  List<FormationSlot> get slots {
    switch (this) {
      case FormationType.f442:
        return const [
          FormationSlot('GK', 0.06, 0.50),
          FormationSlot('LB', 0.20, 0.15),
          FormationSlot('CB', 0.16, 0.38),
          FormationSlot('CB', 0.16, 0.62),
          FormationSlot('RB', 0.20, 0.85),
          FormationSlot('LM', 0.34, 0.12),
          FormationSlot('CM', 0.32, 0.38),
          FormationSlot('CM', 0.32, 0.62),
          FormationSlot('RM', 0.34, 0.88),
          FormationSlot('ST', 0.46, 0.38),
          FormationSlot('ST', 0.46, 0.62),
        ];
      case FormationType.f433:
        return const [
          FormationSlot('GK', 0.06, 0.50),
          FormationSlot('LB', 0.20, 0.15),
          FormationSlot('CB', 0.16, 0.38),
          FormationSlot('CB', 0.16, 0.62),
          FormationSlot('RB', 0.20, 0.85),
          FormationSlot('CM', 0.32, 0.30),
          FormationSlot('CM', 0.30, 0.50),
          FormationSlot('CM', 0.32, 0.70),
          FormationSlot('LW', 0.46, 0.15),
          FormationSlot('ST', 0.42, 0.50),
          FormationSlot('RW', 0.46, 0.85),
        ];
      case FormationType.f4231:
        return const [
          FormationSlot('GK', 0.06, 0.50),
          FormationSlot('LB', 0.20, 0.15),
          FormationSlot('CB', 0.16, 0.38),
          FormationSlot('CB', 0.16, 0.62),
          FormationSlot('RB', 0.20, 0.85),
          FormationSlot('CDM', 0.30, 0.38),
          FormationSlot('CDM', 0.30, 0.62),
          FormationSlot('LAM', 0.40, 0.18),
          FormationSlot('CAM', 0.38, 0.50),
          FormationSlot('RAM', 0.40, 0.82),
          FormationSlot('ST', 0.48, 0.50),
        ];
      case FormationType.f352:
        return const [
          FormationSlot('GK', 0.06, 0.50),
          FormationSlot('CB', 0.16, 0.30),
          FormationSlot('CB', 0.14, 0.50),
          FormationSlot('CB', 0.16, 0.70),
          FormationSlot('LM', 0.32, 0.10),
          FormationSlot('CM', 0.30, 0.35),
          FormationSlot('CM', 0.28, 0.50),
          FormationSlot('CM', 0.30, 0.65),
          FormationSlot('RM', 0.32, 0.90),
          FormationSlot('ST', 0.46, 0.40),
          FormationSlot('ST', 0.46, 0.60),
        ];
      case FormationType.f343:
        return const [
          FormationSlot('GK', 0.06, 0.50),
          FormationSlot('CB', 0.16, 0.30),
          FormationSlot('CB', 0.14, 0.50),
          FormationSlot('CB', 0.16, 0.70),
          FormationSlot('LM', 0.32, 0.12),
          FormationSlot('CM', 0.30, 0.38),
          FormationSlot('CM', 0.30, 0.62),
          FormationSlot('RM', 0.32, 0.88),
          FormationSlot('LW', 0.46, 0.18),
          FormationSlot('ST', 0.48, 0.50),
          FormationSlot('RW', 0.46, 0.82),
        ];
      case FormationType.f532:
        return const [
          FormationSlot('GK', 0.06, 0.50),
          FormationSlot('LWB', 0.22, 0.08),
          FormationSlot('CB', 0.16, 0.30),
          FormationSlot('CB', 0.14, 0.50),
          FormationSlot('CB', 0.16, 0.70),
          FormationSlot('RWB', 0.22, 0.92),
          FormationSlot('CM', 0.32, 0.32),
          FormationSlot('CM', 0.30, 0.50),
          FormationSlot('CM', 0.32, 0.68),
          FormationSlot('ST', 0.46, 0.40),
          FormationSlot('ST', 0.46, 0.60),
        ];
      case FormationType.f3142:
        return _rowsToSlots(const [3, 1, 4, 2]);
      case FormationType.f3412:
        return _rowsToSlots(const [3, 4, 1, 2]);
      case FormationType.f3421:
        return _rowsToSlots(const [3, 4, 2, 1]);
      case FormationType.f41212:
        return _rowsToSlots(const [4, 1, 2, 1, 2]);
      case FormationType.f41212v2:
        return _rowsToSlots(const [4, 1, 2, 1, 2], variant: 1);
      case FormationType.f4132:
        return _rowsToSlots(const [4, 1, 3, 2]);
      case FormationType.f4141:
        return _rowsToSlots(const [4, 1, 4, 1]);
      case FormationType.f4213:
        return _rowsToSlots(const [4, 2, 1, 3]);
      case FormationType.f4222:
        return _rowsToSlots(const [4, 2, 2, 2]);
      case FormationType.f4231v2:
        return _rowsToSlots(const [4, 2, 3, 1], variant: 1);
      case FormationType.f424:
        return _rowsToSlots(const [4, 2, 4]);
      case FormationType.f4312:
        return _rowsToSlots(const [4, 3, 1, 2]);
      case FormationType.f4321:
        return _rowsToSlots(const [4, 3, 2, 1]);
      case FormationType.f433v2:
        return _rowsToSlots(const [4, 3, 3], variant: 1);
      case FormationType.f433v3:
        return _rowsToSlots(const [4, 3, 3], variant: 2);
      case FormationType.f433v4:
        return _rowsToSlots(const [4, 3, 3], variant: 3);
      case FormationType.f4411v2:
        return _rowsToSlots(const [4, 4, 1, 1], variant: 1);
      case FormationType.f442v2:
        return _rowsToSlots(const [4, 4, 2], variant: 1);
      case FormationType.f451:
        return _rowsToSlots(const [4, 5, 1]);
      case FormationType.f451v2:
        return _rowsToSlots(const [4, 5, 1], variant: 1);
      case FormationType.f5212:
        return _rowsToSlots(const [5, 2, 1, 2]);
      case FormationType.f523:
        return _rowsToSlots(const [5, 2, 3]);
      case FormationType.f541:
        return _rowsToSlots(const [5, 4, 1]);
    }
  }
}
