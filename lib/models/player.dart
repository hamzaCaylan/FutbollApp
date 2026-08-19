class Player {
  Player({
    required this.id,
    required this.name,
    required this.number,
    required this.team,
    required this.position,
    required this.x,
    required this.y,
    this.isCaptain = false,
    this.onPitch = true,
    this.locked = false,
    this.substituted = false,
    this.card = 'none',
  });

  final String id;
  String name;
  int number;
  final String team;
  String position;
  double x;
  double y;
  bool isCaptain;
  bool onPitch;
  bool locked;

  /// True once this player has been part of a substitution (either side of
  /// it) - shows a small swap badge on their pitch/bench avatar.
  bool substituted;

  /// 'none' | 'yellow' | 'yellow2' (second yellow) | 'red' - shows a small
  /// card icon at the top-left of the player's jersey when not 'none'.
  String card;

  Player copy() => Player(
    id: id,
    name: name,
    number: number,
    team: team,
    position: position,
    x: x,
    y: y,
    isCaptain: isCaptain,
    onPitch: onPitch,
    locked: locked,
    substituted: substituted,
    card: card,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'number': number,
    'team': team,
    'position': position,
    'x': x,
    'y': y,
    'isCaptain': isCaptain,
    'onPitch': onPitch,
    'locked': locked,
    'substituted': substituted,
    'card': card,
  };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
    id: json['id'] as String,
    name: json['name'] as String,
    number: json['number'] as int,
    team: json['team'] as String,
    position: json['position'] as String,
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    isCaptain: json['isCaptain'] as bool? ?? false,
    onPitch: json['onPitch'] as bool? ?? true,
    locked: json['locked'] as bool? ?? false,
    substituted: json['substituted'] as bool? ?? false,
    card: json['card'] as String? ?? 'none',
  );
}
