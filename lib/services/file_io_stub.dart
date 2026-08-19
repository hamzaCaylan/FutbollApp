/// Non-web fallback - see file_io.dart for why this exists.
Future<void> downloadJsonFile(String filename, String content) async {
  throw UnsupportedError(
    'JSON dosyasını indirme şu an yalnızca web sürümünde destekleniyor.',
  );
}

/// Lets the user pick a folder of .json files; returns each file's name
/// and text content. Empty/aborted picks return an empty list.
Future<List<(String name, String content)>> pickJsonFilesFromFolder() async {
  throw UnsupportedError(
    'Klasörden JSON içe aktarma şu an yalnızca web sürümünde destekleniyor.',
  );
}
