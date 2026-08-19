// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Triggers the browser's own Save dialog (or a straight download, if the
/// browser isn't set to ask "Save As" each time) for [content] as a file
/// named [filename] - this is as close as a web app gets to "let the user
/// choose where to save it".
Future<void> downloadJsonFile(String filename, String content) async {
  final blob = html.Blob([content], 'application/json');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}

/// Opens the browser's folder picker and reads every .json file inside it.
Future<List<(String name, String content)>> pickJsonFilesFromFolder() async {
  final input = html.FileUploadInputElement()
    ..accept = '.json'
    ..multiple = true;
  input.setAttribute('webkitdirectory', 'true');
  input.click();

  await input.onChange.first;
  final files = input.files;
  if (files == null || files.isEmpty) return const [];

  final results = <(String, String)>[];
  for (final file in files) {
    if (!file.name.toLowerCase().endsWith('.json')) continue;
    final reader = html.FileReader();
    reader.readAsText(file);
    await reader.onLoad.first;
    results.add((file.name, reader.result as String));
  }
  return results;
}
