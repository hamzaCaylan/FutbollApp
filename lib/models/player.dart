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
    this.nationalityStatus = 'local',
    this.photoUrl,
    this.heightCm,
    this.weightKg,
    this.birthYear,
    this.club,
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

  /// 'local' | 'foreignU23' | 'foreignOver23' - shown as a small colored dot
  /// next to the player's name label (red/green/blue respectively).
  String nationalityStatus;

  /// Optional bio fields a coach can fill in from the Oyuncular editor,
  /// shown on the player's detail page (Dash1Screen) when set; all default
  /// to null (unset) and render as a "—" placeholder there.
  String? photoUrl;
  int? heightCm;
  int? weightKg;
  int? birthYear;
  String? club;

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
    nationalityStatus: nationalityStatus,
    photoUrl: photoUrl,
    heightCm: heightCm,
    weightKg: weightKg,
    birthYear: birthYear,
    club: club,
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
    'nationalityStatus': nationalityStatus,
    'photoUrl': photoUrl,
    'heightCm': heightCm,
    'weightKg': weightKg,
    'birthYear': birthYear,
    'club': club,
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
    nationalityStatus: json['nationalityStatus'] as String? ?? 'local',
    photoUrl: json['photoUrl'] as String?,
    heightCm: json['heightCm'] as int?,
    weightKg: json['weightKg'] as int?,
    birthYear: json['birthYear'] as int?,
    club: json['club'] as String?,
  );
}
