import 'formation.dart';
import 'player.dart';
import '../state/tactics_controller.dart';

/// A single labeled fact shown on one of the Dash 1 hero screen's floating
/// cards (e.g. "FORMA NO" / "7").
class PlayerStat {
  const PlayerStat({required this.label, required this.value});

  final String label;
  final String value;

  factory PlayerStat.fromJson(Map<String, dynamic> json) => PlayerStat(
    label: json['label'] as String,
    value: json['value'] as String,
  );

  Map<String, dynamic> toJson() => {'label': label, 'value': value};
}

/// The dataset behind the Dash 1 player-profile screen: hero typography/
/// photo, physical/bio facts, and headline stat cards. Built from a real
/// roster [Player] via [PlayerProfile.fromPlayer] - bio fields fall back to
/// an em dash when the coach hasn't filled them in from the Oyuncular
/// editor (Player.photoUrl/heightCm/weightKg/birthYear/club are all
/// optional). Also loadable from a JSON asset via [PlayerProfile.fromJson]
/// for the original demo content (assets/data/player_profile.json), which
/// is no longer wired up to any screen but kept for reference.
class PlayerProfile {
  const PlayerProfile({
    required this.watermarkText,
    required this.heroNumber,
    required this.heroPosition,
    required this.heroImage,
    required this.name,
    required this.club,
    required this.height,
    required this.weight,
    required this.born,
    required this.age,
    required this.stats,
    this.teamFacts = const [],
  });

  final String watermarkText;
  final String heroNumber;
  final String heroPosition;
  final String heroImage;
  final String name;
  final String club;
  final String height;
  final String weight;
  final String born;
  final String age;
  final List<PlayerStat> stats;

  /// Real team/plan/status facts shown in the right-side panel - fills the
  /// space the original static demo used for a fabricated match/video/
  /// career section, with things actually derivable from the roster and
  /// the active tactic instead.
  final List<PlayerStat> teamFacts;

  static const _placeholder = '—';

  static String _nationalityLabel(String status) => switch (status) {
    'foreignU23' => 'Yabancı (23 altı)',
    'foreignOver23' => 'Yabancı (23 ve üstü)',
    _ => 'Yerli',
  };

  static String _cardLabel(String card) => switch (card) {
    'yellow' => 'Sarı Kart',
    'yellow2' => '2. Sarı Kart',
    'red' => 'Kırmızı Kart',
    _ => 'Yok',
  };

  factory PlayerProfile.fromPlayer(
    Player player, {
    required TacticsController controller,
  }) {
    final birthYear = player.birthYear;
    final tactic = controller.tactics
        .where((t) => t.id == controller.currentTacticId)
        .firstOrNull;
    return PlayerProfile(
      watermarkText: player.position,
      heroNumber: '${player.number}',
      heroPosition: player.position,
      heroImage: player.photoUrl ?? '',
      name: player.name,
      club:
          player.club ??
          (player.team == 'home' ? 'Ev Sahibi Takım' : 'Deplasman Takımı'),
      height: player.heightCm != null ? '${player.heightCm} cm' : _placeholder,
      weight: player.weightKg != null ? '${player.weightKg} kg' : _placeholder,
      born: birthYear != null ? '$birthYear' : _placeholder,
      age: birthYear != null
          ? '${DateTime.now().year - birthYear}'
          : _placeholder,
      stats: [
        PlayerStat(label: 'FORMA NO', value: '${player.number}'),
        PlayerStat(label: 'MEVKİ', value: player.position),
        PlayerStat(label: 'DURUM', value: player.onPitch ? 'Sahada' : 'Yedek'),
      ],
      teamFacts: [
        PlayerStat(
          label: 'TAKIM',
          value: player.team == 'home' ? 'Ev Sahibi' : 'Deplasman',
        ),
        PlayerStat(label: 'AKTİF PLAN', value: tactic?.name ?? _placeholder),
        PlayerStat(
          label: 'DİZİLİŞ',
          value: player.team == 'home'
              ? controller.homeFormation.label
              : controller.awayFormation.label,
        ),
        PlayerStat(
          label: 'KAPTAN MI',
          value: player.isCaptain ? 'Evet' : 'Hayır',
        ),
        PlayerStat(
          label: 'UYRUK',
          value: _nationalityLabel(player.nationalityStatus),
        ),
        PlayerStat(label: 'KART DURUMU', value: _cardLabel(player.card)),
      ],
    );
  }

  factory PlayerProfile.fromJson(Map<String, dynamic> json) => PlayerProfile(
    watermarkText: json['watermarkText'] as String,
    heroNumber: json['heroNumber'] as String,
    heroPosition: json['heroPosition'] as String,
    heroImage: json['heroImage'] as String,
    name: json['name'] as String,
    club: json['club'] as String,
    height: json['height'] as String,
    weight: json['weight'] as String,
    born: json['born'] as String,
    age: json['age'] as String,
    stats: (json['stats'] as List)
        .map((e) => PlayerStat.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'watermarkText': watermarkText,
    'heroNumber': heroNumber,
    'heroPosition': heroPosition,
    'heroImage': heroImage,
    'name': name,
    'club': club,
    'height': height,
    'weight': weight,
    'born': born,
    'age': age,
    'stats': stats.map((s) => s.toJson()).toList(),
  };
}
