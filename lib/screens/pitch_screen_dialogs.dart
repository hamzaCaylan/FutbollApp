import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/file_io.dart';
import '../state/tactics_controller.dart';
import '../widgets/settings_panel.dart';
import 'help_screen.dart';

/// Dialog and navigation helpers used by [PitchScreen] - pulled out so the
/// screen's own file stays focused on the live pitch widget tree. Each
/// function takes exactly the [BuildContext]/[TacticsController]/callbacks
/// it needs rather than reaching into screen state directly.

/// Saves the current tactic in-memory (so switching plans still keeps it)
/// and downloads it as a .json file via the browser's own Save dialog,
/// letting the coach pick where it ends up.
Future<void> saveTacticToJsonFile(
  TacticsController controller,
  void Function(String message) showMessage,
) async {
  controller.saveCurrentTactic();
  final current = controller.tactics.firstWhere(
    (t) => t.id == controller.currentTacticId,
    orElse: () => controller.tactics.first,
  );
  final safeName = current.name.trim().isEmpty
      ? 'plan'
      : current.name.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  try {
    await downloadJsonFile('$safeName.json', controller.exportSnapshotJson());
    showMessage('Plan kaydedildi ve "$safeName.json" olarak indirildi.');
  } catch (_) {
    showMessage('Plan kaydedildi (JSON indirme bu ortamda desteklenmiyor).');
  }
}

/// Lets the coach pick a folder of previously exported .json plans and adds
/// every valid one as a new entry in the Kayıtlar list, without touching
/// the currently open board.
Future<void> importRecordsFromFolder(
  TacticsController controller,
  void Function(String message) showMessage,
) async {
  List<(String, String)> files;
  try {
    files = await pickJsonFilesFromFolder();
  } catch (_) {
    showMessage('Klasörden içe aktarma bu ortamda desteklenmiyor.');
    return;
  }
  if (files.isEmpty) return;

  var imported = 0;
  for (final (name, content) in files) {
    try {
      controller.importTacticFromJson(
        content,
        fallbackName: name.replaceAll(
          RegExp(r'\.json$', caseSensitive: false),
          '',
        ),
      );
      imported++;
    } catch (_) {
      // Skip malformed/unrelated JSON files, keep importing the rest.
    }
  }
  showMessage(
    imported > 0
        ? '$imported taktik Kayıtlar\'a eklendi.'
        : 'Klasörde içe aktarılabilir bir JSON bulunamadı.',
  );
}

/// Shows the full board snapshot as JSON and lets the user copy it to the
/// clipboard, ready to be pasted into a .json file for safekeeping.
Future<void> showExportJsonDialog(
  BuildContext context,
  TacticsController controller,
  void Function(String message) showMessage,
) async {
  final json = controller.exportSnapshotJson();
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('JSON Dışa Aktar'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bu JSON, sahanızın ve tüm taktik verilerinizin tam bir '
              'kopyasıdır. Kopyalayıp bir .json dosyasına yapıştırıp kaydedin; '
              'daha sonra İçe Aktar ile aynen geri yükleyebilirsiniz.',
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 260,
              child: Scrollbar(
                child: SingleChildScrollView(
                  child: SelectableText(
                    json,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Kapat'),
        ),
        FilledButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: json));
            if (!context.mounted) return;
            Navigator.of(context).pop();
            showMessage('JSON panoya kopyalandı.');
          },
          icon: const Icon(Icons.copy),
          label: const Text('Kopyala'),
        ),
      ],
    ),
  );
}

