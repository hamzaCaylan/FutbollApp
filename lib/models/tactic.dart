import 'ball.dart';
import 'drawing.dart';
import 'formation.dart';
import 'player.dart';

/// A saved snapshot of the board: player positions, the ball, drawings and
/// the formations in use. Switching the active tactic swaps the whole board
/// for another snapshot.
class Tactic {
  Tactic({
    required this.id,
    required this.name,
    required this.players,
    required this.ball,
    required this.drawings,
    this.homeFormation,
    this.awayFormation,
    this.sidesSwapped = false,
    this.description = '',
    this.category = '',
  });

  String id;
  String name;
  List<Player> players;
  Ball ball;
  List<DrawingShape> drawings;
  FormationType? homeFormation;
  FormationType? awayFormation;
  bool sidesSwapped;

  /// Free-text note shown in the Kayıtlar panel's info dialog - lets the
  /// coach jot down what this saved moment/plan is for beyond just its name.
  String description;

  /// Free-text grouping label (e.g. "İlk Yarı", "Duran Top") entered
  /// alongside the title/description when the record is created, shown in
  /// the info dialog.
  String category;

  Tactic copyWith({required String id, required String name}) => Tactic(
    id: id,
    name: name,
    players: players.map((p) => p.copy()).toList(),
    ball: ball.copy(),
    drawings: drawings.map((d) => d.copy()).toList(),
    homeFormation: homeFormation,
    awayFormation: awayFormation,
    sidesSwapped: sidesSwapped,
    description: description,
    category: category,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'players': players.map((p) => p.toJson()).toList(),
    'ball': ball.toJson(),
    'drawings': drawings.map((d) => d.toJson()).toList(),
    'homeFormation': homeFormation?.name,
    'awayFormation': awayFormation?.name,
    'sidesSwapped': sidesSwapped,
    'description': description,
    'category': category,
  };

  factory Tactic.fromJson(Map<String, dynamic> json) => Tactic(
    id: json['id'] as String,
    name: json['name'] as String,
    players: (json['players'] as List? ?? const [])
        .map((p) => Player.fromJson(p as Map<String, dynamic>))
        .toList(),
    ball: json['ball'] != null
        ? Ball.fromJson(json['ball'] as Map<String, dynamic>)
        : Ball(),
    drawings: (json['drawings'] as List? ?? const [])
        .map((d) => DrawingShape.fromJson(d as Map<String, dynamic>))
        .toList(),
    homeFormation: json['homeFormation'] != null
        ? FormationType.values.byName(json['homeFormation'] as String)
        : null,
    awayFormation: json['awayFormation'] != null
        ? FormationType.values.byName(json['awayFormation'] as String)
        : null,
    sidesSwapped: json['sidesSwapped'] as bool? ?? false,
    description: json['description'] as String? ?? '',
    category: json['category'] as String? ?? '',
  );
}
