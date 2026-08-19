/// Browser-backed file save/open helpers - "Kaydet" downloads the current
/// plan as a .json file via the browser's own Save dialog, and "Kayıtları
/// İçe Al" lets the coach pick a folder of previously exported .json files
/// to bulk-add as new records. Only meaningful on web (there's no
/// filesystem/download-dialog equivalent wired up for the other platform
/// targets in this project), so the real implementation is swapped in via
/// conditional export and the other platforms get a stub that reports the
/// feature as unavailable instead of failing to compile.
library;

export 'file_io_stub.dart' if (dart.library.html) 'file_io_web.dart';