/// Lets the user paste a previously exported JSON snapshot back in, then
/// asks whether it should replace the current plan or become a new one.
Future<void> showImportJsonDialog(
  BuildContext context,
  TacticsController controller,
  void Function(String message) showMessage,
) async {
  final textController = TextEditingController();
  final pastedJson = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('JSON İçe Aktar'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dışa aktarılmış JSON metnini buraya yapıştırın.'),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: TextField(
                controller: textController,
                maxLines: null,
                expands: true,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '{ ... }',
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Vazgeç'),
        ),
        TextButton.icon(
          onPressed: () async {
            final data = await Clipboard.getData('text/plain');
            if (data?.text != null) textController.text = data!.text!;
          },
          icon: const Icon(Icons.paste),
          label: const Text('Yapıştır'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(textController.text),
          child: const Text('Devam Et'),
        ),
      ],
    ),
  );
  if (pastedJson == null || pastedJson.trim().isEmpty || !context.mounted) {
    return;
  }

  final overwrite = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('İçe Aktarma Seçeneği'),
      content: const Text(
        'Bu plan mevcut çalışmanın üzerine mi yazılsın, yoksa yeni bir '
        'plan olarak mı eklensin?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Vazgeç'),
        ),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Yeni Plan Olarak Ekle'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Üzerine Yaz'),
        ),
      ],
    ),
  );
  if (overwrite == null || !context.mounted) return;

  try {
    controller.importSnapshotFromJson(pastedJson, overwrite: overwrite);
    showMessage(
      overwrite ? 'Plan üzerine yazıldı.' : 'Yeni plan olarak eklendi.',
    );
  } catch (_) {
    showMessage(
      'JSON okunamadı. Lütfen geçerli bir dışa aktarım metni yapıştırın.',
    );
  }
}

/// Offers to attach a message to the tip of a just-drawn arrow.
Future<void> showArrowFinishedDialog(
  BuildContext context,
  TacticsController controller,
  int shapeIndex,
) async {
  final addMessage = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Ok Mesajı'),
      content: const Text('Bu okun ucuna bir mesaj eklemek ister misiniz?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Hayır'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Evet'),
        ),
      ],
    ),
  );
  if (addMessage != true || !context.mounted) return;

  final textController = TextEditingController();
  final message = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Ok Mesajı'),
      content: TextField(
        controller: textController,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Mesaj'),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(textController.text),
          child: const Text('Kaydet'),
        ),
      ],
    ),
  );
  if (message != null && message.trim().isNotEmpty) {
    controller.setWaypointMessage(shapeIndex, 1, message.trim());
  }
}

/// Asks whether a new "Top Yolu" draft should pick up where the last one
/// left off (so the waypoints read as one continuous passage of play) or
/// start a completely separate path. Null means the dialog was dismissed
/// without choosing, in which case the caller leaves the tool untouched.
Future<bool?> askContinueBallPathDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Top Yolu'),
      content: const Text(
        'Daha önce çizilmiş bir top yolu var. Yeni çizeceğiniz yol o '
        'yolun bittiği noktadan mı devam etsin, yoksa tamamen ayrı bir '
        'yol mu çizmek istersiniz?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Yeni Yol Çiz'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Eski Yola Devam Et'),
        ),
      ],
    ),
  );
}

/// After a ball path is committed, offers to attach a message to each of
/// its waypoints (shown as the animated ball reaches them).
Future<void> showBallPathWaypointMessagesDialog(
  BuildContext context,
  TacticsController controller,
  int shapeIndex,
  int pointCount,
) async {
  final addMessages = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Nokta Mesajları'),
      content: const Text(
        'Bu yoldaki noktalara, top oraya geldiğinde gösterilecek mesajlar eklemek ister misiniz?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Hayır'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Evet'),
        ),
      ],
    ),
  );
  if (addMessages != true || !context.mounted) return;

  for (var i = 0; i < pointCount; i++) {
    if (!context.mounted) return;
    final textController = TextEditingController();
    final message = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${i + 1}. Nokta Mesajı'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Mesaj (boş bırakabilirsiniz)',
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Atla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(textController.text),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    if (message != null && message.trim().isNotEmpty) {
      controller.setWaypointMessage(shapeIndex, i, message.trim());
    }
  }
}

Future<void> showBenchSearchDialog(
  BuildContext context,
  TacticsController controller,
) async {
  final textController = TextEditingController(text: controller.benchQuery);
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Oyuncu Ara'),
      content: TextField(
        controller: textController,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'İsim yazın'),
        onChanged: controller.setBenchQuery,
      ),
      actions: [
        TextButton(
          onPressed: () {
            controller.setBenchQuery('');
            Navigator.of(context).pop();
          },
          child: const Text('Temizle'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Kapat'),
        ),
      ],
    ),
  );
}

Future<void> showRenamePlayerDialog(
  BuildContext context,
  TacticsController controller,
  String playerId,
  String currentName,
) async {
  final textController = TextEditingController(text: currentName);
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Oyuncu adı'),
      content: TextField(
        controller: textController,
        autofocus: true,
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(textController.text),
          child: const Text('Kaydet'),
        ),
      ],
    ),
  );
  if (result != null && result.trim().isNotEmpty) {
    controller.renamePlayer(playerId, result.trim());
  }
}

