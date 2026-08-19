import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/tactics_controller.dart';

/// In-app user guide. Content-only (no Scaffold/AppBar) so it can be
/// embedded directly inside the Sidebar-driven pages like Players/Settings,
/// or wrapped in its own Scaffold when pushed as a full route from the
/// pitch screen (which has no sidebar of its own).
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key, this.controller});

  /// Optional - when given, the shortcuts section shows the fullscreen key
  /// actually configured in Ayarlar instead of a generic placeholder.
  final TacticsController? controller;

  String get _fullscreenKeyLabel {
    final key = controller?.fullscreenShortcutKey;
    if (key == LogicalKeyboardKey.keyF) return 'F';
    if (key == LogicalKeyboardKey.space) return 'Boşluk';
    return 'F11';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: ListView(
        children: [
          Text('Kullanım Kılavuzu', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'FC Manager, antrenörler için dijital bir taktik tahtasıdır: '
            'oyuncuları sahaya yerleştirin, formasyon kurun, ok/çizgi/top '
            'yolu gibi araçlarla hareketleri çizin ve planlarınızı kaydedin.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          const _GuideSection(
            icon: Icons.grid_view_rounded,
            title: 'Sahaya Başlarken',
            initiallyExpanded: true,
            items: [
              'Sol raftaki Diziliş bölümünden hazır bir formasyon seçin '
                  '(4-4-2, 4-3-3, 4-2-3-1, 3-5-2, 3-4-3, 5-3-2); oyuncular '
                  'otomatik olarak o dizilişe yerleşir.',
              'Bir oyuncuyu sahaya sürükleyip bırakarak konumlandırın; '
                  'yedeğe almak için tekrar kenar çubuğuna (bank) sürükleyin.',
              'Bir oyuncunun üstüne çift tıklayarak adını değiştirebilirsiniz.',
              'Sağ raftaki Kaptan ve Kilit düğmeleriyle seçili oyuncuyu '
                  'kaptan yapabilir ya da yanlışlıkla taşınmasını önlemek '
                  'için kilitleyebilirsiniz.',
              'Ayarlar\'dan sahada 11 (tek takım), 22 (çift takım) ya da '
                  'takım başına özel bir oyuncu sayısı seçebilirsiniz.',
              'Rakip oyuncularla birlikte çalışırken tarafları değiştirmek '
                  'için üst çubuktaki "Taraf Değiştir" seçeneğini kullanın.',
            ],
          ),
          const _GuideSection(
            icon: Icons.edit_outlined,
            title: 'Çizim Araçları',
            items: [
              'Alt çubuktaki Taktikler panelinden bir araç seçin: Ok, '
                  'Çizgi, Serbest Çizim, Dikdörtgen, Daire, Vurgulama, Top '
                  'Yolu, Alan Taraması, Oyuncu Koşusu ve Isı Haritası.',
              'Ok ve çizgilerde, çizildikten sonra ortadaki tutamacı '
                  'sürükleyerek düz çizgiyi kavisli bir harekete '
                  'dönüştürebilirsiniz.',
              'Bir çizimi silmek için Seç aracıyla çizimi seçin, ardından '
                  'sağ raftaki Sil düğmesine dokunun.',
              'Yaptığınız son çizim değişikliğini geri almak/yinelemek için '
                  'üst çubuktaki geri al/yinele düğmelerini ya da '
                  'Ctrl+Z / Ctrl+Y kısayollarını kullanın.',
            ],
          ),
          const _GuideSection(
            icon: Icons.route_outlined,
            title: 'Top Yolu ve Oyuncu Koşuları',
            items: [
              'Top Yolu aracıyla sahaya sırayla tıklayarak topun izleyeceği '
                  'durakları (waypoint) belirleyin; Enter veya Esc ile '
                  'çizimi tamamlayın.',
              'Her durağa, oynatma sırasında top oraya ulaştığında '
                  'görünecek kısa bir mesaj ekleyebilirsiniz.',
              'Alttaki oynatma çubuğuyla topu oynatın/duraklatın, baştan '
                  'başlatın, geri sarın ve hızını ayarlayın.',
              'Oyuncu Koşusu aracıyla, bir top yolu segmentine eşlik eden '
                  'bir oyuncunun kendi koşu güzergâhını çizip topla birlikte '
                  'senkronize şekilde oynatabilirsiniz.',
              'Alan Taraması (Zone) ile en az 3 nokta belirleyerek bir '
                  'pressing/baskı bölgesi çizebilirsiniz.',
            ],
          ),
          const _GuideSection(
            icon: Icons.dashboard_customize_outlined,
            title: 'Çizim Şablonları',
            items: [
              'Sağ raftaki Şablonlar düğmesiyle, o an sahada çizili olan '
                  '(veya seçili olan) şekilleri isimlendirip yeniden '
                  'kullanılabilir bir şablon olarak kaydedin - ör. bir köşe '
                  'vuruşu rutini.',
              'Aynı pencereden daha önce kaydettiğiniz bir şablonu tek '
                  'dokunuşla sahaya uygulayabilir veya silebilirsiniz.',
            ],
          ),
          const _GuideSection(
            icon: Icons.save_outlined,
            title: 'Planları Kaydetme ve Aktarma',
            items: [
              'Üst çubuktaki "Yeni Plan" düğmesi, o ana kadarki sahayı '
                  'saklayıp boş/yeni bir plan açar; plan adının üstüne '
                  'tıklayarak adını değiştirebilirsiniz.',
              'Kaydet düğmesi, o anki saha durumunu aktif plana anında '
                  'yazar. Ayrıca yaptığınız her değişiklik birkaç saniye '
                  'içinde otomatik olarak cihazınıza kaydedilir '
                  '(autosave) - uygulamayı kapatıp tekrar açsanız bile '
                  'planlarınız, oyuncularınız ve şablonlarınız kaybolmaz.',
              'JSON Dışa Aktar ile sahanızın ve tüm taktik verilerinizin '
                  'tam bir kopyasını panoya kopyalayıp bir dosyaya '
                  'kaydedebilir, JSON İçe Aktar ile de daha sonra (veya '
                  'başka bir cihazda) aynen geri yükleyebilirsiniz.',
            ],
          ),
          const _GuideSection(
            icon: Icons.group_outlined,
            title: 'Oyuncular Sekmesi',
            items: [
              'Sol menüdeki Oyuncular sekmesi, sahaya girmeden ev sahibi ve '
                  'deplasman kadrolarını yönetmenizi sağlar.',
              'Bir oyuncuya dokunarak adını, forma numarasını ve mevkisini '
                  'düzenleyebilir; yıldız simgesiyle kaptan yapabilir, '
                  'kilit simgesiyle sahada sabitleyebilirsiniz.',
              '"Oyuncu Ekle" ile kadroya yeni bir yedek oyuncu ekleyebilir, '
                  'çöp kutusu simgesiyle bir oyuncuyu tamamen '
                  'silebilirsiniz. Buradaki değişiklikler anında Taktik '
                  'ekranına da yansır.',
            ],
          ),
          _GuideSection(
            icon: Icons.settings_outlined,
            title: 'Ayarlar',
            items: [
              'Sahada kaç oyuncu gösterileceğini (11 / 22 / özel sayı) '
                  'buradan seçebilirsiniz.',
              'Saha görselini ve oyuncu forma görselini (ya da düz numara '
                  'simgesini) buradan değiştirebilirsiniz.',
              'Tam ekran kısayolunu F11, F veya Boşluk arasından '
                  'seçebilirsiniz; şu an ayarlı tuş: $_fullscreenKeyLabel.',
              'Buradaki tüm ayarlar, taktik verilerinizle birlikte otomatik '
                  'olarak kaydedilir.',
            ],
          ),
          _GuideSection(
            icon: Icons.keyboard_outlined,
            title: 'Klavye Kısayolları',
            items: [
              'Ctrl+Z: son çizim değişikliğini geri al · Ctrl+Y veya '
                  'Ctrl+Shift+Z: yinele.',
              'Esc veya Enter: Top Yolu, Alan Taraması ya da Oyuncu Koşusu '
                  'çizimini tamamlar (yarım kalan taslağı kaydeder ya da '
                  'iptal eder).',
              'Ayarlar\'da seçtiğiniz kısayol tuşu (şu an: '
                  '$_fullscreenKeyLabel): tam ekran modunu açar/kapatır.',
            ],
          ),
          const SizedBox(height: 8),
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Not: "Paylaş", "Not Ekle" ve "Maçlar" özellikleri şu anda '
                'geliştirme aşamasında ve yakında eklenecek.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _GuideSection extends StatelessWidget {
  const _GuideSection({
    required this.icon,
    required this.title,
    required this.items,
    this.initiallyExpanded = false,
  });

  final IconData icon;
  final String title;
  final List<String> items;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(icon),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        initiallyExpanded: initiallyExpanded,
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  '),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
