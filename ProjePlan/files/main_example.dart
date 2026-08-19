import 'package:flutter/material.dart';
import 'lineup_screen.dart';
import 'player_model.dart';

/// Bu dosyayı projenin lib/main.dart'ına örnek olarak kullanabilir
/// ya da içeriğini kendi main.dart'ına kopyalayabilirsin.
void main() {
  runApp(const MyLineupApp());
}

class MyLineupApp extends StatelessWidget {
  const MyLineupApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Ekran görüntüsündeki 4-3-3 dizilişine yakın örnek konumlar.
    final homePositions = FormationPresets.formation433Bottom();
    final awayPositions = FormationPresets.formation433Top();

    final homeTeam = <PlayerModel>[
      PlayerModel(number: 1, name: 'Nübel', x: homePositions[0].dx, y: homePositions[0].dy, teamColor: Colors.white),
      PlayerModel(number: 35, name: 'Djaló', x: 0.20, y: 0.72, teamColor: Colors.white),
      PlayerModel(number: 62, name: 'Murillo', x: 0.24, y: 0.90, teamColor: Colors.white),
      PlayerModel(number: 18, name: 'Cerny', x: 0.42, y: 0.90, teamColor: Colors.white),
      PlayerModel(number: 15, name: 'Olaitan', x: 0.35, y: 0.78, teamColor: Colors.white),
      PlayerModel(number: 6, name: 'Salih', x: 0.28, y: 0.58, teamColor: Colors.white),
      PlayerModel(number: 53, name: 'Emirhan', x: 0.20, y: 0.42, teamColor: Colors.white),
      PlayerModel(number: 10, name: 'Orkun', x: 0.35, y: 0.32, teamColor: Colors.white, isCaptain: true),
      PlayerModel(number: 33, name: 'Rıdvan', x: 0.24, y: 0.20, teamColor: Colors.white),
      PlayerModel(number: 29, name: 'İlhan', x: 0.42, y: 0.22, teamColor: Colors.white),
      PlayerModel(number: 9, name: 'Oh', x: 0.50, y: 0.58, teamColor: Colors.white),
      PlayerModel(number: 7, name: 'Franculino', x: 0.55, y: 0.42, teamColor: Colors.white),
      PlayerModel(number: 10, name: 'Cho', x: 0.55, y: 0.62, teamColor: Colors.white),
    ];

    final awayTeam = <PlayerModel>[
      PlayerModel(number: 11, name: 'Osorio', x: 0.66, y: 0.14, teamColor: Colors.red),
      PlayerModel(number: 7, name: 'Rashica', x: 0.58, y: 0.28, teamColor: Colors.red),
      PlayerModel(number: 8, name: 'Billing', x: 0.68, y: 0.32, teamColor: Colors.red),
      PlayerModel(number: 5, name: 'Kristensen', x: 0.78, y: 0.28, teamColor: Colors.red, isCaptain: true),
      PlayerModel(number: 19, name: 'Bravo', x: 0.70, y: 0.48, teamColor: Colors.red),
      PlayerModel(number: 6, name: 'Erlić', x: 0.80, y: 0.48, teamColor: Colors.red),
      PlayerModel(number: 1, name: 'Ólafsson', x: 0.90, y: 0.48, teamColor: Colors.red),
      PlayerModel(number: 20, name: 'Byskov', x: 0.68, y: 0.62, teamColor: Colors.red),
      PlayerModel(number: 22, name: 'Sørensen', x: 0.80, y: 0.68, teamColor: Colors.red),
      PlayerModel(number: 21, name: 'Castillo', x: 0.68, y: 0.82, teamColor: Colors.red),
    ];

    final bench = <PlayerModel>[
      PlayerModel(number: 92, name: 'Ricardo', x: 0, y: 0, teamColor: Colors.white),
      PlayerModel(number: 68, name: 'Ay', x: 0, y: 0, teamColor: Colors.white),
      PlayerModel(number: 94, name: 'Mário', x: 0, y: 0, teamColor: Colors.white),
      PlayerModel(number: 19, name: 'Trossard', x: 0, y: 0, teamColor: Colors.white),
      PlayerModel(number: 25, name: 'Bakker', x: 0, y: 0, teamColor: Colors.red),
      PlayerModel(number: 30, name: 'Ejeheri', x: 0, y: 0, teamColor: Colors.red),
    ];

    return MaterialApp(
      title: 'Kadro Ekranı',
      theme: ThemeData.dark(),
      home: LineupScreen(
        matchTitle: 'Kadro',
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        bench: bench,
      ),
    );
  }
}