/// "Yeni Kayıt" in the Kayıtlar panel: prompts for a name and saves the
/// current live board as a new, separately named entry.
Future<void> showSaveRecordAsNewDialog(
  BuildContext context,
  TacticsController controller,
  void Function(String message) showMessage,
) async {
  final textController = TextEditingController();
  final name = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Kayıt adı'),
      content: TextField(
        controller: textController,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Ör. 2. Yarı Baskı'),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(textController.text),
          child: const Text('Kaydet'),
        ),
      ],
    ),
  );
  if (name != null && name.trim().isNotEmpty) {
    controller.saveCurrentAsNew(name.trim());
    showMessage('Kayıt eklendi.');
  }
}

/// The Kayıtlar panel's per-record rename (pencil) action.
Future<void> showRenameRecordDialog(
  BuildContext context,
  TacticsController controller,
  String id,
  String currentName,
) async {
  final textController = TextEditingController(text: currentName);
  final name = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Kayıt adı'),
      content: TextField(
        controller: textController,
        autofocus: true,
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(textController.text),
          child: const Text('Kaydet'),
        ),
      ],
    ),
  );
  if (name != null && name.trim().isNotEmpty) {
    controller.renameTactic(id, name.trim());
  }
}

Future<String?> promptTemplateNameDialog(BuildContext context) async {
  final textController = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Şablon adı'),
      content: TextField(
        controller: textController,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Ör. Köşe vuruşu'),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(textController.text),
          child: const Text('Kaydet'),
        ),
      ],
    ),
  );
}

/// Lets the user save the currently drawn shapes (or just the selected
/// ones) as a reusable, named template independent of any single Tactic,
/// and browse/apply/delete previously saved templates.
Future<void> showDrawingTemplatesDialog(
  BuildContext context,
  TacticsController controller,
  void Function(String message) showMessage,
) async {
  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Çizim Şablonları'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.selectedDrawingIndices.isNotEmpty
                    ? '${controller.selectedDrawingIndices.length} seçili şekil şablon olarak kaydedilecek.'
                    : 'Sahadaki tüm çizimler (${controller.drawings.length}) şablon olarak kaydedilecek.',
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: controller.drawings.isEmpty
                    ? null
                    : () async {
                        final name = await promptTemplateNameDialog(context);
                        if (name != null && name.trim().isNotEmpty) {
                          controller.saveDrawingsAsPreset(name.trim());
                          setDialogState(() {});
                        }
                      },
                icon: const Icon(Icons.add),
                label: const Text('Bu Çizimi Şablon Olarak Kaydet'),
              ),
              const SizedBox(height: 12),
              if (controller.drawingPresets.isEmpty)
                const Text(
                  'Henüz kayıtlı şablon yok.',
                  style: TextStyle(color: Colors.white54),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: controller.drawingPresets.length,
                    separatorBuilder: (context, i) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final preset = controller.drawingPresets[i];
                      return ListTile(
                        dense: true,
                        title: Text(preset.name),
                        subtitle: Text('${preset.shapes.length} şekil'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Sahaya uygula',
                              icon: const Icon(Icons.add_box_outlined),
                              onPressed: () {
                                controller.applyDrawingPreset(preset.id);
                                Navigator.of(context).pop();
                                showMessage('${preset.name} sahaya eklendi.');
                              },
                            ),
                            IconButton(
                              tooltip: 'Sil',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () {
                                controller.deleteDrawingPreset(preset.id);
                                setDialogState(() {});
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
        ],
      ),
    ),
  );
}

Future<void> showFormationSettingsDialog(
  BuildContext context,
  TacticsController controller,
) async {
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Saha Dizilimi'),
      content: SizedBox(
        width: 480,
        height: MediaQuery.of(context).size.height * 0.75,
        child: SettingsPanel(
          controller: controller,
          onPicked: () => Navigator.of(context).pop(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Kapat'),
        ),
      ],
    ),
  );
}

void pushHelpScreen(BuildContext context, TacticsController controller) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Kullanım Kılavuzu')),
        body: HelpScreen(controller: controller),
      ),
    ),
  );
}
