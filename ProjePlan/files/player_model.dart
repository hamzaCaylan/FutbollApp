import 'package:flutter/material.dart';

/// Bir oyuncuyu temsil eden model.
/// [x] ve [y] saha üzerindeki konumu 0.0 - 1.0 arasında oransal olarak belirtir.
/// (0,0) sahanın sol-üst köşesi, (1,1) sağ-alt köşesidir.
class PlayerModel {
  final int number;
  final String name;
  final double x;
  final double y;
  final String? photoUrl; // Ağdan resim, null ise baş harfler gösterilir
  final Color teamColor; // Çerçeve rengi (örn. kırmızı = deplasman, siyah = ev sahibi)
  final bool isCaptain;

  const PlayerModel({
    required this.number,
    required this.name,
    required this.x,
    required this.y,
    required this.teamColor,
    this.photoUrl,
    this.isCaptain = false,
  });
}

/// Örnek 4-3-3 / 4-2-3-1 gibi bir diziliş için hazır konum şablonları.
/// x,y değerleri 0.0-1.0 aralığında, saha genişliği/yüksekliğine göre oransaldır.
class FormationPresets {
  // Kaleci + 4 defans + 3 orta saha + 3 forvet (4-3-3), sahanın alt yarısı bu takıma ait varsayılmıştır.
  static List<Offset> formation433Bottom() => const [
        Offset(0.10, 0.90), // Kaleci
        Offset(0.20, 0.68), // Sol bek
        Offset(0.40, 0.72), // Stoper
        Offset(0.60, 0.72), // Stoper
        Offset(0.85, 0.68), // Sağ bek
        Offset(0.25, 0.45), // Orta saha
        Offset(0.50, 0.42), // Orta saha
        Offset(0.75, 0.45), // Orta saha
        Offset(0.30, 0.18), // Forvet
        Offset(0.50, 0.14), // Forvet
        Offset(0.70, 0.18), // Forvet
      ];

  static List<Offset> formation433Top() => const [
        Offset(0.10, 0.10),
        Offset(0.20, 0.32),
        Offset(0.40, 0.28),
        Offset(0.60, 0.28),
        Offset(0.85, 0.32),
        Offset(0.25, 0.55),
        Offset(0.50, 0.58),
        Offset(0.75, 0.55),
        Offset(0.30, 0.82),
        Offset(0.50, 0.86),
        Offset(0.70, 0.82),
      ];
}
